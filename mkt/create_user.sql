create user mkt identified by &mkt_pwd
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;
alter user mkt quota unlimited on users;

grant alter session to mkt;
grant create database link to mkt;
grant create session to mkt;
grant create procedure to mkt;
grant create sequence to mkt;
grant create table to mkt;
grant create trigger to mkt;
grant create type to mkt;
grant create synonym to mkt;
grant create view to mkt;
grant create job to mkt;
grant create materialized view to mkt;
grant create database link to mkt;
