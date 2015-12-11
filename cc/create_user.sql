create user cc identified by &cc_pwd
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;
alter user cc quota unlimited on users;
grant cb_role to cc;
