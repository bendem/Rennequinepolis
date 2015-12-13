create or replace package body management is

    procedure add_user(
        p_username  in users.username%type,
        p_password  in users.password%type,
        p_lastname  in users.lastname%type,
        p_firstname in users.firstname%type)
    is
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
        p_username in reviews.username%type,
        p_movie_id in reviews.movie_id%type,
        p_rating   in reviews.rating%type,
        p_content  in reviews.content%type)
    is
        fk_exception exception;
        pragma exception_init(fk_exception, -2291);
    begin
        link_check.check_link_available;

        merge into reviews r using (
            select p_username username, p_movie_id movie_id
            from dual
        ) p on (r.username = p.username and r.movie_id = p.movie_id)
        when matched then
            update set
                r.rating = p_rating,
                r.creation_date = current_date,
                r.content = p_content,
                r.backup_flag = 0
        when not matched then
            insert values (
                p_username,
                p_movie_id,
                p_rating,
                current_date,
                p_content,
                0
            );
    exception
        when fk_exception then
            case
                when sqlerrm like '%FK_REVIEWS_MOVIE_ID%' then
                    raise_application_error(-20001, 'Internal error, restart your search');
                when sqlerrm like '%FK_REVIEWS_USERNAME%' then
                    raise_application_error(-20002, 'Internal error, your session is invalid');
                else
                    raise;
            end case;
        when others then
            logging.e('Failed to add a review: ' || sqlerrm);
            raise;
    end;

    procedure delete_user(
        p_username in users.username%type)
    is
    begin
        update users set backup_flag = 2 where username = p_username;
        update reviews set backup_flag = 2 where username = p_username;
    exception
        when others then
            logging.e('Failed to remove a user: ' || sqlerrm);
            raise;
    end;

    procedure delete_review(
        p_username in reviews.username%type,
        p_movie_id in reviews.movie_id%type)
    is
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
        p_userafter  in users%rowtype)
    is
        busy_exception      exception;
        not_found_exception exception;
        not_equal_exception exception;
        pkey_null           exception;

        pragma exception_init(busy_exception ,-0054);
        pragma exception_init(pkey_null, -1400);

        i number;

        user users%rowtype;
    begin
        i := 0;
        user.username := NULL;

        -- Try to get the ressource needed
        while (i < 3) loop
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
    end modify_user;

    procedure modify_review(
        p_reviewbefore in reviews%rowtype,
        p_reviewafter  in reviews%rowtype)
    is
        busy_exception      exception;
        not_found_exception exception;
        not_equal_exception exception;
        pkey_null           exception;
        fkey_exception      exception;

        pragma exception_init(busy_exception ,-0054);
        pragma exception_init(pkey_null, -1400);
        pragma exception_init(fkey_exception, -2291);

        i number;

        review reviews%rowtype;
    begin
        i := 0;
        review.username := null;
        review.movie_id := null;

        -- Try to get the ressource needed
        while (i < 3) loop
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
    end modify_review;

    function check_user(
        p_username in users.username%type,
        p_password in users.password%type) return char
    is
        u users%rowtype;
    begin
        select * into u from users
        where
            username = p_username
            and password = p_password
            and backup_flag <> 2;
        return '1';
    exception
        when no_data_found then
            return '0';
    end check_user;

    procedure remove_copies(
        p_copies copies_t)
    is
    begin
        forall i in indices of p_copies
            update copies set backup_flag = 2
            where
                copy_id = p_copies(i).copy_id
                and movie_id = p_copies(i).movie_id
                ;

        begin
            backup.propagate_copy_deletions;
        exception
            when others then
                logging.i('Failed to propagate copy deletions, scheduled for next backup job');
        end;
    end remove_copies;

end management;
/
