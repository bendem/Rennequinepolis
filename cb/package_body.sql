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
            insert_log('Failed to add a user: ' || sqlerrm);
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
            insert_log('Failed to add a review: ' || sqlerrm);
            raise;
    end;

    procedure delete_user(
        p_username  users.username%type
    ) is
    begin
        update users set backup_flag = 2 where username = p_username;
        update reviews set backup_flag = 2 where username = p_username;
    exception
        when others then raise;
    end;

    procedure delete_review(
        p_username reviews.username%type,
        p_movie_id reviews.movie_id%type
    ) is
    begin
        delete from reviews@link.backup
        where
            username = p_username
            and movie_id = p_movie_id;

        delete from reviews
        where
            username = p_username
            and movie_id = p_movie_id;
    exception
        when others then
            insert_log('Failed to remove review: ' || sqlerrm);
            raise;
    end;

end cb_thing;
/

exit
