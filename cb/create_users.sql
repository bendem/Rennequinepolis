create role myrole not identified;
grant alter session to myrole;
grant create database link to myrole;
grant create session to myrole;
grant create procedure to myrole;
grant create sequence to myrole;
grant create table to myrole;
grant create trigger to myrole;
grant create type to myrole;
grant create synonym to myrole;
grant create view to myrole;
grant create job to myrole;
grant create materialized view to myrole;
grant create any directory to myrole;

create user cb identified by &cb_pwd
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;
alter user cb quota unlimited on users;
grant myrole to cb;

create user cbb identified by &cb_pwd
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;
alter user cbb quota unlimited on users;
grant myrole to cbb;

grant execute on dbms_lock to cb;
grant execute on utl_file to cb;
grant execute on utl_http to cb;
grant execute on dbms_lock to cbb;
grant execute on sys.owa_opt_lock to cb;
grant execute on sys.owa_opt_lock to cbb;

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
