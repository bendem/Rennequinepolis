create role cc_role not identified;
grant alter session to cc_role;
grant create database link to cc_role;
grant create session to cc_role;
grant create procedure to cc_role;
grant create sequence to cc_role;
grant create table to cc_role;
grant create trigger to cc_role;
grant create type to cc_role;
grant create synonym to cc_role;
grant create view to cc_role;
grant create job to cc_role;
grant create materialized view to cc_role;
grant create any directory to cc_role;

create user cc identified by &cc_pwd
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;
alter user cc quota unlimited on users;
grant cc_role to cc;
