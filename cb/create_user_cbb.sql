create role cbb_role not identified;
grant alter session to cbb_role;
grant create database link to cbb_role;
grant create session to cbb_role;
grant create procedure to cbb_role;
grant create sequence to cbb_role;
grant create table to cbb_role;
grant create trigger to cbb_role;
grant create type to cbb_role;
grant create synonym to cbb_role;
grant create view to cbb_role;
grant create job to cbb_role;
grant create materialized view to cbb_role;
grant create any directory to cbb_role;

create user cbb identified by &cbb_pwd
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;
alter user cbb quota unlimited on users;
grant cbb_role to cbb;

grant execute on dbms_lock to cbb;
grant execute on sys.owa_opt_lock to cbb;
