create user dw identified by &dw_pwd
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;
alter user dw quota unlimited on users;

grant alter session to dw;
grant create database link to dw;
grant create session to dw;
grant create procedure to dw;
grant create sequence to dw;
grant create table to dw;
grant create trigger to dw;
grant create type to dw;
grant create synonym to dw;
grant create view to dw;
grant create job to dw;
grant create materialized view to dw;
grant create database link to dw;
