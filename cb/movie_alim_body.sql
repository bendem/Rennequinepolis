create or replace package body movie_alim is

    type id_path_r is record (
        id   images.image_id%type,
        path images.image_path%type
    );

    type movies_ext_t                  is table of movies_ext%rowtype                  index by pls_integer;
    type people_t                      is table of people%rowtype                      index by pls_integer;
    type spoken_languages_t            is table of spoken_languages%rowtype            index by pls_integer;
    type production_countries_t        is table of production_countries%rowtype        index by pls_integer;
    type production_companies_t        is table of production_companies%rowtype        index by pls_integer;
    type genres_t                      is table of genres%rowtype                      index by pls_integer;
    type characters_t                  is table of characters%rowtype                  index by pls_integer;
    type movies_spoken_languages_t     is table of movies_spoken_languages%rowtype     index by pls_integer;
    type movies_production_countries_t is table of movies_production_countries%rowtype index by pls_integer;
    type movies_production_companies_t is table of movies_production_companies%rowtype index by pls_integer;
    type movies_directors_t            is table of movies_directors%rowtype            index by pls_integer;
    type movies_genres_t               is table of movies_genres%rowtype               index by pls_integer;
    type image_ids_t                   is table of id_path_r                           index by pls_integer;
    type image_paths_t                 is table of images.image_path%type              index by pls_integer;
    type images_by_url_t               is table of images.image_id%type                index by images.image_path%type;
    type images_t                      is table of blob                                index by pls_integer;

    -- Constants
    -- ---------
    size_movies_title              constant pls_integer := 58;
    size_max_movies_title          constant pls_integer := 112;
    size_movies_original_title     constant pls_integer := 59;
    size_max_movies_original_title constant pls_integer := 113;
    size_movies_vote_count         constant pls_integer := 2;
    size_max_movies_vote_count     constant pls_integer := 4;
    size_movies_runtime            constant pls_integer := 5;
    size_max_movies_runtime        constant pls_integer := 9;
    size_movies_budget             constant pls_integer := 9;
    size_max_movies_budget         constant pls_integer := 9;
    size_movies_revenue            constant pls_integer := 10;
    size_max_movies_revenue        constant pls_integer := 10;
    size_movies_homepage           constant pls_integer := 122;
    size_max_movies_homepage       constant pls_integer := 359;
    size_movies_tagline            constant pls_integer := 172;
    size_max_movies_tagline        constant pls_integer := 871;
    size_actors_name               constant pls_integer := 22;
    size_max_actors_name           constant pls_integer := 40;
    size_characters_name           constant pls_integer := 35;
    size_max_characters_name       constant pls_integer := 111;
    size_prod_countries_name       constant pls_integer := 31;
    size_max_prod_countries_name   constant pls_integer := 38;
    size_prod_companies_name       constant pls_integer := 45;
    size_max_prod_companies_name   constant pls_integer := 91;
    size_spoken_languages_name     constant pls_integer := 15;
    size_max_spoken_languages_name constant pls_integer := 16;
    size_directors_id              constant pls_integer := 7;
    size_max_directors_id          constant pls_integer := 7;
    size_directors_name            constant pls_integer := 23;
    size_max_directors_name        constant pls_integer := 35;
    size_statuses_name             constant pls_integer := 8;
    size_max_statuses_name         constant pls_integer := 15;
    size_certifications_name       constant pls_integer := 5;
    size_max_certifications_name   constant pls_integer := 9;

    split_regex   constant varchar2(20) := '(.*?)(\,{2}|$)';
    split_request constant varchar2(2000) := q'[with split(splitted, field, idx) as (
        select
            substr(
                value,
                1,
                case instr(value, '||')
                    when 0 then length(value)
                    else instr(value, '||') - 1
                end
            ),
            value,
            case instr(value, '||')
                when 0 then length(value)
                else instr(value, '||') + 2
            end
        from (
            select substr(value, 3, length(value) - 4) value from (
                select :value value from dual
            )
        )
        union all
        select
            substr(
                field,
                idx,
                case instr(field, '||', idx)
                    when 0 then length(field) + 1
                    else instr(field, '||', idx)
                end - idx
            ),
            field,
            case instr(field, '||', idx)
                when 0 then length(field)
                else instr(field, '||', idx) + 2
            end
        from split
        where idx < length(field)
    ) select distinct splitted from split]';

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

        cb_pull.pull_movies@link.cc;
        cb_pull.pull_copies@link.cc;
        commit;
    exception
        when others then
            rollback;
            dbms_output.put_line(sqlerrm);
            dbms_output.put_line(dbms_utility.format_call_stack);
            dbms_output.put_line(dbms_utility.format_error_backtrace);
            raise;
    end;

    procedure insert_movie(
        p_movie in movies_ext%rowtype)
    is
        dml_exception exception;
        pragma exception_init(dml_exception, -24381);

        raw_data movies_ext%rowtype;

        y varchar2(1000);

        i pls_integer := 0;
        j pls_integer := 0;

        chars1_v varchar2_t;

        actors_v                      people_t;
        spoken_languages_v            spoken_languages_t;
        production_countries_v        production_countries_t;
        production_companies_v        production_companies_t;
        directors_v                   people_t;
        genres_v                      genres_t;
        characters_v                  characters_t;
        certification_rec             certifications%rowtype;
        status_rec                    statuses%rowtype;
        movie_rec                     movies%rowtype;
        movies_spoken_languages_v     movies_spoken_languages_t;
        movies_production_countries_v movies_production_countries_t;
        movies_production_companies_v movies_production_companies_t;
        movies_directors_v            movies_directors_t;
        movies_genres_v               movies_genres_t;
        director_images_v             image_paths_t;
        actor_images_v                image_paths_t;
        images_by_url_v               images_by_url_t;
        image_ids_v                   image_ids_t;
        exist number(4, 0);
    begin
        begin
            select movie_copies into exist
            from movies where movie_id = p_movie.id;
        exception
            when no_data_found then
                exist := 0;
        end;

        if exist <> 0 then
            logging.i('Update of movie n°' || raw_data.id || ' number of copies starting.');
            j := round(abs(sys.dbms_random.normal * 2) + 5);
            update movies set
                movie_copies = movie_copies + j
            where movie_id = p_movie.id;

            for i in exist+1..exist+1+j loop
                insert into copies values (p_movie.id, i, 0);
            end loop;

            cc_alim.send_copies(movie_rec.movie_id);

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

                j := 1;
                y := regexp_substr(chars1_v(i), split_regex, 1, j);
                while length(y) <> 0 loop
                    y := trim(both ',' from y);
                    case j
                        when 1 then
                            actors_v(i).person_id := y;
                            characters_v(i).person_id := y;
                        when 2 then
                            utils.check_size(y, size_actors_name, size_max_actors_name);
                            actors_v(i).person_name := y;
                        when 3 then
                            characters_v(i).character_id := y;
                        when 4 then
                            utils.check_size(y, size_characters_name, size_max_characters_name);
                            characters_v(i).character_name := y;
                        when 5 then
                            actor_images_v(i) := y;
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
                            director_images_v(i) := y;
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

        -- INSERTS
        if raw_data.poster_path is not null then
            begin
                insert into images(image_path, image) values (
                    raw_data.poster_path,
                    httpuritype('http://image.tmdb.org/t/p/w185' || raw_data.poster_path).getblob()
                ) returning image_id into movie_rec.movie_poster_id;
            exception
                when dup_val_on_index then
                    select image_id into movie_rec.movie_poster_id from images
                    where image_path = raw_data.poster_path;
                when others then
                    logging.e('Failed to insert "' || raw_data.poster_path || '": ' || utl_http.get_detailed_sqlerrm);
                    raise;
            end;
        end if;


        if raw_data.status is not null then
            begin
                utils.check_size(raw_data.status, size_statuses_name, size_max_statuses_name);
                insert into statuses(status_name) values (initcap(raw_data.status))
                returning status_id into movie_rec.movie_status_id;
            exception
                when dup_val_on_index then
                    logging.i('Status ' || raw_data.status || ' already present');
                    select status_id into movie_rec.movie_status_id
                    from statuses where initcap(status_name) = initcap(raw_data.status);
            end;
        else
            movie_rec.movie_status_id := null;
        end if;

        if raw_data.certification is not null then
            begin
                utils.check_size(raw_data.certification, size_certifications_name, size_max_certifications_name);
                insert into certifications(certification_name) values (initcap(raw_data.certification))
                returning certification_id into movie_rec.movie_certification_id;
            exception
                when dup_val_on_index then
                    logging.i('Certification ' || raw_data.certification || ' already present');
                    select certification_id into movie_rec.movie_certification_id
                    from certifications where initcap(certification_name) = initcap(raw_data.certification);
            end;
        else
            movie_rec.movie_certification_id := null;
        end if;

        movie_rec.backup_flag := 0;
        insert into movies values movie_rec;

        -- Insert copies

        for i in 1..movie_rec.movie_copies loop
            insert into copies values (movie_rec.movie_id, i, 0);
        end loop;

        -- Insert director images
        begin
            forall i in indices of director_images_v save exceptions
                insert into images(image_path, image) values (
                    director_images_v(i),
                    httpuritype('http://image.tmdb.org/t/p/w185' || director_images_v(i)).getblob()
                ) returning image_id, image_path bulk collect into image_ids_v;
        exception
            when dml_exception then
                if exceptions_contains_not(1) then
                    logging.e('Error fetching http://image.tmdb.org/t/p/w185' || director_images_v(i));
                    raise;
                end if;
        end;

        -- Store path -> id mappings of inserted images
        if image_ids_v.count <> 0 then
            for i in image_ids_v.first..image_ids_v.last loop
                images_by_url_v(image_ids_v(i).path) := image_ids_v(i).id;
            end loop;
        end if;

        image_ids_v.delete;
        -- Insert actor images
        begin
            forall i in indices of actor_images_v save exceptions
                insert into images(image_path, image) values (
                    actor_images_v(i),
                    httpuritype('http://image.tmdb.org/t/p/w185' || actor_images_v(i)).getblob()
                ) returning image_id, image_path bulk collect into image_ids_v;
        exception
            when dml_exception then
                if exceptions_contains_not(1) then
                    logging.e('Error fetching http://image.tmdb.org/t/p/w185' || actor_images_v(i));
                    raise;
                end if;
        end;

        -- Store path -> id mappings of inserted images
        if image_ids_v.count <> 0 then
            for i in image_ids_v.first..image_ids_v.last loop
                images_by_url_v(image_ids_v(i).path) := image_ids_v(i).id;
            end loop;
        end if;

        -- Insert image ids into actors
        if actors_v.count <> 0 then
            for i in actors_v.first..actors_v.last loop
                if not actor_images_v.exists(i) then
                    actors_v(i).person_profile_id := null;
                elsif images_by_url_v.exists(actor_images_v(i)) then
                    actors_v(i).person_profile_id := images_by_url_v(actor_images_v(i));
                else
                    select image_id into actors_v(i).person_profile_id
                    from images where image_path = actor_images_v(i);
                end if;
            end loop;
        end if;

        -- Actually insert actors
        begin
            forall i in indices of actors_v save exceptions
                insert into people values actors_v(i);
        exception
            when dml_exception then
                if exceptions_contains_not(1) then
                    raise;
                end if;
        end;

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
                            update production_countries
                            set production_country_name = production_countries_v(i).production_country_name
                            where production_country_id = production_countries_v(i).production_country_id;
                        end if;
                end;
            end loop;
        end if;

        begin
            forall i in indices of production_companies_v save exceptions
                insert into production_companies values production_companies_v(i);
        exception
            when dml_exception then
                if exceptions_contains_not(1) then
                    raise;
                end if;
        end;

        -- Insert image ids into directors
        if directors_v.count <> 0 then
            for i in directors_v.first..directors_v.last loop
                if not director_images_v.exists(i) then
                    directors_v(i).person_profile_id := null;
                elsif images_by_url_v.exists(director_images_v(i)) then
                    directors_v(i).person_profile_id := images_by_url_v(director_images_v(i));
                else
                    select image_id into directors_v(i).person_profile_id
                    from images where image_path = director_images_v(i);
                end if;
            end loop;
        end if;


        -- Actually insert the directors
        begin
            forall i in indices of directors_v save exceptions
                insert into people values directors_v(i);
        exception
            when dml_exception then
                if exceptions_contains_not(1) then
                    raise;
                end if;
        end;

        begin
            forall i in indices of genres_v save exceptions
                insert into genres values genres_v(i);
        exception
            when dml_exception then
                if exceptions_contains_not(1) then
                    raise;
                end if;
        end;

        begin
            forall i in indices of characters_v save exceptions
                insert into characters values characters_v(i);
        exception
            when dml_exception then
                if exceptions_contains_not(1) then
                    raise;
                end if;
        end;

        forall i in indices of movies_spoken_languages_v
            insert into movies_spoken_languages values movies_spoken_languages_v(i);

        forall i in indices of movies_production_companies_v
            insert into movies_production_companies values movies_production_companies_v(i);

        forall i in indices of movies_production_countries_v
            insert into movies_production_countries values movies_production_countries_v(i);

        forall i in indices of movies_directors_v
            insert into movies_directors values movies_directors_v(i);

        forall i in indices of movies_genres_v
            insert into movies_genres values movies_genres_v(i);

        cc_alim.send_copies(movie_rec.movie_id);

        commit;
        logging.i('Succesful insertion of movie n°' || raw_data.id);
    exception
        when others then
            logging.e('Error during the inserting of movie n°' || p_movie.id || ': ' || sqlerrm);
            dbms_output.put_line(sqlerrm);
            dbms_output.put_line(dbms_utility.format_call_stack);
            -- Note: vvv This is the usefull one, it points to the line the error happened at.
            dbms_output.put_line(dbms_utility.format_error_backtrace);
            rollback;
    end;


    function exceptions_contains_not(
        p_error pls_integer) return boolean
    is
    begin
        for i in 1..sql%bulk_exceptions.count loop
            if sql%bulk_exceptions(i).error_code <> p_error then
                return true;
            end if;
        end loop;
        return false;
    end;

end movie_alim;
/
