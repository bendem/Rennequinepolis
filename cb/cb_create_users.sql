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
grant execute on sys.dbms_lock to myrole;
grant execute on sys.owa_opt_lock to myrole;

create user cb identified by dummy
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;
alter user cb quota unlimited on users;
grant myrole to cb;

create user cbb identified by dummy
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;
alter user cbb quota unlimited on users;
grant myrole to cbb;
