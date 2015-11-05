create or replace type number_t is table of number;
create or replace type varchar2_t is table of varchar2(4000);

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

    split_request varchar2(2000);

    x varchar2(1000);
    y varchar2(1000);
    z varchar2(1000);

    i pls_integer := 0;
    j pls_integer := 0;
    k pls_integer := 0;
    l pls_integer := 0;
    m pls_integer := 0;
    indx pls_integer := 0;

    chars1_v varchar2_t;
    chars2_v varchar2_t;
    chars3_v varchar2_t;
    chars4_v varchar2_t;
    chars5_v varchar2_t;
    chars6_v varchar2_t;

    raw_data movies_ext%rowtype;

    actors_t               table of actors%rowtype index by pls_integer;
    certification_rec      certifications%rowtype;
    status_rec             statuses%rowtype;
    spoken_languages_t     table of spoken_languages%rowtype index by pls_integer;
    production_countries_t table of production_countries%rowtype index by pls_integer;
    production_companies_t table of production_companies%rowtype index by pls_integer;
    directors_t            table of directors%rowtype index by pls_integer;
    genres_t               table of genres%rowtype index by pls_integer;
    movie_rec              movies%rowtype;
    characters_t           table of characters%rowtype index by pls_integer;

    movies_spoken_languages_t     table of movies_spoken_languages%rowtype index by pls_integer;
    movies_production_countries_t table of movies_production_countries%rowtype index by pls_integer;
    movies_production_companies_t table of movies_production_companies%rowtype index by pls_integer;
    movies_directors_t            table of movies_directors%rowtype index by pls_integer;
    movies_genres_t               table of movies_genres%rowtype index by pls_integer;

begin

    select * into raw_data from movies_ext where id = movie_id;

    -- Actors / Characters
    execute immediate split_request bulk collect into chars1_v using raw_data.actors;

    chars2_v := varchar2_t();
    chars3_v := varchar2_t();
    chars4_v := varchar2_t();
    chars5_v := varchar2_t();
    chars6_v := varchar2_t();

    for i in chars1_v.first..chars1_v.last loop
        j := 1;
        y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);

        while length(y) <> 0 loop
            y := trim(trailing ',' from y);
            case j
                when 1 then
                    chars2_v.extend; -- id
                    chars2_v(chars2_v.count) := y;
                when 2 then
                    chars3_v.extend; -- act name
                    chars3_v(chars3_v.count) := y;
                when 3 then
                    chars4_v.extend; -- castid
                    chars4_v(chars4_v.count) := y;
                when 4 then
                    chars5_v.extend; -- cast char
                    chars5_v(chars5_v.count) := y;
                when 5 then
                    chars6_v.extend; -- char name
                    chars6_v(chars6_v.count) := y;
            end case;
            j := j + 1;
            y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        end loop;
    end loop;

    for i in chars2_v.first .. chars2_v.last loop
        actors_t(i).actor_id := chars2_v(i);
        actors_t(i).actor_name := chars3_v(i);
        actors_t(i).actor_profile_path := chars6_v(i);
        characters_t(i).movie_id := movie_id;
        characters_t(i).character_id := chars4_v(i);
        characters_t(i).character_name := chars5_v(i);
        movies_actors_characters_t(i).movie_id := movie_id;
        movies_actors_characters_t(i).character_id := chars4_v(i);
        movies_actors_characters_t(i).actor_id := chars2_v(i);
    end loop;

    -- Directors
    execute immediate split_request bulk collect into chars1_v using raw_data.directors;

    chars2_v := varchar2_t();
    chars3_v := varchar2_t();
    chars4_v := varchar2_t();
    for i in chars1_v.first..chars1_v.last loop
        j := 1;
        y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);

        while length(y) <> 0 loop
            y := trim(trailing ',' from y);
            case j
                when 1 then
                    chars2_v.extend; -- Director id
                    chars2_v(chars2_v.count) := y;
                when 2 then
                    chars3_v.extend; -- Director name
                    chars3_v(chars3_v.count) := y;
                when 3 then
                    chars4_v.extend; -- Director profile path
                    chars4_v(chars4_v.count) := y;
            end case;
            j := j + 1;
            y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        end loop;
    end loop;

    for i in chars2_v.first .. chars2_v.last loop
        directors_t(i).director_id := chars2_v(i);
        directors_t(i).director_name := chars3_v(i);
        directors_t(i).director_profile_path := chars4_v(i);
        movies_directors_t(i).movie_id := movie_id;
        movies_directors_t(i).director_id := chars2_v(i);
    end loop;

    -- spoken_languages
    execute immediate split_request bulk collect into chars1_v using raw_data.spoken_languages;

    chars2_v := varchar2_t();
    chars3_v := varchar2_t();
    for i in chars1_v.first..chars1_v.last loop
        j := 1;
        y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);

        while length(y) <> 0 loop
            y := trim(trailing ',' from y);
            case j
                when 1 then
                    chars2_v.extend; -- spoken_language_id
                    chars2_v(chars2_v.count) := y;
                when 2 then
                    chars3_v.extend; -- spoken_language_name
                    chars3_v(chars3_v.count) := y;
            end case;
            j := j + 1;
            y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        end loop;
    end loop;

    for i in chars2_v.first .. chars2_v.last loop
        spoken_languages_t(i).spoken_language_id := chars2_v(i);
        spoken_languages_t(i).spoken_language_name := chars3_v(i);
        movies_spoken_languages_t(i).movie_id := movie_id;
        movies_spoken_languages_t(i).spoken_language_id := chars2_v(i);
    end loop;

    -- production_companies
    execute immediate split_request bulk collect into chars1_v using raw_data.production_companies;

    chars2_v := varchar2_t();
    chars3_v := varchar2_t();
    for i in chars1_v.first..chars1_v.last loop
        j := 1;
        y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);

        while length(y) <> 0 loop
            y := trim(trailing ',' from y);
            case j
                when 1 then
                    chars2_v.extend; -- production_company_id
                    chars2_v(chars2_v.count) := y;
                when 2 then
                    chars3_v.extend; -- production_company_name
                    chars3_v(chars3_v.count) := y;
            end case;
            j := j + 1;
            y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        end loop;
    end loop;

    for i in chars2_v.first .. chars2_v.last loop
        production_companies_t(i).production_company_id := chars2_v(i);
        production_companies_t(i).production_company_name := chars3_v(i);
        movies_production_companies_t(i).movie_id := movie_id;
        movies_production_companies_t(i).production_company_id := chars2_v(i);
    end loop;

    -- production_countries
    execute immediate split_request bulk collect into chars1_v using raw_data.production_countries;

    chars2_v := varchar2_t();
    chars3_v := varchar2_t();
    for i in chars1_v.first..chars1_v.last loop
        j := 1;
        y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);

        while length(y) <> 0 loop
            y := trim(trailing ',' from y);
            case j
                when 1 then
                    chars2_v.extend; -- production_country_id
                    chars2_v(chars2_v.count) := y;
                when 2 then
                    chars3_v.extend; -- production_country_name
                    chars3_v(chars3_v.count) := y;
            end case;
            j := j + 1;
            y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        end loop;
    end loop;

    for i in chars2_v.first .. chars2_v.last loop
        production_countries_t(i).production_country_id := chars2_v(i);
        production_countries_t(i).production_country_name := chars3_v(i);
        movies_production_countries_t(i).movie_id := movie_id;
        movies_production_countries_t(i).production_country_id := chars2_v(i);
    end loop;

     -- genres
    execute immediate split_request bulk collect into chars1_v using raw_data.genres;

    chars2_v := varchar2_t();
    chars3_v := varchar2_t();
    for i in chars1_v.first..chars1_v.last loop
        j := 1;
        y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);

        while length(y) <> 0 loop
            y := trim(trailing ',' from y);
            case j
                when 1 then
                    chars2_v.extend; -- genre_id
                    chars2_v(chars2_v.count) := y;
                when 2 then
                    chars3_v.extend; -- genre_name
                    chars3_v(chars3_v.count) := y;
            end case;
            j := j + 1;
            y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        end loop;
    end loop;

    for i in chars2_v.first .. chars2_v.last loop
        genres_t(i).genre_id := chars2_v(i);
        genres_t(i).genre_name := chars3_v(i);
        movies_genres_t(i).movie_id := movie_id;
        movies_genres_t(i).genre_id := chars2_v(i);
    end loop;

    movie_rec.movie_title := raw_data.title;
    movie_rec.movie_original_title := raw_data.original_title;
    movie_rec.movie_release_date := raw_data.release_date;
    movie_rec.movie_vote_average := raw_data.vote_average;
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

    for i in actors_t.first .. actors_t.last loop
        begin
            insert into actors values actors_t(i);
        exception
            when dup_val_on_index then
                null;
            when others then
                raise;
        end;
    end loop;

    for i in spoken_languages_t.first .. spoken_languages_t.last loop
        begin
            insert into spoken_languages values spoken_languages_t(i);
        exception
            when dup_val_on_index then
                null;
            when others then
                raise;
        end;
    end loop;

    for i in production_countries_t.first .. production_countries_t.last loop
        begin
            insert into production_countries values production_countries_t(i);
        exception
            when dup_val_on_index then
                null;
            when others then
                raise;
        end;
    end loop;

    for i in production_companies_t.first .. production_companies_t.last loop
        begin
            insert into production_companies values production_companies_t(i);
        exception
            when dup_val_on_index then
                null;
            when others then
                raise;
        end;
    end loop;

    for i in directors_t.first .. directors_t.last loop
        begin
            insert into directors values directors_t(i);
        exception
            when dup_val_on_index then
                null;
            when others then
                raise;
        end;
    end loop;

    for i in genres_t.first .. genres_t.last loop
        begin
            insert into genres values genres_t(i);
        exception
            when dup_val_on_index then
                null;
            when others then
                raise;
        end;
    end loop;

    insert into movies values movie_rec;

    for i in characters_t.first .. characters_t.last loop
        insert into characters values characters_t(i);
    end loop;

    for i in movies_spoken_languages_t.first .. movies_spoken_languages_t.last loop
        insert into movies_spoken_languages values movies_spoken_languages_t(i);
    end loop;

    for i in movies_production_companies_t.first .. movies_production_companies_t.last loop
        insert into movies_production_companies values movies_production_companies_t(i);
    end loop;

    for i in movies_production_countries_t.first .. movies_production_countries_t.last loop
        insert into movies_production_countries values movies_production_countries_t(i);
    end loop;

    for i in movies_directors_t.first .. movies_directors_t.last loop
        insert into movies_directors values movies_directors_t(i);
    end loop;

    for i in movies_genres_t.first .. movies_genres_t.last loop
        insert into movies_genres values movies_genres_t(i);
    end loop;

    for i in movies_actors_characters_t.first .. movies_actors_characters_t.last loop
        insert into movies_actors_characters values movies_actors_characters_t(i);
    end loop;

exception
    when others then
        dbms_output.put_line(sqlerrm);
        dbms_output.put_line(dbms_utility.format_call_stack);
        dbms_output.put_line(dbms_utility.format_error_backtrace);
        raise;
end;
/
