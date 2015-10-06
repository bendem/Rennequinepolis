-- Create view of available user (backup_flag != 2)
create or replace view available_users as
    select username, password, lastname, firstname, creation_date
    from users
    where backup_flag != 2;
