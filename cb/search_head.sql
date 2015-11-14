create or replace package search is

    title_criteria constant varchar2(200) := q'[ lower(movie_title) like lower('%:title%') ]';

    date_criteria constant varchar2(200) := q'[ extract(year from movie_release_date) :comparator :date ]';

    actor_base_criteria constant varchar2(200) := q'[ select movie_id from movies natural join movies_actors_characters natural join people where ]';

    director_base_criteria constant varchar2(200) := q'[ select movie_id from movies natural join movies_directors natural join people where ]';

    person_part_criteria constant varchar2(200) := q'[ person_name like '%:name%' ]';



    -- function search(
    --     p_id  movies.movie_id%type)
    -- return sys_refcursor;

    function search(
        p_actors varchar2_t default null,
        p_title movies.movie_title%type default null,
        p_directors varchar2_t default null,
        p_date number default null,
        p_date_type char default null)
    return sys_refcursor;

end search;
/
