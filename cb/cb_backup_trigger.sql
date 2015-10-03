create or replace trigger cb_backup_trigger
before insert on reviews
for each row
        fk_exception exception;
        pragma exception_init(fk_exception, -2191);
        backup_flag users.backup_flag%type;
begin

    if :new.backup_flag <> 1 then
        -- Prevent a network request
        select backup_flag into backup_flag from users where user_id = :new.user_id;
        if backup_flag = 1 then
            insert into reviews@link.backup (
                review_id,
                user_id,
                movie_id,
                rating,
                creation_date,
                content,
                backup_flag
            ) values (
                :new.review_id,
                :new.user_id,
                :new.movie_id,
                :new.rating,
                :new.creation_date,
                :new.content,
                1
            );
            update reviews set backup_flag = 1 where review_id = :new.review_id;
        end if;
    end if;
exception
    when fk_exception then raise;
        -- TODO if fk_reviews_user_id, user not copied yet
end;
