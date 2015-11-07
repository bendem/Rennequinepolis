create or replace procedure insert_movie (v_movie in movies_ext%rowtype) is

    split_request constant varchar2(2000) := 'with split(splitted, field, idx) as (
        select
            substr(
                value,
                1,
                case instr(value, ''||'')
                    when 0 then length(value)
                    else instr(value, ''||'') - 1
                end
            ),
            value,
            case instr(value, ''||'')
                when 0 then length(value)
                else instr(value, ''||'') + 2
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
                case instr(field, ''||'', idx)
                    when 0 then length(field) + 1
                    else instr(field, ''||'', idx)
                end - idx
            ),
            field,
            case instr(field, ''||'', idx)
                when 0 then length(field)
                else instr(field, ''||'', idx) + 2
            end
        from split
        where idx < length(field)
    ) select distinct splitted from split';

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


    size_movies_title number := 58;
    size_max_movies_title number := 112;
    size_movies_original_title number := 59;
    size_max_movies_original_title number := 113;
    -- size_movies_vote_avg number := 3;
    -- size_max_movies_vote_avg number := 3;
    size_movies_vote_count number := 2;
    size_max_movies_vote_count number := 4;
    size_movies_runtime number := 5;
    size_max_movies_runtime number := 9;
    -- size_movies_poster_path number := 32;
    -- size_max_movies_poster_path number := 32;
    size_movies_budget number := 8;
    size_max_movies_budget number := 9;
    size_movies_revenue number := 8;
    size_max_movies_revenue number := 9;
    size_movies_homepage number := 122;
    size_max_movies_homepage number := 359;
    size_movies_tagline number := 172;
    size_max_movies_tagline number := 871;
    -- size_actors_id number := 7;
    -- size_max_actors_id number := 7;
    size_actors_name number := 22;
    size_max_actors_name number := 40;
    -- size_actors_profile_path number := 32;
    -- size_max_actors_profile_path number := 32;
    -- size_characters_id number := 4;
    -- size_max_characters_id number := 4;
    size_characters_name number := 35;
    size_max_characters_name number := 111;
    -- size_production_countries_id number := 2;
    -- size_max_production_countries_id number := 2;
    size_prod_countries_name number := 31;
    size_max_prod_countries_name number := 38;
    -- size_production_companies_id number := 5;
    -- size_max_production_companies_id number := 5;
    size_prod_companies_name number := 45;
    size_max_prod_companies_name number := 91;
    size_spoken_languages_name number := 15;
    size_max_spoken_languages_name number := 16;
    size_directors_id number := 7;
    size_max_directors_id number := 7;
    size_directors_name number := 23;
    size_max_directors_name number := 35;
    -- size_directors_profile_path number := 32;
    -- size_max_directors_profile_path number := 32;
    size_statuses_name number := 8;
    size_max_statuses_name number := 15;
    size_certifications_name number := 5;
    size_max_certifications_name number := 9;
    -- size_genres_id number := 5;
    -- size_max_genres_id number := 5;
    -- size_genres_name number := 16;
    -- size_max_genres_name number := 16;
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
        update movies set
            movie_copies = movie_copies + round((SYS.DBMS_RANDOM.NORMAL*2)+5)
        where movie_id = v_movie.id;
        return;
    end if;


    raw_data := v_movie;
    dbms_output.put_line('MOVIE ID = ' || raw_data.id);
    -- Actors / Characters
    if raw_data.actors <> '[[]]' then
        execute immediate split_request bulk collect into chars1_v using raw_data.actors;

        for i in chars1_v.first..chars1_v.last loop
            characters_v(i).movie_id := raw_data.id;
            movies_actors_characters_v(i).movie_id := raw_data.id;

            j := 1;
            y := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
            while length(y) <> 0 loop
                y := trim(trailing ',' from y);
                case j
                    when 1 then
                        actors_v(i).actor_id := y;
                        movies_actors_characters_v(i).actor_id := y;
                    when 2 then
                        dbms_output.put_line('DEBUG READ ACTOR name before : ' || y);
                        utils.check_size(y, size_actors_name, size_max_actors_name);
                        dbms_output.put_line('DEBUG READ ACTOR name after : ' || y);
                        actors_v(i).actor_name := y;
                    when 3 then
                        characters_v(i).character_id := y;
                        movies_actors_characters_v(i).character_id := y;
                    when 4 then
                        dbms_output.put_line('DEBUG READ CHARACTER name before : ' || y);
                        utils.check_size(y, size_characters_name, size_max_characters_name);
                        dbms_output.put_line('DEBUG READ CHARACTER name after : ' || y);
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
                y := trim(trailing ',' from y);
                case j
                    when 1 then
                        directors_v(i).director_id := y;
                        movies_directors_v(i).director_id := y;
                    when 2 then
                        dbms_output.put_line('DEBUG READ DIRECTOR name before : ' || y);
                        utils.check_size(y, size_directors_name, size_max_directors_name);
                        dbms_output.put_line('DEBUG READ DIRECTOR name after : ' || y);
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
                y := trim(trailing ',' from y);
                case j
                    when 1 then
                        spoken_languages_v(i).spoken_language_id := y;
                        movies_spoken_languages_v(i).spoken_language_id := y;
                    when 2 then
                        dbms_output.put_line('DEBUG READ SPOKEN_LANGUAGE name before : ' || y);
                        utils.check_size(y, size_spoken_languages_name , size_max_spoken_languages_name);
                        dbms_output.put_line('DEBUG READ SPOKEN_LANGUAGE name after : ' || y);
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
                y := trim(trailing ',' from y);
                case j
                    when 1 then
                        production_companies_v(i).production_company_id := y;
                        movies_production_companies_v(i).production_company_id := y;
                    when 2 then
                        dbms_output.put_line('DEBUG READ PRODUCTION_COMPANY name before : ' || y);
                        utils.check_size(y, size_prod_companies_name , size_max_prod_companies_name);
                        dbms_output.put_line('DEBUG READ PRODUCTION_COMPANY name after : ' || y);
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
                y := trim(trailing ',' from y);
                case j
                    when 1 then
                        production_countries_v(i).production_country_id := y;
                        movies_production_countries_v(i).production_country_id := y;
                    when 2 then
                        dbms_output.put_line('DEBUG READ PRODUCTION_COUNTRIES name before : ' || y);
                        utils.check_size(y, size_prod_countries_name , size_max_prod_countries_name);
                        dbms_output.put_line('DEBUG READ PRODUCTION_COUNTRIES name after : ' || y);
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
                y := trim(trailing ',' from y);
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
    utils.check_size(raw_data.title, size_movies_title , size_max_movies_title);
    movie_rec.movie_title := raw_data.title;
    utils.check_size(raw_data.original_title, size_movies_original_title , size_max_movies_original_title);
    movie_rec.movie_original_title := raw_data.original_title;
    movie_rec.movie_release_date := raw_data.release_date;
    movie_rec.movie_vote_avg := raw_data.vote_average;
    utils.check_size(raw_data.vote_count, size_movies_vote_count , size_max_movies_vote_count);
    movie_rec.movie_vote_count := raw_data.vote_count;
    utils.check_size(raw_data.runtime, size_movies_runtime , size_max_movies_runtime);
    movie_rec.movie_runtime := raw_data.runtime;
    movie_rec.movie_poster_path := raw_data.poster_path;
    utils.check_size(raw_data.budget, size_movies_budget , size_max_movies_budget);
    movie_rec.movie_budget := raw_data.budget;
    utils.check_size(raw_data.revenue, size_movies_revenue , size_max_movies_revenue);
    movie_rec.movie_revenue := raw_data.revenue;
    utils.check_size(raw_data.homepage, size_movies_homepage , size_max_movies_homepage);
    movie_rec.movie_homepage := raw_data.homepage;
    utils.check_size(raw_data.tagline, size_movies_tagline , size_max_movies_tagline);
    movie_rec.movie_tagline := raw_data.tagline;
    movie_rec.movie_overview := raw_data.overview;
    movie_rec.movie_copies := round(abs(SYS.DBMS_RANDOM.NORMAL * 2) + 5);

    if raw_data.status is not null then
        begin
            insert into statuses values (null, upper(raw_data.status));
        exception
            when dup_val_on_index then
                null;
            when others then
                raise;
        end;
    end if;

    if raw_data.certification is not null then
        begin
            insert into certifications values (null, upper(raw_data.certification));
        exception
            when dup_val_on_index then
                null;
            when others then
                raise;
        end;
    end if;

    if raw_data.status is not null then
        select status_id into movie_rec.movie_status_id from statuses where upper(status_name) = upper(raw_data.status);
    else
        movie_rec.movie_status_id := null;
    end if;

    if raw_data.certification is not null then
        select certification_id into movie_rec.movie_certification_id from certifications where upper(certification_name) = upper(raw_data.certification);
    else
        movie_rec.movie_certification_id := null;
    end if;



    -- INSERTS
    if actors_v.count <> 0 then
        for i in actors_v.first .. actors_v.last loop
            begin
                dbms_output.put_line('DEBUG actors_v(i) = ID: ' || actors_v(i).actor_id || ' name: ' || actors_v(i).actor_name);
                insert into actors values actors_v(i);
            exception
                when dup_val_on_index then
                    null;
                when others then
                    raise;
            end;
        end loop;
    end if;

    if spoken_languages_v.count <> 0 then
        for i in spoken_languages_v.first .. spoken_languages_v.last loop
            begin
            dbms_output.put_line('DEBUG spoken_languages_v(i) = ID: ' || spoken_languages_v(i).spoken_language_id || ' name: ' || spoken_languages_v(i).spoken_language_name);
                insert into spoken_languages values spoken_languages_v(i);
            exception
                when dup_val_on_index then
                    null;
                when others then
                    raise;
            end;
        end loop;
    end if;

    if production_countries_v.count <> 0 then
        for i in production_countries_v.first .. production_countries_v.last loop
            begin
                dbms_output.put_line('DEBUG production_countries_v(i) = ID: ' || production_countries_v(i).production_country_id || ' name: ' || production_countries_v(i).production_country_name);
                insert into production_countries values production_countries_v(i);
            exception
                when dup_val_on_index then
                    null;
                when others then
                    raise;
            end;
        end loop;
    end if;

    if production_companies_v.count <> 0 then
        for i in production_companies_v.first .. production_companies_v.last loop
            begin
            dbms_output.put_line('DEBUG production_companies_v(i) = ID: ' || production_companies_v(i).production_company_id || ' name: ' || production_companies_v(i).production_company_name);
                insert into production_companies values production_companies_v(i);
            exception
                when dup_val_on_index then
                    null;
                when others then
                    raise;
            end;
        end loop;
    end if;

    if directors_v.count <> 0 then
        for i in directors_v.first .. directors_v.last loop
            begin
                dbms_output.put_line('DEBUG directors_v(i) = ID: ' || directors_v(i).director_id || ' name: ' || directors_v(i).director_name);
                insert into directors values directors_v(i);
            exception
                when dup_val_on_index then
                    null;
                when others then
                    raise;
            end;
        end loop;
    end if;

    if genres_v.count <> 0 then
        for i in genres_v.first .. genres_v.last loop
            begin
                dbms_output.put_line('DEBUG genres_v(i) = ID: ' || genres_v(i).genre_id || ' name: ' || genres_v(i).genre_name);
                insert into genres values genres_v(i);
            exception
                when dup_val_on_index then
                    null;
                when others then
                    raise;
            end;
        end loop;
    end if;

    insert into movies values movie_rec;

    if characters_v.count <> 0 then
        for i in characters_v.first .. characters_v.last loop
            dbms_output.put_line('DEBUG CHARACTERS = ID: ' || characters_v(i).character_id || ' name: ' || characters_v(i).character_name);
            insert into characters values characters_v(i);
        end loop;
    end if;

    if movies_spoken_languages_v.count <> 0 then
        for i in movies_spoken_languages_v.first .. movies_spoken_languages_v.last loop
            dbms_output.put_line('DEBUG movies_spoken_languages_v(i) = ID: ' || movies_spoken_languages_v(i).spoken_language_id);
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
exception
    when others then
        dbms_output.put_line(sqlerrm);
        dbms_output.put_line(dbms_utility.format_call_stack);
        dbms_output.put_line(dbms_utility.format_error_backtrace);
        rollback;
        raise;
end;
/
