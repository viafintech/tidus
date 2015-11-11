#!/usr/bin/env bash

# Tidus Anonymize Backup and Restore
# v1.0 2015 - Martin Seener (martin.seener@barzahlen.de)

# Dumps/Restores databases using the _anonymized views for tables only, except for the schema_migrations table.

# Usage:
# 

### Core Functions

# Checks if the specified folder exists
check_folder() {
  if [ ! -d $1 ]; then mkdir -p $1
    if [ $? -gt 0 ]; then
      exit 1
    fi
  fi
}

# Shows help
print_help() {
  echo "${PROGNAME} ${VERSION}"
  echo ""
  echo "$PROGNAME is able to dump and restore tidus-anonymized PostgreSQL databases. It will do so for the last 7 days by default."
  echo ""
  echo "Usage:"
  echo ""
  echo "You must provide the correct server ip, port and login credentials within the dump_db and restore_db functions to work properly."
  echo "Due to security considerations the login credentials are not exposed as a parameter at this moment."
  echo ""
  echo "  ./${0} - without any parameter the help is shown."
  echo "  ./${0} (-d|--dump) <destination folder>"
  echo "  ./${0} (-r|--restore) <source folder> <backup-set number>"
  echo ""
  echo "WARNING: In this early version you have to define the database names and users within the dump_it and restore_it functions manually."
  echo "         At moment there is no way to define them as a parameter when this script is called (will be possible soon)."
  echo ""
}

### Main Functions

dump_db() {
  # Credentials
  PGSERVER='10.0.0.1'
  PGPORT=5432
  PGUSER='export_user'
  export PGPASSWORD='password' # Must be exported so psql/pg_dump can use them without user interaction

  # Check Backup Folder
  check_folder $1/$2

  # 1 Get all anonymized views
  declare -a ANONVIEWS=( `psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $2 -c 'SELECT table_schema,table_type,table_name FROM information_schema.tables ORDER BY table_schema,table_type,table_name;' | grep -i "public" | grep "VIEW" | grep -i "_anonymized" | cut -d'|' -f3 | tr -d ' '` )

  # 2 Dump all anonymized views (Data only!) (using repeatable reads protection level for consistent dumps)
  ( printf "SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;"
    for anontbl in ${ANONVIEWS[@]}; do
      origtbl=${anontbl%"_anonymized"}
      # Rolling Dumps: Delete oldest dump and rename all others, so we can create a new dump 1 (most recent dump)
      CNT=7
      rm $1/$2/${CNT}_$2.$origtbl.copy 2>/dev/null
      while [ $CNT -gt 0 ]; do
        cd $1/$2 && rename s/$(($CNT-1))_/$(($CNT))_/ *_$2.$origtbl.*copy
        CNT=$(($CNT-1))
      done
      printf "\COPY (SELECT * FROM %s) to '$1/$2/1_$2.$origtbl.copy' \n;" "$anontbl"; done) | psql --single-transaction -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} $2

  # Do the same for the .schema's since COPY only copies the data and not the schema!
  for anontbl2 in ${ANONVIEWS[@]}; do
    origtbl2=${anontbl2%"_anonymized"}
    CNT=7
    rm $1/$2/${CNT}_$2.$origtbl2.schema 2>/dev/null
    while [ $CNT -gt 0 ]; do
      cd $1/$2 && rename s/$(($CNT-1))_/$(($CNT))_/ *_$2.$origtbl2.*schema
      CNT=$(($CNT-1))
    done
    pg_dump -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -s -t $origtbl2 $2 -f $1/$2/1_$2.$origtbl2.schema
  done

  # 3 Dump the schema_migrations table - also as a rolling dump
  CNT=7
  rm $1/$2/${CNT}_$2.schema_migrations.sql 2>/dev/null
  while [ $CNT -gt 0 ]; do
    cd $1/$2 && rename s/$(($CNT-1))_/$(($CNT))_/ *_$2.schema_migrations.sql
    CNT=$(($CNT-1))
  done
  pg_dump -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -t schema_migrations $2 -f $1/$2/1_$2.schema_migrations.sql
}

restore_db() {
  PGSERVER='10.0.0.1'
  PGPORT=5432
  PGUSER='staging_admin'
  export PGPASSWORD='password'

  # 1. Delete all views and base tables first
  VIEWS=`psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 -t -c "SELECT string_agg(table_name, ',') FROM information_schema.tables WHERE table_schema='public' AND table_type='VIEW' AND NOT table_name='pg_stat_statements'"`
  BASETBLS=`psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 -t -c "SELECT string_agg(table_name, ',') FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE'"`

  echo ""
  echo "Working on Database: $3"
  echo ""

  # Checking if there is the desired backupset before deleting the destination
  if [ `ls ${1}/${2} | egrep "^${5}_.*" | wc -l` == 0 ]; then
    echo "Can't find any files for Backupset ${5}"
    exit 1
  fi

  if [ "$VIEWS" == "" ]; then
    echo "No Views found!"
  else
    echo "Dropping views: ${VIEWS}"
    psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 -c "DROP VIEW IF EXISTS ${VIEWS};"
  fi
  if [ "$BASETBLS" == "" ]; then
    echo "No Tables found!"
    exit 1
  else
    echo "Dropping tables: ${BASETBLS}"
    psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 -c "DROP TABLE IF EXISTS ${BASETBLS} CASCADE;"
  fi

  echo "Restore all .sql files which are available in the folder"
  for SQLFILE in `ls $1/$2 | grep "${5}_.*.sql$"`; do
    echo "Restoring ${SQLFILE}"
    psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 < $1/$2/$SQLFILE
  done

  echo "Now Restore all .schema files in advance of the .copy files"
  for SCHEMAFILE in `ls $1/$2 | grep "${5}_.*.schema$"`; do
    echo "Restoring $SCHEMAFILE"
    psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 < $1/$2/$SCHEMAFILE
  done

  echo "Now we will restore all .copy files in their appropriate tables"
  for COPYFILE in `ls $1/$2 | grep "${5}_.*.copy$"`; do
    # 3.1 We need to get the table name out of the filename to correctly create the COPY FROM command
    TBLNAME=`echo $COPYFILE | cut -d'.' -f2`
    # 3.2 Do the COPY
    echo "Restoring $TBLNAME"
    psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 -c "\copy $TBLNAME FROM '$1/$2/$COPYFILE'"
  done

  echo "In the last step we recreate all normal views"
  for VIEWFILE in `ls $1/$2 | grep "${5}_.*.view$"`; do
    echo "Restoring $VIEWFILE"
    psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 < $1/$2/$VIEWFILE
  done

  echo "Fixing Sequences and nextvals for their respective tables"
  psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 -qAt -f tidus_seq_rst.sql -o /tmp/seq_rst_qry
  echo "... Queries created - executing ..."
  psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 -f /tmp/seq_rst_qry
  rm /tmp/seq_rst_qry

  echo "Resetting Owner for Tables, Sequences and Views"
  for TBL in `psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 -qAt -c "SELECT tablename FROM pg_tables WHERE schemaname='public';"`; do
    psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 -c "ALTER TABLE $TBL OWNER TO \"$4\""
  done
  for SEQ in `psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 -qAt -c "SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema='public';"`; do
    psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 -c "ALTER TABLE $SEQ OWNER TO \"$4\""
  done
  for VIEW in `psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 -qAt -c "SELECT table_name FROM information_schema.views WHERE table_schema='public';"`; do
    psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 -c "ALTER TABLE $VIEW OWNER TO \"$4\""
  done

  # Resetting all Permissions for the given user in restore_it since the staging user may differ from the production user.
  echo "Resetting Permissions for Tables, Sequences and Views"
  PERMARR=( 'ALTER SCHEMA public OWNER TO postgres;' )
  PERMARR+=( 'REVOKE ALL ON SCHEMA public FROM "'$4'";' )
  PERMARR+=( 'GRANT CREATE, USAGE ON SCHEMA public TO "'$4'";' )
  PERMARR+=( 'REVOKE ALL ON DATABASE "'$3'" FROM "'$4'";' )
  PERMARR+=( 'GRANT CONNECT, TEMPORARY ON DATABASE "'$3'" TO "'$4'";' )
  PERMARR+=( 'REVOKE ALL ON ALL TABLES IN SCHEMA public FROM "'$4'";' )
  PERMARR+=( 'GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "'$4'";' )
  PERMARR+=( 'REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM "'$4'";' )
  PERMARR+=( 'GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA public TO "'$4'";' )

  for PERM in "${PERMARR[@]}"; do
  psql -h ${PGSERVER} -p ${PGPORT} -U ${PGUSER} -d $3 -c "$PERM"
  done

  echo ""
  echo "Done for $3!"
}

# What to dump/restore?

dump_it() {
  #dump_db <dump folder> <database name>
  dump_db $1 production_db_1
  dump_db $1 production_db_2
}

restore_it() {
  #restore_db <dump folder> <source database name> <destination database name> <destination database user> <backup-set number>
  restore_db $1 production_db_1 staging_db_1 staging_db_1_user $2
  restore_db $1 production_db_2 staging_db_2 staging_db_2_user $2
}

### Do your thing

case "$1" in
  --dump|-d)    check_folder $2
                dump_it $2
                exit 0;;
  --restore|-r) check_folder $2
                restore_it $2 $3
                exit 0;;
  *)            print_help
                exit 0;;
esac