create or replace package body cb_thing is

    procedure add_user(
        p_username  users.username%type,
        p_password  users.password%type,
        p_lastname  users.lastname%type,
        p_firstname users.firstname%type
    ) is
    begin
        insert into users (
            username,
            password,
            lastname,
            firstname,
            backup_flag
        ) values (
            p_username,
            p_password,
            p_lastname,
            p_firstname,
            0
        );
    exception
        -- will come later...
        -- when dup_val_on_index then
        --     raise_application_error(20001, '')
        when others then
            insert_log(sqlerrm);
            raise;
    end;

    procedure add_review(
        p_username reviews.username%type,
        p_movie_id reviews.movie_id%type,
        p_rating   reviews.rating%type,
        p_content  reviews.content%type
    ) is
        fk_exception exception;
        pragma exception_init(fk_exception, -2191);
    begin
        insert into reviews (
            username,
            movie_id,
            rating,
            content,
            backup_flag
        ) values (
            p_username,
            p_movie_id,
            p_rating,
            p_content,
            0
        );
    exception
        when fk_exception then
            raise_application_error(20001, '');
        when others then
            insert_log(sqlerrm);
            raise;
    end;

    procedure async_backup is
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

        update users set backup_flag = 1 where backup_flag = 0;
        update reviews set backup_flag = 1 where backup_flag = 0;
        insert_log('Async backup done');
        -- implicit commit by dbms_scheduler
    exception
        when others then
            insert_log(sqlerrm);
            raise;
    end;

end cb_thing;
/

exit
