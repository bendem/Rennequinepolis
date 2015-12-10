create role cb_role not identified;
grant alter session to cb_role;
grant create database link to cb_role;
grant create session to cb_role;
grant create procedure to cb_role;
grant create sequence to cb_role;
grant create table to cb_role;
grant create trigger to cb_role;
grant create type to cb_role;
grant create synonym to cb_role;
grant create view to cb_role;
grant create job to cb_role;
grant create materialized view to cb_role;
grant create any directory to cb_role;

create user cb identified by &cb_pwd
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;
alter user cb quota unlimited on users;
grant cb_role to cb;

create user cbb identified by &cb_pwd
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;
alter user cbb quota unlimited on users;
grant cb_role to cbb;

grant execute on dbms_lock to cb;
grant execute on utl_file to cb;
grant execute on utl_http to cb;
grant execute on dbms_lock to cbb;
grant execute on sys.owa_opt_lock to cb;
grant execute on sys.owa_opt_lock to cbb;

-- TODO Should 'http.xml' be configurable?
begin
    dbms_output.put_line('Creating acl');
    dbms_network_acl_admin.create_acl(
        acl => 'http.xml',
        description => 'HTTP Access',
        principal => 'CB',
        is_grant => true,
        privilege => 'resolve');

    dbms_output.put_line('Adding connect privilege');
    dbms_network_acl_admin.add_privilege(
        acl => 'http.xml',
        principal => 'CB',
        is_grant => true,
        privilege => 'connect');

    dbms_output.put_line('Assigning accl');
    dbms_network_acl_admin.assign_acl(
        acl => 'http.xml',
        host => '*',
        lower_port => 80,
        upper_port => 80);

    commit;
exception
    when others then
        dbms_output.put_line('*******************************');
        dbms_output.put_line('*******************************');
        dbms_output.put_line('*******************************');
        dbms_output.put_line('** ACL suck, fix it yourself **');
        dbms_output.put_line('*******************************');
        dbms_output.put_line('*******************************');
        dbms_output.put_line('*******************************');
        dbms_output.put_line(sqlerrm);
end;
/
