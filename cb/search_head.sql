create or replace package search is

    -- Searches movies using combinable criterias.
    -- @param p_actors the actors search criteria
    -- @param p_title the title search criteria
    -- @param p_directors the directors search criteria
    -- @param p_years a table of years
    -- @param p_years_comparisons the comparisons to use for the p_years argument
    -- @return a cursor from `movies` left joined with `images` and `statuses`
    function search(
        p_actors            varchar2_t default null,
        p_title             movies.movie_title%type default null,
        p_directors         varchar2_t default null,
        p_years             number_t   default null,
        p_years_comparisons varchar2_t default null) return sys_refcursor;

    -- Gets a movie by id.
    -- @param p_id the movie id
    -- @return a cursor from `movies` left joined with `images` and `statuses`
    function search(
        p_id movies.movie_id%type) return sys_refcursor;

    -- Gets actor information for a movie id.
    -- @param p_id the movie id
    -- @return a cursor from `people` left joined with `images`
    function get_actors(
        p_id movies.movie_id%type) return sys_refcursor;

    -- Gets director information for a movie id.
    -- @param p_id the movie id
    -- @return a cursor from `people` left joined with `images`
    function get_directors(
        p_id movies.movie_id%type) return sys_refcursor;

    -- Gets a page of 5 reviews for a movie id.
    -- @param p_id the movie id
    -- @return a cursor from `review` minus the backup_flag
    function get_reviews(
        p_id movies.movie_id%type,
        p_page pls_integer) return sys_refcursor;

    -- Gets languages information for a movie id
    -- @param p_id the movie id
    -- @return a cursor from `movies_spoken_languages` natural joined with `spoken_languages`
    function get_languages(
        p_id movies.movie_id%type) return sys_refcursor;

end search;
/
