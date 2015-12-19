create or replace directory xml_dir as '&cc_dir';

begin
    -- dbms_xmlschema.deleteschema(
    --     'http://xmlns.bendem.be/cc',
    --     dbms_xmlschema.delete_cascade_force);
    dbms_xmlschema.registerschema(
        schemaurl => 'http://xmlns.bendem.be/cc',
        schemadoc => bfilename('XML_DIR', 'cc.xsd'),
        local     => true,
        gentypes  => true,
        gentables => false,
        csid      => nls_charset_id('AL32UTF8'));

    -- dbms_xmlschema.deleteschema(
    --     'http://xmlns.bendem.be/cc_schedules',
    --     dbms_xmlschema.delete_cascade_force);
    dbms_xmlschema.registerschema(
        schemaurl => 'http://xmlns.bendem.be/cc_schedules',
        schemadoc => bfilename('XML_DIR', 'cc_schedules.xsd'),
        local     => true,
        gentypes  => true,
        gentables => false,
        csid      => nls_charset_id('AL32UTF8'));
    commit;
end;
/
