-- Backups changes made to a review if its owner is already up to date with
-- its backup counter part.
create or replace trigger backup_reviews_trigger
before insert or update on reviews
for each row
declare
    fk_exception exception;
    pragma exception_init(fk_exception, -2191);

    backup_flag users.backup_flag%type;
begin
    if :new.backup_flag = 0 then
        -- Prevent a network request through the db link
        select backup_flag into backup_flag from users where username = :new.username;
        if backup_flag = 1 then
            merge into reviews@link.backup u using (
                select
                    :new.username username,
                    :new.movie_id movie_id,
                    :new.rating rating,
                    :new.creation_date creation_date,
                    :new.content content,
                    :new.backup_flag backup_flag
                from dual
            ) p on (u.username = p.username and u.movie_id = p.movie_id)
            when matched then
                update set
                    u.rating = p.rating,
                    u.creation_date = p.creation_date,
                    u.content = p.content,
                    u.backup_flag = 1
                -- FIXME This should prevent overriding a more recent reviews
                -- but it's causing more problems than it solves.
                --where u.creation_date < p.creation_date
            when not matched then
                insert values (
                    p.username,
                    p.movie_id,
                    p.rating,
                    p.creation_date,
                    p.content,
                    1
                );
            :new.backup_flag := 1;
        end if;
    end if;
exception
    when others then
        logging.e(sqlerrm);
        raise;
end;
/

-- Backups changes made to a movie copy.
create or replace trigger backup_copies_trigger
before insert on copies
for each row
declare
    fk_exception exception;
    pragma exception_init(fk_exception, -2191);

    backup_flag users.backup_flag%type;
begin
    if :new.backup_flag = 0 then
        -- Prevent a network request through the db link
        select backup_flag into backup_flag from movies where movie_id = :new.movie_id;
        if backup_flag = 1 then
            insert into copies@link.backup (
                movie_id,
                copy_id,
                backup_flag
            ) values (
                :new.movie_id,
                :new.copy_id,
                1
            );
            :new.backup_flag := 1;
        end if;
    end if;
exception
    when others then
        logging.e(sqlerrm);
        raise;
end;
/
