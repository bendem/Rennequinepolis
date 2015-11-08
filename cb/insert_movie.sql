create or replace procedure insert_movie(
    v_movie in movies_ext%rowtype)
is
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

    raw_data movies_ext%rowtype;

    y varchar2(1000);

    i pls_integer := 0;
    j pls_integer := 0;

    chars1_v varchar2_t;

    type actors_t                      is table of actors%rowtype index by pls_integer;
    type spoken_languages_t            is table of spoken_languages%rowtype index by pls_integer;
    type production_countries_t        is table of production_countries%rowtype index by pls_integer;
    type production_companies_t        is table of production_companies%rowtype index by pls_integer;
    type directors_t                   is table of directors%rowtype index by pls_integer;
    type genres_t                      is table of genres%rowtype index by pls_integer;
    type characters_t                  is table of characters%rowtype index by pls_integer;
    type movies_actors_characters_t    is table of movies_actors_characters%rowtype index by pls_integer;
    type movies_spoken_languages_t     is table of movies_spoken_languages%rowtype index by pls_integer;
    type movies_production_countries_t is table of movies_production_countries%rowtype index by pls_integer;
    type movies_production_companies_t is table of movies_production_companies%rowtype index by pls_integer;
    type movies_directors_t            is table of movies_directors%rowtype index by pls_integer;
    type movies_genres_t               is table of movies_genres%rowtype index by pls_integer;
    actors_v                      actors_t;
    spoken_languages_v            spoken_languages_t;
    production_countries_v        production_countries_t;
    production_companies_v        production_companies_t;
    directors_v                   directors_t;
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

    size_movies_title              constant pls_integer := 58;
    size_max_movies_title          constant pls_integer := 112;
    size_movies_original_title     constant pls_integer := 59;
    size_max_movies_original_title constant pls_integer := 113;
    size_movies_vote_count         constant pls_integer := 2;
    size_max_movies_vote_count     constant pls_integer := 4;
    size_movies_runtime            constant pls_integer := 5;
    size_max_movies_runtime        constant pls_integer := 9;
    size_movies_budget             constant pls_integer := 8;
    size_max_movies_budget         constant pls_integer := 9;
    size_movies_revenue            constant pls_integer := 8;
    size_max_movies_revenue        constant pls_integer := 9;
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
    exist number(1, 0);
begin
    begin
        select 1 into exist
        from movies where movie_id = v_movie.id;
    exception
        when no_data_found then
            exist := 0;
    end;

    if exist = 1 then
        logging.i('Update of movie n°' || raw_data.id || ' number of copies starting.');
        update movies set
            movie_copies = movie_copies + round(abs(sys.dbms_random.normal * 2) + 5)
        where movie_id = v_movie.id;
        commit;
        logging.i('Update of movie n°' || raw_data.id || ' number of copies done.');
        return;
    end if;


    raw_data := v_movie;
    logging.i('Start insertion of movie n°' || raw_data.id);
    -- Actors / Characters
    if raw_data.actors <> '[[]]' then
        execute immediate split_request bulk collect into chars1_v using raw_data.actors;

        for i in chars1_v.first..chars1_v.last loop
            characters_v(i).movie_id := raw_data.id;
            movies_actors_characters_v(i).movie_id := raw_data.id;

            j := 1;
            y := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
            while length(y) <> 0 loop
                y := trim(both ',' from y);
                case j
                    when 1 then
                        actors_v(i).actor_id := y;
                        movies_actors_characters_v(i).actor_id := y;
                    when 2 then
                        utils.check_size(y, size_actors_name, size_max_actors_name);
                        actors_v(i).actor_name := y;
                    when 3 then
                        characters_v(i).character_id := y;
                        movies_actors_characters_v(i).character_id := y;
                    when 4 then
                        utils.check_size(y, size_characters_name, size_max_characters_name);
                        characters_v(i).character_name := y;
                    when 5 then
                        actors_v(i).actor_profile_path := y;
                end case;
                j := j + 1;
                y := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
            end loop;
        end loop;
    end if;

    -- Directors
    if raw_data.directors <> '[[]]' then
        execute immediate split_request bulk collect into chars1_v using raw_data.directors;

        for i in chars1_v.first..chars1_v.last loop
            movies_directors_v(i).movie_id := raw_data.id;

            j := 1;
            y := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
            while length(y) <> 0 loop
                y := trim(both ',' from y);
                case j
                    when 1 then
                        directors_v(i).director_id := y;
                        movies_directors_v(i).director_id := y;
                    when 2 then
                        utils.check_size(y, size_directors_name, size_max_directors_name);
                        directors_v(i).director_name := y;
                    when 3 then
                        directors_v(i).director_profile_path := y;
                end case;
                j := j + 1;
                y := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
            end loop;
        end loop;
    end if;

    -- spoken_languages
    if raw_data.spoken_languages <> '[[]]' then
        execute immediate split_request bulk collect into chars1_v using raw_data.spoken_languages;

        for i in chars1_v.first..chars1_v.last loop
            movies_spoken_languages_v(i).movie_id := raw_data.id;

            j := 1;
            y := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
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
                y := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
            end loop;
        end loop;
    end if;

    -- production_companies
    if raw_data.production_companies <> '[[]]' then
        execute immediate split_request bulk collect into chars1_v using raw_data.production_companies;

        for i in chars1_v.first..chars1_v.last loop
            movies_production_companies_v(i).movie_id := raw_data.id;

            j := 1;
            y := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
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
                y := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
            end loop;
        end loop;
    end if;

    -- production_countries
    if raw_data.production_countries <> '[[]]' then
        execute immediate split_request bulk collect into chars1_v using raw_data.production_countries;

        for i in chars1_v.first..chars1_v.last loop
            movies_production_countries_v(i).movie_id := raw_data.id;

            j := 1;
            y := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
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
                y := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
            end loop;
        end loop;
    end if;

     -- genres
    if raw_data.genres <> '[[]]' then
        execute immediate split_request bulk collect into chars1_v using raw_data.genres;

        for i in chars1_v.first..chars1_v.last loop
            movies_genres_v(i).movie_id := raw_data.id;

            j := 1;
            y := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
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
                y := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
            end loop;
        end loop;
    end if;

    movie_rec.movie_id := raw_data.id;
    utils.check_size(raw_data.title, size_movies_title, size_max_movies_title);
    movie_rec.movie_title := raw_data.title;
    utils.check_size(raw_data.original_title, size_movies_original_title, size_max_movies_original_title);
    movie_rec.movie_original_title := raw_data.original_title;
    movie_rec.movie_release_date := raw_data.release_date;
    movie_rec.movie_vote_avg := raw_data.vote_average;
    utils.check_size(raw_data.vote_count, size_movies_vote_count, size_max_movies_vote_count);
    movie_rec.movie_vote_count := raw_data.vote_count;
    utils.check_size(raw_data.runtime, size_movies_runtime, size_max_movies_runtime);
    movie_rec.movie_runtime := raw_data.runtime;
    movie_rec.movie_poster_path := raw_data.poster_path;
    utils.check_size(raw_data.budget, size_movies_budget, size_max_movies_budget);
    movie_rec.movie_budget := raw_data.budget;
    utils.check_size(raw_data.revenue, size_movies_revenue, size_max_movies_revenue);
    movie_rec.movie_revenue := raw_data.revenue;
    utils.check_size(raw_data.homepage, size_movies_homepage, size_max_movies_homepage, null);
    movie_rec.movie_homepage := raw_data.homepage;
    utils.check_size(raw_data.tagline, size_movies_tagline, size_max_movies_tagline, null);
    movie_rec.movie_tagline := raw_data.tagline;
    movie_rec.movie_overview := raw_data.overview;
    movie_rec.movie_copies := round(abs(sys.dbms_random.normal * 2) + 5);

    if raw_data.status is not null then
        begin
            utils.check_size(raw_data.status, size_statuses_name, size_max_statuses_name);
            insert into statuses values (null, upper(raw_data.status));
        exception
            when dup_val_on_index then
                logging.i('Status ' || raw_data.status || ' already present');
        end;
        select status_id into movie_rec.movie_status_id from statuses where upper(status_name) = upper(raw_data.status);
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
        select certification_id into movie_rec.movie_certification_id from certifications where upper(certification_name) = upper(raw_data.certification);
    else
        movie_rec.movie_certification_id := null;
    end if;

    -- INSERTS
    if actors_v.count <> 0 then
        for i in actors_v.first .. actors_v.last loop
            begin
                insert into actors values actors_v(i);
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
                insert into directors values directors_v(i);
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
        logging.e('Error during the inserting of movie n°' || v_movie.id);
        dbms_output.put_line(sqlerrm);
        dbms_output.put_line(dbms_utility.format_call_stack);
        dbms_output.put_line(dbms_utility.format_error_backtrace);
        rollback;
end;
/
