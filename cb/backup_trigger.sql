create or replace trigger cb_backup_trigger
before insert or update on reviews
for each row
declare
    fk_exception exception;
    pragma exception_init(fk_exception, -2191);

    backup_flag users.backup_flag%type;
begin
    if :new.backup_flag = 0 then
        -- Prevent a network request
        select backup_flag into backup_flag from users where username = :new.username;
        if backup_flag = 1 then
            if inserting then
                insert into reviews@link.backup (
                    username,
                    movie_id,
                    rating,
                    creation_date,
                    content,
                    backup_flag
                ) values (
                    :new.username,
                    :new.movie_id,
                    :new.rating,
                    :new.creation_date,
                    :new.content,
                    1
                );
            end if;

            if updating then
                update reviews@link.backup set
                    username = :new.username,
                    movie_id = :new.movie_id,
                    rating = :new.rating,
                    creation_date = :new.creation_date,
                    content = :new.content,
                    backup_flag = 1
                where username = :new.username and movie_id = :new.movie_id;
            end if;

            :new.backup_flag := 1;
        end if;
    end if;
exception
    when others then
        logging.e(sqlerrm);
        raise;
end;
/

exit
