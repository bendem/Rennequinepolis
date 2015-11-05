create or replace type number_t is table of number;
/
create or replace type varchar2_t is table of varchar2(4000);
/

create or replace procedure insert_movie (movie_id in movies.movie_id%type) is

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

    y varchar2(1000);

    i pls_integer := 0;
    j pls_integer := 0;

    chars1_v varchar2_t;

    raw_data movies_ext%rowtype;

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

begin
    select * into raw_data from movies_ext where id = movie_id;

    -- Actors / Characters
    execute immediate split_request bulk collect into chars1_v using raw_data.actors;

    for i in chars1_v.first..chars1_v.last loop
        characters_v(i).movie_id := movie_id;
        movies_actors_characters_v(i).movie_id := movie_id;

        j := 1;
        y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        while length(y) <> 0 loop
            y := trim(trailing ',' from y);
            case j
                when 1 then
                    actors_v(i).actor_id := y;
                    movies_actors_characters_v(i).actor_id := y;
                when 2 then
                    actors_v(i).actor_name := y;
                when 3 then
                    characters_v(i).character_id := y;
                    movies_actors_characters_v(i).character_id := y;
                when 4 then
                    characters_v(i).character_name := y;
                when 5 then
                    actors_v(i).actor_profile_path := y;
            end case;
            j := j + 1;
            y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        end loop;
    end loop;

    -- Directors
    execute immediate split_request bulk collect into chars1_v using raw_data.directors;

    for i in chars1_v.first..chars1_v.last loop
        movies_directors_v(i).movie_id := movie_id;

        j := 1;
        y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        while length(y) <> 0 loop
            y := trim(trailing ',' from y);
            case j
                when 1 then
                    directors_v(i).director_id := y;
                    movies_directors_v(i).director_id := y;
                when 2 then
                    directors_v(i).director_name := y;
                when 3 then
                    directors_v(i).director_profile_path := y;
            end case;
            j := j + 1;
            y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        end loop;
    end loop;

    -- spoken_languages
    execute immediate split_request bulk collect into chars1_v using raw_data.spoken_languages;

    for i in chars1_v.first..chars1_v.last loop
        movies_spoken_languages_v(i).movie_id := movie_id;

        j := 1;
        y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        while length(y) <> 0 loop
            y := trim(trailing ',' from y);
            case j
                when 1 then
                    spoken_languages_v(i).spoken_language_id := y;
                    movies_spoken_languages_v(i).spoken_language_id := y;
                when 2 then
                    spoken_languages_v(i).spoken_language_name := y;
            end case;
            j := j + 1;
            y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        end loop;
    end loop;

    -- production_companies
    execute immediate split_request bulk collect into chars1_v using raw_data.production_companies;

    for i in chars1_v.first..chars1_v.last loop
        movies_production_companies_v(i).movie_id := movie_id;

        j := 1;
        y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        while length(y) <> 0 loop
            y := trim(trailing ',' from y);
            case j
                when 1 then
                    production_companies_v(i).production_company_id := y;
                    movies_production_companies_v(i).production_company_id := y;
                when 2 then
                    production_companies_v(i).production_company_name := y;
            end case;
            j := j + 1;
            y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        end loop;
    end loop;

    -- production_countries
    execute immediate split_request bulk collect into chars1_v using raw_data.production_countries;

    for i in chars1_v.first..chars1_v.last loop
        movies_production_countries_v(i).movie_id := movie_id;

        j := 1;
        y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        while length(y) <> 0 loop
            y := trim(trailing ',' from y);
            case j
                when 1 then
                    production_countries_v(i).production_country_id := y;
                    movies_production_countries_v(i).production_country_id := y;
                when 2 then
                    production_countries_v(i).production_country_name := y;
            end case;
            j := j + 1;
            y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        end loop;
    end loop;

     -- genres
    execute immediate split_request bulk collect into chars1_v using raw_data.genres;

    for i in chars1_v.first..chars1_v.last loop
        movies_genres_v(i).movie_id := movie_id;

        j := 1;
        y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
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
            y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        end loop;
    end loop;

    movie_rec.movie_id := movie_id;
    movie_rec.movie_title := raw_data.title;
    movie_rec.movie_original_title := raw_data.original_title;
    movie_rec.movie_release_date := raw_data.release_date;
    movie_rec.movie_vote_avg := raw_data.vote_average;
    movie_rec.movie_vote_count := raw_data.vote_count;
    movie_rec.movie_runtime := raw_data.runtime;
    movie_rec.movie_poster_path := raw_data.poster_path;
    movie_rec.movie_budget := raw_data.budget;
    movie_rec.movie_revenue := raw_data.revenue;
    movie_rec.movie_homepage := raw_data.homepage;
    movie_rec.movie_tagline := raw_data.tagline;
    movie_rec.movie_overview := raw_data.overview;

    begin
        insert into statuses values (null, upper(raw_data.status));
        insert into certifications values (null, upper(raw_data.certification));
    exception
        when dup_val_on_index then
            null;
        when others then
            raise;
    end;

    select status_id into movie_rec.movie_status_id from statuses where upper(status_name) = upper(raw_data.status);
    select certification_id into movie_rec.movie_certification_id from certifications where upper(certification_name) = upper(raw_data.certification);


    -- INSERTS

    for i in actors_v.first .. actors_v.last loop
        begin
            insert into actors values actors_v(i);
        exception
            when dup_val_on_index then
                null;
            when others then
                raise;
        end;
    end loop;

    for i in spoken_languages_v.first .. spoken_languages_v.last loop
        begin
            insert into spoken_languages values spoken_languages_v(i);
        exception
            when dup_val_on_index then
                null;
            when others then
                raise;
        end;
    end loop;

    for i in production_countries_v.first .. production_countries_v.last loop
        begin
            insert into production_countries values production_countries_v(i);
        exception
            when dup_val_on_index then
                null;
            when others then
                raise;
        end;
    end loop;

    for i in production_companies_v.first .. production_companies_v.last loop
        begin
            insert into production_companies values production_companies_v(i);
        exception
            when dup_val_on_index then
                null;
            when others then
                raise;
        end;
    end loop;

    for i in directors_v.first .. directors_v.last loop
        begin
            insert into directors values directors_v(i);
        exception
            when dup_val_on_index then
                null;
            when others then
                raise;
        end;
    end loop;

    for i in genres_v.first .. genres_v.last loop
        begin
            insert into genres values genres_v(i);
        exception
            when dup_val_on_index then
                null;
            when others then
                raise;
        end;
    end loop;

    insert into movies values movie_rec;

    for i in characters_v.first .. characters_v.last loop
        insert into characters values characters_v(i);
    end loop;

    for i in movies_spoken_languages_v.first .. movies_spoken_languages_v.last loop
        insert into movies_spoken_languages values movies_spoken_languages_v(i);
    end loop;

    for i in movies_production_companies_v.first .. movies_production_companies_v.last loop
        insert into movies_production_companies values movies_production_companies_v(i);
    end loop;

    for i in movies_production_countries_v.first .. movies_production_countries_v.last loop
        insert into movies_production_countries values movies_production_countries_v(i);
    end loop;

    for i in movies_directors_v.first .. movies_directors_v.last loop
        insert into movies_directors values movies_directors_v(i);
    end loop;

    for i in movies_genres_v.first .. movies_genres_v.last loop
        insert into movies_genres values movies_genres_v(i);
    end loop;

    for i in movies_actors_characters_v.first .. movies_actors_characters_v.last loop
        insert into movies_actors_characters values movies_actors_characters_v(i);
    end loop;

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
