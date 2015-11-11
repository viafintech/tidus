SELECT 'SELECT SETVAL(' ||quote_literal(quote_ident(PGT.schemaname)|| '.'||quote_ident(S.relname))|| ', (SELECT MAX(' ||quote_ident(C.attname)|| ') FROM ' ||quote_ident(PGT.schemaname)|| '.'||quote_ident(T.relname)|| '), true);
ALTER TABLE ' ||quote_ident(PGT.schemaname)|| '.'||quote_ident(T.relname)|| ' ALTER ' ||quote_ident(C.attname)|| ' SET DEFAULT nextval(' ||quote_literal(quote_ident(PGT.schemaname)|| '.'||quote_ident(S.relname))|| ');'
FROM pg_class AS S, pg_depend AS D, pg_class AS T, pg_attribute AS C, pg_tables AS PGT
WHERE S.relkind = 'S'
  AND S.oid = D.objid
  AND D.refobjid = T.oid
  AND D.refobjid = C.attrelid
  AND D.refobjsubid = C.attnum
  AND T.relname = PGT.tablename
ORDER BY S.relname;
