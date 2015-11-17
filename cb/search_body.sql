create or replace package body search is

    function search(
        p_actors varchar2_t,
        p_title movies.movie_title%type,
        p_directors varchar2_t,
        p_years number_t,
        p_years_comparisons varchar2_t) return sys_refcursor
    is
        v_parts varchar2_t;
        v_query varchar2(2000) := 'select * from movies left join images on (movie_poster_id = image_id) left join statuses on (movie_status_id = status_id) where 1 = 1';
        x sys_refcursor;
    begin
        -- TODO Build a worst case static sql query and short circuit the predicate
        if p_title is not null then
            v_query := v_query || ' and ' || replace(title_criteria, ':title', p_title);
        end if;

        if p_years is not null then
            for i in p_years.first..p_years.last loop
                v_query := v_query || ' and ' || replace(replace(date_criteria, ':year', p_years(i)), ':comparator', coalesce(p_years_comparisons(i), '='));
            end loop;
        end if;

        if p_actors is not null or p_directors is not null then
            v_query := v_query || ' and movie_id in (';

            if p_actors is not null then
                for i in p_actors.first..p_actors.last loop
                    v_query := v_query || actor_base_criteria;

                    v_parts := varchar2_t();
                    v_parts := utils.split(p_actors(i), ' ');

                    for j in v_parts.first..v_parts.last loop
                        v_query := v_query || ' and ' || replace(person_part_criteria, ':name', v_parts(j));
                    end loop;

                    if i <> p_actors.last then
                        v_query := v_query || ' intersect ';
                    end if;
                end loop;

                if p_directors is not null then
                    v_query := v_query || ' intersect ';
                end if;
            end if;

            if p_directors is not null then
                for i in p_directors.first..p_directors.last loop
                    v_query := v_query || director_base_criteria;

                    v_parts := varchar2_t();
                    v_parts := utils.split(p_directors(i), ' ');

                    for j in v_parts.first..v_parts.last loop
                        v_query := v_query || ' and ' || replace(person_part_criteria, ':name', v_parts(j));
                    end loop;

                    if i <> p_directors.last then
                        v_query := v_query || ' intersect ';
                    end if;
                end loop;
            end if;

            v_query := v_query || ' )';
        end if;

        dbms_output.put_line(v_query);

        open x for (v_query);
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
        where person_id in (select person_id from movies_actors_characters where movie_id = p_id);
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
