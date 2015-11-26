create or replace package body search is

    function search(
        p_actors    varchar2_t,
        p_title     movies.movie_title%type,
        p_directors varchar2_t,
        p_before    number,
        p_after     number,
        p_during    number) return cur
    is
        actors_count    number(2, 0) := 0;
        directors_count number(2, 0) := 0;
        x cur;
    begin
        if p_actors is not null then
            actors_count := p_actors.count;
        end if;
        if p_directors is not null then
            directors_count := p_directors.count;
        end if;

        open x for
            with actor_search(person_name) as (
                select '%' || column_value || '%' from table(p_actors)
            ), director_search(person_name) as (
                select '%' || column_value || '%' from table(p_directors)
            )
            select *
            from movies
            left join images   on (movie_poster_id = image_id)
            left join statuses on (movie_status_id = status_id)
            where 1 = 1
                and (movie_title is null or lower(movie_title) like lower('%' || p_title || '%'))
                -- TODO This is not right
                and (p_actors is null or movie_id in (
                    select movie_id
                    from characters
                    natural join people
                    left join actor_search on (people.person_name like actor_search.person_name)
                    group by movie_id
                    having count(distinct actor_search.person_name) = actors_count
                ))
                and (p_directors is null or movie_id in (
                    select movie_id
                    from movies_directors
                    natural join people
                    inner join director_search on (people.person_name like director_search.person_name)
                    group by movie_id
                    having count(distinct director_search.person_name) = directors_count
                ))
                and (p_during is null or extract(year from movie_release_date) = p_during)
                and (p_before is null or extract(year from movie_release_date) < p_before)
                and (p_after  is null or extract(year from movie_release_date) > p_after)
        ;

        return x;
    end;

    function search(
        p_id movies.movie_id%type) return sys_refcursor
    is
        x sys_refcursor;
    begin
        open x for select * from movies
        left join images on (movie_poster_id = image_id)
        left join statuses on (movie_status_id = status_id)
        where movie_id = p_id;
        return x;
    end;

    function get_actors(
        p_id movies.movie_id%type) return sys_refcursor
    is
        x sys_refcursor;
    begin
        open x for select * from people
        left join images on (person_profile_id = image_id)
        where person_id in (select person_id from characters where movie_id = p_id);
        return x;
    end;

    function get_directors(
        p_id movies.movie_id%type) return sys_refcursor
    is
        x sys_refcursor;
    begin
        open x for select * from people
        left join images on (person_profile_id = image_id)
        where person_id in (select person_id from movies_directors where movie_id = p_id);
        return x;
    end;

    function get_reviews(
        p_id movies.movie_id%type,
        p_page pls_integer) return sys_refcursor
    is
        x sys_refcursor;
    begin
        open x for select * from (
            select
                username,
                rating,
                creation_date,
                content,
                row_number() over (order by username) rnum
            from reviews where movie_id = p_id
        ) where rnum between (p_page - 1) * 5 + 1 and p_page * 5;
        return x;
    end;

    function get_languages(
        p_id movies.movie_id%type) return sys_refcursor
    is
        x sys_refcursor;
    begin
        open x for select * from movies_spoken_languages natural join spoken_languages where movie_id = p_id;
        return x;
    end;

end search;
/
