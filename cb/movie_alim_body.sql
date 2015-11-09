create or replace package body movie_alim is

    procedure insert_movies(
        p_count pls_integer)
    is
        movies movies_ext_t;
        cursor movie_c
            is select * from (
                select * from movies_ext order by dbms_random.value
            ) where rownum < p_count + 1;
    begin
        for rec in movie_c loop
            insert_movie(rec);
        end loop;
    exception
        when others then
            dbms_output.put_line(sqlerrm);
            dbms_output.put_line(dbms_utility.format_call_stack);
            dbms_output.put_line(dbms_utility.format_error_backtrace);
            raise;
    end;

    procedure insert_movie(
        p_movie in movies_ext%rowtype)
    is
        raw_data movies_ext%rowtype;

        y varchar2(1000);

        i pls_integer := 0;
        j pls_integer := 0;

        chars1_v varchar2_t;

        image blob;

        actors_v                      persons_t;
        spoken_languages_v            spoken_languages_t;
        production_countries_v        production_countries_t;
        production_companies_v        production_companies_t;
        directors_v                   persons_t;
        genres_v                      genres_t;
        characters_v                  characters_t;
        certification_rec             certifications%rowtype;
        status_rec                    statuses%rowtype;
        movie_rec                     movies%rowtype;
        movies_actors_characters_v    movies_actors_characters_t;
        movies_spoken_languages_v     movies_spoken_languages_t;
        movies_production_countries_v movies_production_countries_t;
        movies_production_companies_v movies_production_companies_t;
        movies_directors_v            movies_directors_t;
        movies_genres_v               movies_genres_t;
        director_images_v             images_t;
        actor_images_v               images_t;
        exist number(1, 0);
    begin
        begin
            select 1 into exist
            from movies where movie_id = p_movie.id;
        exception
            when no_data_found then
                exist := 0;
        end;

        if exist = 1 then
            logging.i('Update of movie n°' || raw_data.id || ' number of copies starting.');
            update movies set
                movie_copies = movie_copies + round(abs(sys.dbms_random.normal * 2) + 5)
            where movie_id = p_movie.id;
            commit;
            logging.i('Update of movie n°' || raw_data.id || ' number of copies done.');
            return;
        end if;


        raw_data := p_movie;
        logging.i('Start insertion of movie n°' || raw_data.id);
        -- Actors / Characters
        if raw_data.actors <> '[[]]' then
            execute immediate split_request bulk collect into chars1_v using raw_data.actors;

            for i in chars1_v.first..chars1_v.last loop
                characters_v(i).movie_id := raw_data.id;
                movies_actors_characters_v(i).movie_id := raw_data.id;

                j := 1;
                y := regexp_substr(chars1_v(i), split_regex, 1, j);
                while length(y) <> 0 loop
                    y := trim(both ',' from y);
                    case j
                        when 1 then
                            actors_v(i).person_id := y;
                            movies_actors_characters_v(i).person_id := y;
                        when 2 then
                            utils.check_size(y, size_actors_name, size_max_actors_name);
                            actors_v(i).person_name := y;
                        when 3 then
                            characters_v(i).character_id := y;
                            movies_actors_characters_v(i).character_id := y;
                        when 4 then
                            utils.check_size(y, size_characters_name, size_max_characters_name);
                            characters_v(i).character_name := y;
                        when 5 then
                            actor_images_v(i) := httpuritype('http://image.tmdb.org/t/p/w185' || y).getblob();
                    end case;
                    j := j + 1;
                    y := regexp_substr(chars1_v(i), split_regex, 1, j);
                end loop;
            end loop;
        end if;

        -- Directors
        if raw_data.directors <> '[[]]' then
            execute immediate split_request bulk collect into chars1_v using raw_data.directors;

            for i in chars1_v.first..chars1_v.last loop
                movies_directors_v(i).movie_id := raw_data.id;

                j := 1;
                y := regexp_substr(chars1_v(i), split_regex, 1, j);
                while length(y) <> 0 loop
                    y := trim(both ',' from y);
                    case j
                        when 1 then
                            directors_v(i).person_id := y;
                            movies_directors_v(i).person_id := y;
                        when 2 then
                            utils.check_size(y, size_directors_name, size_max_directors_name);
                            directors_v(i).person_name := y;
                        when 3 then
                            director_images_v(i) := httpuritype('http://image.tmdb.org/t/p/w185' || y).getblob();
                    end case;
                    j := j + 1;
                    y := regexp_substr(chars1_v(i), split_regex, 1, j);
                end loop;
            end loop;
        end if;

        -- spoken_languages
        if raw_data.spoken_languages <> '[[]]' then
            execute immediate split_request bulk collect into chars1_v using raw_data.spoken_languages;

            for i in chars1_v.first..chars1_v.last loop
                movies_spoken_languages_v(i).movie_id := raw_data.id;

                j := 1;
                y := regexp_substr(chars1_v(i), split_regex, 1, j);
                while length(y) <> 0 loop
                    y := trim(both ',' from y);
                    case j
                        when 1 then
                            spoken_languages_v(i).spoken_language_id := y;
                            movies_spoken_languages_v(i).spoken_language_id := y;
                        when 2 then
                            utils.check_size(y, size_spoken_languages_name, size_max_spoken_languages_name, null);
                            spoken_languages_v(i).spoken_language_name := y;
                    end case;
                    j := j + 1;
                    y := regexp_substr(chars1_v(i), split_regex, 1, j);
                end loop;
            end loop;
        end if;

        -- production_companies
        if raw_data.production_companies <> '[[]]' then
            execute immediate split_request bulk collect into chars1_v using raw_data.production_companies;

            for i in chars1_v.first..chars1_v.last loop
                movies_production_companies_v(i).movie_id := raw_data.id;

                j := 1;
                y := regexp_substr(chars1_v(i), split_regex, 1, j);
                while length(y) <> 0 loop
                    y := trim(both ',' from y);
                    case j
                        when 1 then
                            production_companies_v(i).production_company_id := y;
                            movies_production_companies_v(i).production_company_id := y;
                        when 2 then
                            utils.check_size(y, size_prod_companies_name, size_max_prod_companies_name);
                            production_companies_v(i).production_company_name := y;
                    end case;
                    j := j + 1;
                    y := regexp_substr(chars1_v(i), split_regex, 1, j);
                end loop;
            end loop;
        end if;

        -- production_countries
        if raw_data.production_countries <> '[[]]' then
            execute immediate split_request bulk collect into chars1_v using raw_data.production_countries;

            for i in chars1_v.first..chars1_v.last loop
                movies_production_countries_v(i).movie_id := raw_data.id;

                j := 1;
                y := regexp_substr(chars1_v(i), split_regex, 1, j);
                while length(y) <> 0 loop
                    y := trim(both ',' from y);
                    case j
                        when 1 then
                            production_countries_v(i).production_country_id := y;
                            movies_production_countries_v(i).production_country_id := y;
                        when 2 then
                            utils.check_size(y, size_prod_countries_name, size_max_prod_countries_name, null);
                            production_countries_v(i).production_country_name := y;
                    end case;
                    j := j + 1;
                    y := regexp_substr(chars1_v(i), split_regex, 1, j);
                end loop;
            end loop;
        end if;

         -- genres
        if raw_data.genres <> '[[]]' then
            execute immediate split_request bulk collect into chars1_v using raw_data.genres;

            for i in chars1_v.first..chars1_v.last loop
                movies_genres_v(i).movie_id := raw_data.id;

                j := 1;
                y := regexp_substr(chars1_v(i), split_regex, 1, j);
                while length(y) <> 0 loop
                    y := trim(both ',' from y);
                    case j
                        when 1 then
                            genres_v(i).genre_id := y;
                            movies_genres_v(i).genre_id := y;
                        when 2 then
                            genres_v(i).genre_name := y;
                    end case;
                    j := j + 1;
                    y := regexp_substr(chars1_v(i), split_regex, 1, j);
                end loop;
            end loop;
        end if;

        utils.check_size(raw_data.title, size_movies_title, size_max_movies_title);
        utils.check_size(raw_data.original_title, size_movies_original_title, size_max_movies_original_title);
        utils.check_size(raw_data.vote_count, size_movies_vote_count, size_max_movies_vote_count);
        utils.check_size(raw_data.runtime, size_movies_runtime, size_max_movies_runtime);
        utils.check_size(raw_data.budget, size_movies_budget, size_max_movies_budget);
        utils.check_size(raw_data.revenue, size_movies_revenue, size_max_movies_revenue);
        utils.check_size(raw_data.homepage, size_movies_homepage, size_max_movies_homepage, null);
        utils.check_size(raw_data.tagline, size_movies_tagline, size_max_movies_tagline, null);

        movie_rec.movie_id             := raw_data.id;
        movie_rec.movie_title          := raw_data.title;
        movie_rec.movie_original_title := raw_data.original_title;
        movie_rec.movie_release_date   := raw_data.release_date;
        movie_rec.movie_vote_avg       := raw_data.vote_average;
        movie_rec.movie_vote_count     := raw_data.vote_count;
        movie_rec.movie_runtime        := raw_data.runtime;
        movie_rec.movie_budget         := raw_data.budget;
        movie_rec.movie_revenue        := raw_data.revenue;
        movie_rec.movie_homepage       := raw_data.homepage;
        movie_rec.movie_tagline        := raw_data.tagline;
        movie_rec.movie_overview       := raw_data.overview;
        movie_rec.movie_copies         := round(abs(sys.dbms_random.normal * 2) + 5);



        image := httpuritype('http://image.tmdb.org/t/p/w185' || raw_data.poster_path).getblob();
        insert into images(image) values (image) returning image_id into i;


        movie_rec.movie_poster_id := i;

        if raw_data.status is not null then
            begin
                utils.check_size(raw_data.status, size_statuses_name, size_max_statuses_name);
                insert into statuses values (null, upper(raw_data.status));
            exception
                when dup_val_on_index then
                    logging.i('Status ' || raw_data.status || ' already present');
            end;
            select status_id into movie_rec.movie_status_id
            from statuses where upper(status_name) = upper(raw_data.status);
        else
            movie_rec.movie_status_id := null;
        end if;

        if raw_data.certification is not null then
            begin
                utils.check_size(raw_data.certification, size_certifications_name, size_max_certifications_name);
                insert into certifications values (null, upper(raw_data.certification));
            exception
                when dup_val_on_index then
                    logging.i('Certification ' || raw_data.certification || ' already present');
            end;
            select certification_id into movie_rec.movie_certification_id
            from certifications where upper(certification_name) = upper(raw_data.certification);
        else
            movie_rec.movie_certification_id := null;
        end if;

        -- INSERTS
        if actors_v.count <> 0 then
            for i in actors_v.first .. actors_v.last loop
                begin
                    if actor_images_v.exists(i) then
                        insert into images(image) values (actor_images_v(i)) returning image_id into j;
                        actors_v(i).person_profile_id := j;
                    end if;
                    insert into persons values actors_v(i);
                exception
                    when dup_val_on_index then
                        null;
                end;
            end loop;
        end if;

        if spoken_languages_v.count <> 0 then
            for i in spoken_languages_v.first .. spoken_languages_v.last loop
                begin
                    insert into spoken_languages values spoken_languages_v(i);
                exception
                    when dup_val_on_index then
                        if spoken_languages_v(i).spoken_language_name is not null then
                            update spoken_languages set spoken_language_name = spoken_languages_v(i).spoken_language_name where spoken_language_id = spoken_languages_v(i).spoken_language_id;
                        end if;
                end;
            end loop;
        end if;

        if production_countries_v.count <> 0 then
            for i in production_countries_v.first .. production_countries_v.last loop
                begin
                    insert into production_countries values production_countries_v(i);
                exception
                    when dup_val_on_index then
                        if production_countries_v(i).production_country_name is not null then
                            update production_countries set production_country_name = production_countries_v(i).production_country_name where production_country_id = production_countries_v(i).production_country_id;
                        end if;
                end;
            end loop;
        end if;

        if production_companies_v.count <> 0 then
            for i in production_companies_v.first .. production_companies_v.last loop
                begin
                    insert into production_companies values production_companies_v(i);
                exception
                    when dup_val_on_index then
                        null;
                end;
            end loop;
        end if;

        if directors_v.count <> 0 then
            for i in directors_v.first .. directors_v.last loop
                begin
                    if director_images_v.exists(i) then
                        insert into images(image) values (director_images_v(i)) returning image_id into j;
                        directors_v(i).person_profile_id := j;
                    end if;
                    insert into persons values directors_v(i);
                exception
                    when dup_val_on_index then
                        null;
                end;
            end loop;
        end if;

        if genres_v.count <> 0 then
            for i in genres_v.first .. genres_v.last loop
                begin
                    insert into genres values genres_v(i);
                exception
                    when dup_val_on_index then
                        null;
                end;
            end loop;
        end if;

        insert into movies values movie_rec;

        if characters_v.count <> 0 then
            for i in characters_v.first .. characters_v.last loop
                begin
                    insert into characters values characters_v(i);
                exception
                    when dup_val_on_index then
                        null;
                end;
            end loop;
        end if;

        if movies_spoken_languages_v.count <> 0 then
            for i in movies_spoken_languages_v.first .. movies_spoken_languages_v.last loop
                insert into movies_spoken_languages values movies_spoken_languages_v(i);
            end loop;
        end if;

        if movies_production_companies_v.count <> 0 then
            for i in movies_production_companies_v.first .. movies_production_companies_v.last loop
                insert into movies_production_companies values movies_production_companies_v(i);
            end loop;
        end if;

        if movies_production_countries_v.count <> 0 then
            for i in movies_production_countries_v.first .. movies_production_countries_v.last loop
                insert into movies_production_countries values movies_production_countries_v(i);
            end loop;
        end if;

        if movies_directors_v.count <> 0 then
            for i in movies_directors_v.first .. movies_directors_v.last loop
                insert into movies_directors values movies_directors_v(i);
            end loop;
        end if;

        if movies_genres_v.count <> 0 then
            for i in movies_genres_v.first .. movies_genres_v.last loop
                insert into movies_genres values movies_genres_v(i);
            end loop;
        end if;

        if movies_actors_characters_v.count <> 0 then
            for i in movies_actors_characters_v.first .. movies_actors_characters_v.last loop
                insert into movies_actors_characters values movies_actors_characters_v(i);
            end loop;
        end if;

        commit;
        logging.i('Succesful insertion of movie n°' || raw_data.id);
    exception
        when others then
            logging.e('Error during the inserting of movie n°' || p_movie.id);
            dbms_output.put_line(sqlerrm);
            dbms_output.put_line(dbms_utility.format_call_stack);
            dbms_output.put_line(dbms_utility.format_error_backtrace);
            rollback;
    end;

end movie_alim;
/
