create or replace package movie_alim is

    -- Types
    -- -----
    type movies_ext_t                  is table of movies_ext%rowtype index by pls_integer;
    type persons_t                     is table of persons%rowtype index by pls_integer;
    type spoken_languages_t            is table of spoken_languages%rowtype index by pls_integer;
    type production_countries_t        is table of production_countries%rowtype index by pls_integer;
    type production_companies_t        is table of production_companies%rowtype index by pls_integer;
    type genres_t                      is table of genres%rowtype index by pls_integer;
    type characters_t                  is table of characters%rowtype index by pls_integer;
    type movies_actors_characters_t    is table of movies_actors_characters%rowtype index by pls_integer;
    type movies_spoken_languages_t     is table of movies_spoken_languages%rowtype index by pls_integer;
    type movies_production_countries_t is table of movies_production_countries%rowtype index by pls_integer;
    type movies_production_companies_t is table of movies_production_companies%rowtype index by pls_integer;
    type movies_directors_t            is table of movies_directors%rowtype index by pls_integer;
    type movies_genres_t               is table of movies_genres%rowtype index by pls_integer;
    type images_t                      is table of blob index by pls_integer;


    -- Inserts a set amount of movies from movies_ext into the main database.
    -- @param p_count the number of movies to transfer
    procedure insert_movies(
        p_count pls_integer);

    -- Inserts a movies_ext row into the main database
    -- @param p_movie the rowtype to decompose and insert
    procedure insert_movie(
        p_movie movies_ext%rowtype);


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

end movie_alim;
/
