create or replace package body cb_thing is

    procedure add_user(
        lastname users.lastname%type,
        firstname users.firstname%type
    ) is
    begin
        insert into users (
            lastname,
            firstname,
            backup_flag
        ) values (
            lastname,
            firstname,
            0
        );
    exception
        -- will come later...
        -- when dup_val_on_index then
        --     raise_application_error(20001, '')
    end;

    procedure add_review(
        user_id       reviews.user_id%type,
        movie_id      reviews.movie_id%type,
        rating        reviews.rating%type,
        creation_date reviews.creation_date%type,
        content       reviews.content%type
    ) is
        fk_exception exception;
        pragma exception_init(fk_exception, -2191);
    begin
        insert into reviews (
            user_id,
            movie_id,
            rating,
            creation_date,
            content,
            backup_flag
        ) values (
            user_id,
            movie_id,
            rating,
            creation_date,
            content,
            0
        );
    exception
        when fk_exception then
            raise_application_error(20001, '');
    end;

    procedure async_backup() is
        type users_t is table of users%rowtype index by pls_integer;
        type reviews_t is table of reviews%rowtype index by pls_integer;

        users_to_backup users_t;
        reviews_to_backup reviews_t;
    begin
        select
            user_id,
            lastname,
            firstname,
            1
        into users_to_backup
        from users
        where backup_flag = 0;
        insert into users@link.users values users_to_backup;

        select
            review_id,
            user_id,
            movie_id,
            rating,
            creation_date,
            content,
            1
        into reviews_to_backup
        from reviews
        where backup_flag = 0;
        insert into reviews@link.reviews values reviews_to_backup;
    end;

end cb_thing;
