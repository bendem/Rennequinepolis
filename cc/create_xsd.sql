begin
    -- dbms_xmlschema.deleteschema(
    --     'http://xmlns.bendem.be/cc',
    --     dbms_xmlschema.delete_cascade_force);
    dbms_xmlschema.registerschema(
        schemaurl => 'http://xmlns.bendem.be/cc',
        schemadoc => bfilename('MOVIES_DIR', 'cc.xsd'),
        local     => true,
        gentypes  => true,
        gentables => false,
        csid      => nls_charset_id('AL32UTF8'));
    commit;
end;
/
