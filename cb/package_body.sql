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
            logging.e('Failed to add a user: ' || sqlerrm);
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
            logging.e('Failed to add a review: ' || sqlerrm);
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
            logging.e('Failed to remove review: ' || sqlerrm);
            raise;
    end;

    procedure modify_user(
        p_userbefore in users%rowtype,
        p_userafter  in users%rowtype
    )
    AS
        busy_exception      exception;
        not_found_exception exception;
        not_equal_exception exception;
        pkey_null           exception;

        pragma exception_init(busy_exception ,-0054);
        pragma exception_init(pkey_null, -1400);

        i number;

        user users%rowtype;
    BEGIN
        i := 0;
        user.username := NULL;

        -- Try to get the ressource needed
        while (i < 3)
        loop
            begin
                select * into user
                from users
                where username = p_userbefore.username and backup_flag <> 2
                for update nowait;
                i := 3;
            exception
                when busy_exception then
                    i := i + 1;
                    dbms_lock.sleep(3 * i);
                when no_data_found then
                    raise not_found_exception;
            end;
        end loop;

        -- Check if we got the ressource we needed
        if (user.username is null) then
            raise busy_exception;
        end if;


        -- Compare the old record with the one we just read
        if (owa_opt_lock.checksum(p_userbefore.password || p_userbefore.lastname || p_userbefore.firstname || to_char(p_userbefore.creation_date, 'yyyymmdd'))
                <> owa_opt_lock.checksum(user.password || user.lastname || user.firstname || to_char(user.creation_date, 'yyyymmdd'))) then
            raise not_equal_exception;
        end if;

        -- Update the record
        update users
        set password = p_userafter.password,
            lastname = p_userafter.lastname,
            firstname = p_userafter.firstname,
            backup_flag = 0
        where username = user.username;
        commit;

    exception
        when busy_exception then
            logging.e('Busy when modifying user: ' || sqlerrm);
            raise_application_error(-20160, 'Record is busy');
        when not_found_exception then
            logging.e('User to modify not found: ' || sqlerrm);
            raise_application_error(-20161, 'Record not found');
        when not_equal_exception then
            logging.e('User modification mismatch: ' || sqlerrm);
            raise_application_error(-20162, 'Record has been modified before your modification could be applied');
            rollback;
        when dup_val_on_index then
            logging.e('Duplicated value on index: ' || sqlerrm);
            raise_application_error(-20140, 'Primary key already in use');
        when pkey_null then
            logging.e('Primary key was null: ' || sqlerrm);
            raise_application_error(-20141, 'Primary key can''t be null');
        when others then raise;
    end modify_user;

    procedure modify_review(
        p_reviewbefore in reviews%rowtype,
        p_reviewafter  in reviews%rowtype
    )
    AS
        busy_exception      exception;
        not_found_exception exception;
        not_equal_exception exception;
        pkey_null           exception;
        fkey_exception       exception;

        pragma exception_init(busy_exception ,-0054);
        pragma exception_init(pkey_null, -1400);
        pragma exception_init(fkey_exception, -2291);

        i number;

        review reviews%rowtype;
    BEGIN
        i := 0;
        review.username := null;
        review.movie_id := null;

        -- Try to get the ressource needed
        while (i<3)
        loop
            begin
                select * into review
                from reviews
                where username = p_reviewbefore.username
                    and movie_id = p_reviewbefore.movie_id
                    and backup_flag <> 2
                for update nowait;

                i := 3;
            exception
                when busy_exception then
                    i := i+1;
                    dbms_lock.sleep(3 * i);
                when no_data_found then
                    raise not_found_exception;
            end;
        end loop;

        -- Check if we got the ressource we needed
        if (review.username is null or review.movie_id is null) then
            raise busy_exception;
        end if;


        -- Compare the old record with the one we just read
        if (owa_opt_lock.checksum(p_reviewbefore.rating || p_reviewbefore.content || to_char(p_reviewbefore.creation_date, 'yyyymmdd'))
                <> owa_opt_lock.checksum(review.rating || review.content || to_char(review.creation_date, 'yyyymmdd'))) then
            raise not_equal_exception;
        end if;

        -- Update the record
        update reviews
        set rating = p_reviewafter.rating,
            content = p_reviewafter.content,
            backup_flag = 0
        where username = review.username
            and movie_id = review.movie_id;
        commit;

    exception
        when busy_exception then
            logging.e('Busy when modifying review: ' || sqlerrm);
            raise_application_error(-20160, 'Record is busy');
        when not_found_exception then
            logging.e('Review to modify not found: ' || sqlerrm);
            raise_application_error(-20161, 'Record not found');
        when not_equal_exception then
            logging.e('Data mismatch on review update: ' || sqlerrm);
            raise_application_error(-20162, 'Record has been modified before your modification could be applied');
            rollback;
        when dup_val_on_index then
            raise_application_error(-20140, 'Primary key already in use');
        when pkey_null then
            raise_application_error(-20141, 'Primary key can''t be null');
        when fkey_exception then
            case
                when sqlerrm like '%fk_reviews_username%' then
                    raise_application_error(-20142, 'Username referenced wasn''t found. (' || p_reviewafter.username || ')');
            end case;
        when others then
            raise;
    end modify_review;

end cb_thing;
/
