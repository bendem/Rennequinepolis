create or replace package body backup is

    procedure propagate_changes is
    begin
        logging.i('Starting backup job');
        backup.propagate_user_deletions;
        backup.propagate_user_changes;
        backup.propagate_movie_changes;
        backup.propagate_copy_changes;
        backup.propagate_review_changes;
        logging.i('Backup job done');
        commit;
    exception
        when others then
            logging.e('Backup job failed:' || sqlerrm);
            rollback;
    end;

    procedure propagate_user_deletions is
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

    procedure propagate_copy_deletions is
    begin
        -- Remove marked copies
        delete from copies@link.backup where (copy_id, movie_id) in (
            select copy_id, movie_id from copies where backup_flag = 2
        );
        delete from copies where backup_flag = 2;
    end;

    procedure propagate_user_changes is
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
            where u.creation_date < p.creation_date
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

    procedure propagate_review_changes is
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

        update reviews set backup_flag = 1 where backup_flag = 0;
    end;

    procedure propagate_movie_changes is
        ids number_t;
    begin
        --select movie_id bulk collect into ids from movies where backup_flag = 0;

        Logging.i('Transfering Images');
        merge into images@link.backup there using (
            select * from images where image_id in (
                select movie_poster_id from movies where movie_id in (
                    select movie_id from movies where backup_flag = 0
                )
                union
                select person_profile_id from people where person_id in (
                    select person_id from movies_directors where movie_id in (
                        select movie_id from movies where backup_flag = 0
                    )
                    union
                    select person_id from characters where movie_id in (
                        select movie_id from movies where backup_flag = 0
                    )
                )
            )
        ) here on (there.image_id = here.image_id)
        when not matched then
            insert values (
                here.image_id,
                here.image_path,
                here.image
            );

        Logging.i('Transfering people');
        merge into people@link.backup there using (
            select * from people where person_id in (
                select person_id from movies_directors where movie_id in (
                    select movie_id from movies where backup_flag = 0
                )
                union
                select person_id from characters where movie_id in (
                    select movie_id from movies where backup_flag = 0
                )
            )
        ) here on (there.person_id = here.person_id)
        when not matched then
            insert values (
                here.person_id,
                here.person_name,
                here.person_profile_id
            );

        Logging.i('Transfering genres');
        merge into genres@link.backup there using (
            select * from genres where genre_id in (
                select genre_id from movies_genres where movie_id in (
                    select movie_id from movies where backup_flag = 0
                )
            )
        ) here on (there.genre_id = here.genre_id)
        when not matched then
            insert values (
                here.genre_id,
                here.genre_name
            );

        Logging.i('Transfering certifications');
        merge into certifications@link.backup there using (
            select * from certifications where certification_id in (
                select certification_id from movies where movie_id in (
                    select movie_id from movies where backup_flag = 0
                )
            )
        ) here on (there.certification_id = here.certification_id)
        when not matched then
            insert values (
                here.certification_id,
                here.certification_name
            );

        Logging.i('Transfering statuses');
        merge into statuses@link.backup there using (
            select * from statuses where status_id in (
                select status_id from movies where movie_id in (
                    select movie_id from movies where backup_flag = 0
                )
            )
        ) here on (there.status_id = here.status_id)
        when not matched then
            insert values (
                here.status_id,
                here.status_name
            );

        Logging.i('Transfering spoken_languages');
        merge into spoken_languages@link.backup there using (
            select * from spoken_languages where spoken_language_id in (
                select spoken_language_id from movies_spoken_languages where movie_id in (
                    select movie_id from movies where backup_flag = 0
                )
            )
        ) here on (there.spoken_language_id = here.spoken_language_id)
        when not matched then
            insert values (
                here.spoken_language_id,
                here.spoken_language_name
            );

        Logging.i('Transfering production_countries');
        merge into production_countries@link.backup there using (
            select * from production_countries where production_country_id in (
                select production_country_id from movies_production_countries where movie_id in (
                    select movie_id from movies where backup_flag = 0
                )
            )
        ) here on (there.production_country_id = here.production_country_id)
        when not matched then
            insert values (
                here.production_country_id,
                here.production_country_name
            );

        Logging.i('Transfering production_companies');
        merge into production_companies@link.backup there using (
            select * from production_companies where production_company_id in (
                select production_company_id from movies_production_companies where movie_id in (
                    select movie_id from movies where backup_flag = 0
                )
            )
        ) here on (there.production_company_id = here.production_company_id)
        when not matched then
            insert values (
                here.production_company_id,
                here.production_company_name
            );

        Logging.i('Transfering movies');
        merge into movies@link.backup there using (
            select
                movie_id,
                movie_title,
                movie_original_title,
                movie_release_date,
                movie_status_id,
                movie_certification_id,
                movie_vote_avg,
                movie_vote_count,
                movie_runtime,
                movie_poster_id,
                movie_budget,
                movie_revenue,
                movie_homepage,
                movie_tagline,
                movie_overview,
                movie_copies,
                backup_flag
            from movies p
            where backup_flag = 0
        ) here on (there.movie_id = here.movie_id)
        when not matched then
            insert values (
                here.movie_id,
                here.movie_title,
                here.movie_original_title,
                here.movie_release_date,
                here.movie_status_id,
                here.movie_certification_id,
                here.movie_vote_avg,
                here.movie_vote_count,
                here.movie_runtime,
                here.movie_poster_id,
                here.movie_budget,
                here.movie_revenue,
                here.movie_homepage,
                here.movie_tagline,
                here.movie_overview,
                here.movie_copies,
                1
            );

        Logging.i('Transfering movies_production_countries');
        merge into movies_production_countries@link.backup there using (
            select * from movies_production_countries where movie_id in (
                select movie_id from movies where backup_flag = 0
            )
        ) here on (there.movie_id = here.movie_id and there.production_country_id = here.production_country_id)
        when not matched then
            insert values (
                here.movie_id,
                here.production_country_id
            );

        Logging.i('Transfering movies_production_companies');
        merge into movies_production_companies@link.backup there using (
            select * from movies_production_companies where movie_id in (
                select movie_id from movies where backup_flag = 0
            )
        ) here on (there.movie_id = here.movie_id and there.production_company_id = here.production_company_id)
        when not matched then
            insert values (
                here.movie_id,
                here.production_company_id
            );

        Logging.i('Transfering movies_directors');
        merge into movies_directors@link.backup there using (
            select * from movies_directors where movie_id in (
                select movie_id from movies where backup_flag = 0
            )
        ) here on (there.movie_id = here.movie_id and there.person_id = here.person_id)
        when not matched then
            insert values (
                here.movie_id,
                here.person_id
            );

        Logging.i('Transfering movies_genres');
        merge into movies_genres@link.backup there using (
            select * from movies_genres where movie_id in (
                select movie_id from movies where backup_flag = 0
            )
        ) here on (there.movie_id = here.movie_id and there.genre_id = here.genre_id)
        when not matched then
            insert values (
                here.movie_id,
                here.genre_id
            );

        Logging.i('Transfering characters');
        merge into characters@link.backup there using (
            select * from characters where movie_id in (
                select movie_id from movies where backup_flag = 0
            )
        ) here on (there.movie_id = here.movie_id and there.character_id = here.character_id)
        when not matched then
            insert values (
                here.movie_id,
                here.character_id,
                here.person_id,
                here.character_name
            );

        Logging.i('Transfering copies');
        merge into copies@link.backup there using (
            select * from copies where movie_id in (
                select movie_id from movies where backup_flag = 0
            )
        ) here on (there.movie_id = here.movie_id)
        when not matched then
            insert values (
                here.movie_id,
                here.copy_id,
                1
            );

        update movies set backup_flag = 1 where backup_flag = 0;
        update copies set backup_flag = 1 where backup_flag = 0;
    end;

    procedure propagate_copy_changes is
    begin
        merge into copies@link.backup there using (
            select * from copies
            where backup_flag = 0
        ) here on (there.movie_id = here.movie_id)
        when not matched then
            insert values (
                here.movie_id,
                here.copy_id,
                1
            );
        update copies set backup_flag = 1 where backup_flag = 0;
    end;

    procedure sync_propagation is
        pragma autonomous_transaction;
    begin
        backup.propagate_review_changes;
        backup.propagate_copy_changes;
        commit;
    exception
        when others then
            Logging.e('sync_propagation fail');
            rollback;
    end;

end backup;
/
