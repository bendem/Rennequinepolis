create or replace package search is

    function search(
        p_actors varchar2_t default null,
        p_title movies.movie_title%type default null,
        p_directors varchar2_t default null,
        p_year number default null,
        p_year_comparison varchar2 default null) return sys_refcursor;

    function search(
        p_id movies.movie_id%type) return sys_refcursor;

    function getActors(
        p_id movies.movie_id%type) return sys_refcursor;

    function getDirectors(
        p_id movies.movie_id%type) return sys_refcursor;

    function getReviews(
        p_id movies.movie_id%type) return sys_refcursor;

    title_criteria constant varchar2(200) := q'[lower(movie_title) like lower('%:title%')]';
    date_criteria constant varchar2(200) := q'[extract(year from movie_release_date) :comparator :year]';
    actor_base_criteria constant varchar2(200) := q'[select movie_id from movies natural join movies_actors_characters natural join people where 1 = 1]';
    director_base_criteria constant varchar2(200) := q'[select movie_id from movies natural join movies_directors natural join people where 1 = 1]';
    person_part_criteria constant varchar2(200) := q'[person_name like '%:name%']';

end search;
/
