create or replace package body backup is

    procedure do_the_thing is
    begin
        insert_log('Starting backup job');
        backup.delete_them_userz;
        backup.copy_them_userz;
        backup.copy_them_reviewz;
        insert_log('Backup job done');
        -- implicit commit by dbms_scheduler
    exception
        when others then
            insert_log('Backup job failed:' || sqlerrm);
            raise;
    end;

    procedure delete_them_userz is
    begin
        -- Remove marked users
        delete from reviews@link.backup where username in (
            select username from users where backup_flag = 2
        );
        delete from users@link.backup where username in (
            select username from users where backup_flag = 2
        );
        delete from reviews where username in (
            select username from users where backup_flag = 2
        );
        delete from users where backup_flag = 2;
    end;

    procedure copy_them_userz is
    begin
        merge into users@link.backup u using (
            select
                username,
                password,
                lastname,
                firstname,
                creation_date,
                backup_flag
            from users
            where backup_flag = 0
        ) p on (u.username = p.username)
        when matched then
            update set
                u.password = p.password,
                u.lastname = p.lastname,
                u.firstname = p.firstname,
                u.creation_date = p.creation_date,
                u.backup_flag = 1
        when not matched then
            insert values (
                p.username,
                p.password,
                p.lastname,
                p.firstname,
                p.creation_date,
                1
            );
        update users set backup_flag = 1 where backup_flag = 0;
    end;

    procedure copy_them_reviewz is
    begin
        merge into reviews@link.backup u using (
            select
                username,
                movie_id,
                rating,
                creation_date,
                content,
                backup_flag
            from reviews
            where backup_flag = 0
        ) p on (u.username = p.username and u.movie_id = p.movie_id)
        when matched then
            update set
                u.rating = p.rating,
                u.creation_date = p.creation_date,
                u.content = p.content,
                u.backup_flag = 1
        when not matched then
            insert values (
                p.username,
                p.movie_id,
                p.rating,
                p.creation_date,
                p.content,
                1
            );

        update reviews set backup_flag = 1 where backup_flag = 0;
    end;

end backup;
/
