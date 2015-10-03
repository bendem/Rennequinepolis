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
        when others then raise;
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

    procedure async_backup is
    begin
        insert into users@link.backup
          select
            user_id,
            lastname,
            firstname,
            current_date,
            1
          from users
          where backup_flag = 0;

        insert into reviews@link.backup
          select
              review_id,
              user_id,
              movie_id,
              rating,
              creation_date,
              content,
              1
          from reviews
          where backup_flag = 0;
    end;

end cb_thing;
