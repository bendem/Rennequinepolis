create or replace package search is

    type cur is ref cursor;

    function search(
        p_actors    varchar2_t              default null,
        p_title     movies.movie_title%type default null,
        p_directors varchar2_t              default null,
        p_before    number                  default null,
        p_after     number                  default null,
        p_during    number                  default null) return cur;

    function search(
        p_id movies.movie_id%type) return sys_refcursor;

    function get_actors(
        p_id movies.movie_id%type) return sys_refcursor;

    function get_directors(
        p_id movies.movie_id%type) return sys_refcursor;

    function get_reviews(
        p_id movies.movie_id%type,
        p_page pls_integer) return sys_refcursor;

    function get_languages(
        p_id movies.movie_id%type) return sys_refcursor;

end search;
/
