#!/usr/bin/env bash

# Tidus Anonymize Backup and Restore
# v1.1 - Martin Seener (martin.seener@viafintech.com)

# Dumps/Restores databases using the _anonymized views for tables only, except for the schema_migrations table.

### Mapping environment variables
CREDENTIALSFILE=$1  # Path and/or name of the file containing PG Credentials
SCRIPTMODE=$2       # Dump or Restore?
FILEPATH=$3         # The path used for dumping files to or restoring files from
BACKUPSET=$4        # A parameter which defines the Backup Set used for restore

### Setting Aliases
PSQL="psql --set ON_ERROR_STOP=on"  # Let psql stop on errors

### Load Configuration
if ! source "${CREDENTIALSFILE}"; then
    echo "Unable to load credentials!"
    exit 1
fi

### Core Functions - Script Starting Point at the Bottom "case"!

getAnonymized() {
    local ELEM
    local LIST
    for ELEM in "${@}"; do
        if [[ $ELEM =~ .*_anonymized ]]; then
            LIST+=${ELEM%'_anonymized'}" "
        fi
    done
    echo "${LIST}"
}

# Checks if the specified folder exists
check_folder() {
    local PATHTOCREATE=$1
    if [ ! -d "${PATHTOCREATE}" ]; then
        if ! mkdir -p "${PATHTOCREATE}"; then
            exit 1
        fi
    fi
}

# Shows help
print_help() {
    echo "Tidus Backup/Restore"
    echo ""
    echo "Tidus Backup/Restore is able to dump and restore tidus-anonymized PostgreSQL databases. It will do so for the last 7 days by default."
    echo ""
    echo "Usage:"
    echo ""
    echo "You must provide a credentials file with the correct server ip, port and login credentials within the dump_db and restore_db functions to work properly."
    echo ""
    echo "  ./${0} - without any parameter the help is shown."
    echo "  ./${0} <PathToCredentialsFile> (-d|--dump) <destination folder>"
    echo "  ./${0} <PathToCredentialsFile> (-r|--restore) <source folder> <backup-set number>"
    echo ""
    echo "WARNING: In this early version you have to define the database names and users within the dump_it and restore_it functions manually."
    echo "         At moment there is no way to define them as a parameter when this script is called (will be possible in the future)."
    echo ""
}

### Main Functions

dump_db() {
    # Function Local Variables
    local DUMPPATH=$1
    local DBNAME=$2

    # Credentials
    export PGHOST=${DUMP_HOST}
    export PGPORT=${DUMP_PORT}
    export PGUSER=${DUMP_PGUSER}
    export PGPASSWORD=${DUMP_PGPASSWORD}

    # Check Backup Folder
    check_folder "${DUMPPATH}/${DBNAME}"

    # 1 Get all anonymized views
    declare -a ANONVIEWS=( $(${PSQL} -d "${DBNAME}" -c 'SELECT table_schema,table_type,table_name FROM information_schema.tables ORDER BY table_schema,table_type,table_name;' | grep -i "public" | grep "VIEW" | grep -i "_anonymized" | cut -d'|' -f3 | tr -d ' ') )

    # 2 Delete oldest dumps beforehand
    CNT=7
    rm ${DUMPPATH}/${DBNAME}/${CNT}_* 2>/dev/null

    # 3 Dump all anonymized views (using repeatable reads protection level)
    ( printf "SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;"
    for ANONTBL in "${ANONVIEWS[@]}"; do
        ORIGTBL=${ANONTBL%"_anonymized"}
        # Rolling Dumps/Schemas: Delete oldest and rename all others, so we can create a new one (most recent dump/schema)
        CNT=7
        cd "${DUMPPATH}/${DBNAME}"
        while [ ${CNT} -gt 1 ]; do
            rename -- s/$((CNT-1))_/$((CNT))_/ *_"${DBNAME}.${ORIGTBL}".*copy
            rename -- s/$((CNT-1))_/$((CNT))_/ *_"${DBNAME}.${ORIGTBL}".*schema
            CNT=$((CNT-1))
        done
        # Create new Dump
        printf "\COPY (SELECT * FROM %s) to '${DUMPPATH}/${DBNAME}/1_${DBNAME}.${ORIGTBL}.copy' \n;" "${ANONTBL}"; done) | ${PSQL} --single-transaction "${DBNAME}"
        # Create new Schema files
        pg_dump -s --section=pre-data -x -O -t "${ORIGTBL}" "${DBNAME}" -f "${DUMPPATH}/${DBNAME}/1_${DBNAME}.$ORIGTBL.preschema"
        pg_dump -s --section=post-data -x -O -t "${ORIGTBL}" "${DBNAME}" -f "${DUMPPATH}/${DBNAME}/1_${DBNAME}.$ORIGTBL.postschema"
    done

    # 4 Dump unowned sequences
    declare -a UNOWNEDSEQUENCES=( $(${PSQL} -t -d "${DBNAME}" -c "SELECT seq.relname AS seq_name FROM pg_class AS seq JOIN pg_namespace ns ON (seq.relnamespace=ns.oid) WHERE seq.relkind = 'S' AND NOT EXISTS (SELECT * FROM pg_depend WHERE objid=seq.oid AND deptype='a') ORDER BY seq.relname") )
    for UNOWNEDSEQ in "${UNOWNEDSEQUENCES[@]}"; do
        CNT=7
        cd "${DUMPPATH}/${DBNAME}"
        while [ ${CNT} -gt 1 ]; do
            rename -- s/$((CNT-1))_/$((CNT))_/ *_"${UNOWNEDSEQ}".sequence.sql
            CNT=$((CNT-1))
        done
        pg_dump -x -O -t "${UNOWNEDSEQ}" "${DBNAME}" -f "${DUMPPATH}/${DBNAME}/1_${UNOWNEDSEQ}.sequence.sql"
    done

    # 5 Dump the schema_migrations table
    CNT=7
    cd "${DUMPPATH}/${DBNAME}"
    while [ ${CNT} -gt 1 ]; do
        rename -- s/$((CNT-1))_/$((CNT))_/ *_"${DBNAME}".schema_migrations.sql
        CNT=$((CNT-1))
    done
    pg_dump -x -O -t schema_migrations "${DBNAME}" -f "${DUMPPATH}/${DBNAME}/1_${DBNAME}.schema_migrations.sql"
}

# What to dump?
dump_it() {
    # Function Local Variables
    local DUMPPATH=$1
    #dump_db <dump folder> <database name>
    dump_db "${DUMPPATH}" production_db_1
    dump_db "${DUMPPATH}" production_db_2
}

restore_db() {
    # Function Local Variables
    local RESTOREPATH=$1
    local PRODUCTIONDBNAME=$2
    local STAGINGDBNAME=$3
    local STAGINGDBUSER=$4
    local RESTOREBACKUPSET=$5
    local PERMRESETMIGRATION=$6

    # Credentials
    export PGHOST=${RESTORE_HOST}
    export PGPORT=${RESTORE_PORT}
    export PGUSER=${RESTORE_PGUSER}
    export PGPASSWORD=${RESTORE_PGPASSWORD}

    # 1. Delete all views, unowned sequences and base tables first
    VIEWS=$(${PSQL} -d "${STAGINGDBNAME}" -t -c "SELECT string_agg(table_name, ',') FROM information_schema.tables WHERE table_schema='public' AND table_type='VIEW' AND NOT table_name='pg_stat_statements'")
    BASETBLS=$(${PSQL} -d "${STAGINGDBNAME}" -t -c "SELECT string_agg(table_name, ',') FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE'")
    UNOWNEDSEQUENCES=$(${PSQL} -t -d "${STAGINGDBNAME}" -c "SELECT string_agg(seq.relname, ',') FROM pg_class AS seq JOIN pg_namespace ns ON (seq.relnamespace=ns.oid) WHERE seq.relkind = 'S' AND NOT EXISTS (SELECT * FROM pg_depend WHERE objid=seq.oid AND deptype='a') GROUP BY seq.relname")

    echo ""
    echo "=====> Working on Database: ${STAGINGDBNAME}"
    echo ""

    # Checking if there is the desired backupset before deleting the destination
    if [ "$(find "${RESTOREPATH}/${PRODUCTIONDBNAME}" -type f -name "${RESTOREBACKUPSET}_${PRODUCTIONDBNAME}*" | wc -l)" == 0 ]; then
        echo "Can't find any files for Backupset ${RESTOREBACKUPSET}"
        exit 1
    fi

    if [ "$VIEWS" == ' ' ]; then
        echo "No Views found!"
    else
        echo "Dropping views: ${VIEWS}"
        if ! ${PSQL} -d "${STAGINGDBNAME}" -c "DROP VIEW IF EXISTS ${VIEWS}"; then
            echo "Error: Unable to drop views!"
            exit 1
        fi
    fi
    if [ "$BASETBLS" == ' ' ]; then
        echo "No Tables found!"
    else
        echo "Dropping tables: ${BASETBLS}"
        if ! ${PSQL} -d "${STAGINGDBNAME}" -c "DROP TABLE IF EXISTS ${BASETBLS} CASCADE"; then
            echo "Error: Unable to drop tables!"
            exit 1
        fi
    fi
    if [ "${UNOWNEDSEQUENCES}" == '' ]; then
        echo "No unowned Sequences found!"
    else
        echo "Dropping unowned sequences: ${UNOWNEDSEQUENCES}"
        if ! ${PSQL} -d "${STAGINGDBNAME}" -c "DROP SEQUENCE IF EXISTS ${UNOWNEDSEQUENCES} CASCADE"; then
            echo "Error: Unable to drop unowned sequences!"
            exit 1
        fi
    fi

    echo "Restore all .sql files which are available in the folder"
    for SQLFILE in ${RESTOREPATH}/${PRODUCTIONDBNAME}/${RESTOREBACKUPSET}_*sql; do
        if [ "${SQLFILE}" != "${RESTOREPATH}/${PRODUCTIONDBNAME}/${RESTOREBACKUPSET}_*sql" ]; then
            echo "Restoring ${SQLFILE}"
            if ! ${PSQL} -d "${STAGINGDBNAME}" < "${SQLFILE}"; then
                echo "Error: Unable to restore ${SQLFILE}!"
                exit 1
            fi
        fi
    done

    echo "Now Restore all .preschema files in advance of the .copy files"
    for SCHEMAFILE in ${RESTOREPATH}/${PRODUCTIONDBNAME}/${RESTOREBACKUPSET}_*preschema; do
        if [ "${SCHEMAFILE}" != "${RESTOREPATH}/${PRODUCTIONDBNAME}/${RESTOREBACKUPSET}_*preschema" ]; then
            echo "Restoring ${SCHEMAFILE}"
            if ! ${PSQL} -d "${STAGINGDBNAME}" < "${SCHEMAFILE}"; then
                echo "Error: Unable to restore ${SCHEMAFILE}!"
                exit 1
            fi
        fi
    done

    echo "Now we will restore all .copy files in their appropriate tables"
    for COPYFILE in ${RESTOREPATH}/${PRODUCTIONDBNAME}/${RESTOREBACKUPSET}_*copy; do
        if [ "${COPYFILE}" != "${RESTOREPATH}/${PRODUCTIONDBNAME}/${RESTOREBACKUPSET}_*copy" ]; then
            # 3.1 We need to get the table name out of the filename to correctly create the COPY FROM command
            TBLNAME=$(echo "${COPYFILE}" | cut -d'.' -f2)
            # 3.2 Do the COPY
            echo "Restoring ${TBLNAME}"
            if ! ${PSQL} -d "${STAGINGDBNAME}" -c "\copy ${TBLNAME} FROM '${COPYFILE}'"; then
                echo "Error: Unable to restore ${TBLNAME}!"
                exit 1
            fi
        fi
    done

    echo "Now Restore all .postschema files after the .copy files"
    for SCHEMAFILE2 in ${RESTOREPATH}/${PRODUCTIONDBNAME}/${RESTOREBACKUPSET}_*postschema; do
            if [ "${SCHEMAFILE2}" != "${RESTOREPATH}/${PRODUCTIONDBNAME}/${RESTOREBACKUPSET}_*postschema" ]; then
                echo "Restoring ${SCHEMAFILE2}"
                if ! ${PSQL} -d "${STAGINGDBNAME}" < "${SCHEMAFILE2}"; then
                    echo "Error: Unable to restore ${SCHEMAFILE2}!"
                    exit 1
                fi
            fi
        done

    echo "In the last step we recreate all normal views"
    for VIEWFILE in ${RESTOREPATH}/${PRODUCTIONDBNAME}/${RESTOREBACKUPSET}_*view; do
        if [ "${VIEWFILE}" != "${RESTOREPATH}/${PRODUCTIONDBNAME}/${RESTOREBACKUPSET}_*view" ]; then
            echo "Restoring ${VIEWFILE}"
            if ! ${PSQL} -d "${STAGINGDBNAME}" < "${VIEWFILE}"; then
                echo "Error: Unable to restore ${VIEWFILE}!"
                exit 1
            fi
        fi
    done

    echo "Fixing Sequences and nextvals for their respective tables"
    if ! ${PSQL} -d "${STAGINGDBNAME}" -qAt -f ~/.scripts/pgviewcopy_seq_rst.sql -o /tmp/seq_rst_qry; then
        echo "Error: Unable to fix Sequences and nextvals!"
        exit 1
    fi
    echo "... Queries created - executing ..."
    if ! ${PSQL} -d "${STAGINGDBNAME}" -f /tmp/seq_rst_qry; then
        echo "Error: Unable to execute Sequence/nextvals Queries!"
        exit 1
    fi
    rm /tmp/seq_rst_qry

    echo "Resetting Owner for Tables, Sequences and Views"
    for TBL in $(${PSQL} -d "${STAGINGDBNAME}" -qAt -c "SELECT tablename FROM pg_tables WHERE schemaname='public';"); do
        if ! ${PSQL} -d "${STAGINGDBNAME}" -c "ALTER TABLE $TBL OWNER TO \"${STAGINGDBUSER}\""; then
            echo "Error: Unable to reset table owners!"
            exit 1
        fi
    done
    for SEQ in $(${PSQL} -d "${STAGINGDBNAME}" -qAt -c "SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema='public';"); do
        if ! ${PSQL} -d "${STAGINGDBNAME}" -c "ALTER TABLE $SEQ OWNER TO \"${STAGINGDBUSER}\""; then
            echo "Error: Unable to reset table sequence owner!"
            exit 1
        fi
    done
    for VIEW in $(${PSQL} -d "${STAGINGDBNAME}" -qAt -c "SELECT table_name FROM information_schema.views WHERE table_schema='public';"); do
        if ! ${PSQL} -d "${STAGINGDBNAME}" -c "ALTER TABLE $VIEW OWNER TO \"${STAGINGDBUSER}\""; then
            echo "Error: Unable to reset view owner!"
            exit 1
        fi
    done

    # Resetting all Permissions for the given user in restore_it since the staging user may differ from the production user.
    echo "Resetting Permissions for Tables, Sequences and Views"
    PERMARR=( 'ALTER SCHEMA public OWNER TO postgres;' )
    PERMARR+=( 'REVOKE ALL ON SCHEMA public FROM "'${STAGINGDBUSER}'";' )
    PERMARR+=( 'GRANT CREATE, USAGE ON SCHEMA public TO "'${STAGINGDBUSER}'";' )
    PERMARR+=( 'REVOKE ALL ON DATABASE "'${STAGINGDBNAME}'" FROM "'${STAGINGDBUSER}'";' )
    PERMARR+=( 'GRANT CONNECT, TEMPORARY ON DATABASE "'${STAGINGDBNAME}'" TO "'${STAGINGDBUSER}'";' )
    PERMARR+=( 'REVOKE ALL ON ALL TABLES IN SCHEMA public FROM "'${STAGINGDBUSER}'";' )
    PERMARR+=( 'GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON ALL TABLES IN SCHEMA public TO "'${STAGINGDBUSER}'";' )
    PERMARR+=( 'REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM "'${STAGINGDBUSER}'";' )
    PERMARR+=( 'GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA public TO "'${STAGINGDBUSER}'";' )

    for PERM in "${PERMARR[@]}"; do
        if ! ${PSQL} -d "${STAGINGDBNAME}" -c "${PERM}"; then
            echo "Error: Unable to reset permissions!"
            exit 1
        fi
    done

    echo ""
    echo "=====> Done for ${STAGINGDBNAME}!"
}

# What to restore?

restore_it() {
    # Function Local Variables
    local RESTOREPATH=$1
    local BACKUPSETNUMBER=$2
    #restore_db <dump folder> <source database name> <destination database name> <destination database user> <backup-set number>
    restore_db "${RESTOREPATH}" production_db_1 staging_db_1 staging_db_1_user "${BACKUPSETNUMBER}"
    restore_db "${RESTOREPATH}" production_db_2 staging_db_2 staging_db_2_user "${BACKUPSETNUMBER}"
}

### Do your thing

### Script Starting Point!

case "${SCRIPTMODE}" in
    --dump|-d)      check_folder "${FILEPATH}"
                    dump_it "${FILEPATH}";;
    --restore|-r)   check_folder "${FILEPATH}"
                    restore_it "${FILEPATH}" "${BACKUPSET}";;
    *)              print_help;;
esac
