
execute scheduling.read_file;

delete from schedules;

select to_timestamp(current_date) + interval '20' hour + interval '30' minute from dual;

insert into schedules
    select xmlelement(
        "schedule",
        xmlforest(
            3 "copy_id",
            2 "movie_id",
            xmlforest(
                current_timestamp - interval '1' day "schedule_start",
                1 "hall_id"
            ) "time_schedule"
        )
    ) from dual;
commit;

select
    extractvalue(object_value, '/copy/copy_id'),
    extractvalue(object_value, '/copy/movie_id')
from copies;



with schedules_(copy_id, movie_id, schedule_start) as (
    select
        extractvalue(s.object_value, '/schedule/copy_id'),
        extractvalue(s.object_value, '/schedule/movie_id'),
        to_timestamp_tz(extractvalue(t.object_value, '/time_schedule/schedule_start'))
    from
        schedules s,
        xmltable('/schedule/time_schedule' passing s.object_value) t
)
select
    *
from schedules_
where
    schedule_start < trunc(current_timestamp)
    and schedule_start > trunc(current_timestamp) - interval '1' day
;

execute archive.archive;
delete from archives;
select
    extractvalue(object_value, '/archive/movie_id'),
    extractvalue(object_value, '/archive/running_days'),
    extractvalue(object_value, '/archive/places_sold')
from archives;





-- ------------
-- YAY XML \o/
select * from cc_queue@link.cb;
insert into movies select * from cc_queue@link.cb;
commit;

select extract(object_value, '/movie/original_title/text()').getStringVal() from movies;

update movies set object_value = updatexml(object_value, '/movie/original_title/text()', 'Aaaaaariel')
   where extractvalue(object_value, '/movie/original_title') = 'Ariel';

update movies set object_value = appendchildxml(object_value, '/movie', xmltype('<copy><id>3</id></copy>'));
update movies set object_value = insertchildxml(
    object_value,
    '/movie',
    'copy',
    xmltype('<copy><id>1</id></copy>')
)
--where extractvalue(object_value, '/movie/original_title') = 'Ariel'
;


with schedules_(meta, sched) as (
    select s.object_value, t.object_value
    from
        schedules s,
        xmltable('/schedule/time_schedule' passing s.object_value) t
)
select
    extractvalue(meta, '/schedule/copy_id'),
    extractvalue(meta, '/schedule/movie_id'),
    to_timestamp_tz(extractvalue(sched, '/time_schedule/schedule_start'))
from schedules_;


--  THE ONE
select
    extractvalue(object_value, '/schedule/copy_id') "copy_id"
from
    schedules s
where not exists(
    select * from
        schedules s2,
        xmltable('/schedule/time_schedule/schedule_start' passing s.object_value) t
    where
        to_timestamp_tz(extractvalue(t.column_value, 'schedule_start'), 'YYYY-MM-DD"T"HH24:MI:SS.FFTZH:TZM') + (
            select
                numtodsinterval(extractvalue(m.object_value, '/movie/runtime'), 'minute')
            from movies m
            where
                extractvalue(m.object_value, '/movie/id') = extractvalue(s.object_value, '/schedule/movie_id')
        ) + numtodsinterval(30, 'minute') > current_timestamp
        and extractvalue(s.object_value,'/schedule/movie_id') = extractvalue(s2.object_value,'/schedule/movie_id')
        and extractvalue(s.object_value,'/schedule/copy_id') = extractvalue(s2.object_value,'/schedule/copy_id')
)
;



insert into schedules
    select xmlelement(
        "schedule",
        xmlforest(
            1 "copy_id",
            2 "movie_id",
            xmlforest(
                current_timestamp "schedule_start",
                1 "hall_id"
            ) "time_schedule"
        )
    ) from dual;
commit;


select extract(object_value, '/movie/copy').getClobVal() from movies;
select * from movies;



declare
    x sys_refcursor;
    r movies%rowtype;
    c number;
begin
    x := search.search(
        p_actors => varchar2_t('Tamasaburo Bando', 'Ai Yasunaga'),
        p_directors => varchar2_t('Akio Jissoji'),
        p_title => 'a',
        p_year => 1987,
        p_year_comparison => '>='
    );
    loop
        fetch x into r;
        exit when x%notfound;
        dbms_output.put_line(lpad(r.movie_id, 5) || ' | ' || r.movie_title || ': ' || r.movie_release_date);
    end loop;
    close x;
end;
/

select sid, serial#, username, osuser from v$session where username <> 'oracle';
alter system disconnect session '65,253' immediate;
alter user cb account lock;

declare
    type t is table of movies_ext%rowtype;
    r t;
begin
    select * bulk collect into r from movies_ext where rownum < 10;
    for i in r.first..r.last loop
        movie_alim.insert_movie(r(i));
    end loop;
    -- execute backup.propagate_changes;
end;
/


select sum(s) from (
    select regexp_count(actors, '\|\|') + 1 s
    from movies_ext
    where
        actors is not null
        and actors <> '[[]]'
);
-- => 1059560

--select * from movies_ext;
select count(*) from movies_ext;

select actors from movies_ext where rownum < 3;

select count(*) from movies_ext where dbms_lob.substr(actors, 1, 10) <> '[[]]';

select * from table(str_split_c('aa,,bb', ',,'));

create or replace package refcur_pkg is
  type bleh is record(val varchar2(4000));
  type bleh_t is table of bleh;
  type refcur_t is ref cursor return bleh;
end refcur_pkg;
/

create or replace type number_t is table of number(10);
/

declare
    genre_id_v number_t := number_t();
    genre_name_v varchar2_t := varchar2_t();
    parts_v varchar2_t;

    median_v number;
    stddev_v number;
    max_v number;
    min_v number;
    avg_v number;
begin
    for x in (select str_split(substr(genres, 3, length(genres) - 4), '||') as x from movies_ext where genres <> '[[]]') loop
        for y in 1..x.x.count loop
            parts_v := str_split(x.x(y), ',,');
            genre_id_v.extend;
            genre_name_v.extend;
            genre_id_v(genre_id_v.count) := parts_v(1);
            genre_name_v(genre_name_v.count) := parts_v(2);
        end loop;
    end loop;

    select
        median(length(column_value)),
        stddev(length(column_value)),
        max(length(column_value)),
        min(length(column_value)),
        avg(length(column_value))
    into median_v, stddev_v, max_v, min_v, avg_v
    from table(genre_name_v);

    dbms_output.put_line('median: ' || median_v);
    dbms_output.put_line('stddev: ' || stddev_v);
    dbms_output.put_line('max: ' || max_v);
    dbms_output.put_line('min: ' || min_v);
    dbms_output.put_line('avg: ' || avg_v);
end;
/


create or replace type varchar2_t_t is table of varchar2_t;

create or replace function str_split(
    p_str varchar2,
    p_delim varchar2
) return varchar2_t
is
    res_v varchar2_t := varchar2_t();

    pos_v pls_integer;
    prev_pos_v pls_integer := 1;
begin
    if p_str = '' then
        return res_v;
    end if;

    pos_v := instr(p_str, p_delim, 1, 1);
    while pos_v <> 0 loop
        res_v.extend;
        res_v(res_v.count) := substr(p_str, prev_pos_v, pos_v - prev_pos_v);
        prev_pos_v := pos_v + length(p_delim);
        pos_v := instr(p_str, p_delim, prev_pos_v, 1);
    end loop;
    res_v.extend;
    res_v(res_v.count) := substr(p_str, prev_pos_v);
    return res_v;
end;
/

create or replace function str_split_more(
    p_str varchar2_t,
    p_delim varchar2
) return varchar2_t_t
is
    res_v varchar2_t_t := varchar2_t_t();
begin
    for i in 1..p_str.count loop
        res_v.extend;
        res_v(res_v.count) := str_split(p_str(i), p_delim);
    end loop;
    return res_v;
end;
/


--select count(*) from (
select
  --actors,
  regexp_substr(actors, '[^,]+', 3, 1) actor_id,
  regexp_substr(actors, '[^,]+', 3, 2) actor_name
from movies_ext
where dbms_lob.substr(trim(actors), 1, 10) <> '[[]]'
--and rownum < 10
;

select trim(regexp_substr(genres, '[^,]+', 1, column_value))
from (
    select distinct
        trim(regexp_substr(genres, '[^|]+', 1, column_value)) as genres
    from (
        select substr(genres, 3, length(genres) - 4) as genres from movies_ext
    ), table(cast(multiset(
        select level from dual connect by instr(genres, '||', 1, level - 1) > 0
    ) as sys.odciNumberList))
    where genres <> '[[]]'
), table(cast(multiset(
    select level from dual connect by instr(genres, ',,', 1, level - 1) > 0
) as sys.odciNumberList))



select distinct
    trim(regexp_substr(genres, '[^|]+', 1, column_value)) as genres
from (
    select substr(genres, 3, length(genres) - 4) as genres from movies_ext
), table(cast(multiset(
    select level from dual connect by instr(genres, '||', 1, level - 1) > 0
) as sys.odciNumberList))
where genres <> '[[]]'



select
    -- *
    count(*) count,
    median(length(actor_id)) actor_id_median,
    stddev(length(actor_id)) actor_id_stddev,
    max(length(actor_id)) actor_id_max,
    min(length(actor_id)) actor_id_min,
    avg(length(actor_id)) actor_id_avg,
    percentile_cont(0.99) within group (order by length(actor_id)) actor_id_percentile_cont,
    percentile_cont(0.9999) within group (order by length(actor_id)) actor_id_percentile_cont,
    median(length(actor_name)) actor_name_median,
    stddev(length(actor_name)) actor_name_stddev,
    max(length(actor_name)) actor_name_max,
    min(length(actor_name)) actor_name_min,
    avg(length(actor_name)) actor_name_avg,
    percentile_cont(0.99) within group (order by length(actor_name)) actor_name_percentile_cont,
    percentile_cont(0.9999) within group (order by length(actor_name)) actor_name_percentile_cont
from (
    select distinct
        -- actor_id
        to_number(actor_id) actor_id,
        trim(actor_name) actor_name
    from (
        select
            regexp_substr(actors, '[^0,][^,]+', 3, 1) actor_id,
            regexp_substr(actors, '[^,]+', 3, 2) actor_name
        from (
            select distinct
                trim(regexp_substr(actors, '[^|]+', 1, column_value)) as actors
            from (
                select dbms_lob.substr(actors, least(1000, length(actors) - 4), 3) as actors from movies_ext
            ), table(cast(multiset(
                select level from dual connect by dbms_lob.instr(actors, '||', 1, level - 1) > 0
            ) as sys.odciNumberList))
            where dbms_lob.substr(trim(actors), 10, 1) <> '[[]]'
        )
        where dbms_lob.substr(trim(actors), 1, 10) <> '[[]]'
        --and rownum < 10
    )
    where
        actor_id is not null
        -- and actor_name is not null
        and regexp_like(actor_id, '^[0-9]+$')
)
-- order by 1 DESC
;



select regexp_substr('[[54768,,Turo Pajala,,3,,Taisto Olavi Kasurinen,,||54769,,Susanna Haavisto,,4,,Irmeli Katariina Pihlaja,,||4826,,Matti Pellonpää,,5,,Mikkonen,,||54770,,Eetu Hilkamo,,6,,Riku,,]]', '[^,]+', 3, 2) from dual;



with split_actors(actor, actors, idx) as (
    select
        dbms_lob.substr(
            actors,
            case dbms_lob.instr(actors, '||', 3, 1)
                when 0 then dbms_lob.getlength(actors) - 4
                else dbms_lob.instr(actors, '||', 3, 1) - 3
            end,
            3
        ),
        actors,
        case dbms_lob.instr(actors, '||', 3, 1)
            when 0 then dbms_lob.getlength(actors)
            else dbms_lob.instr(actors, '||', 3, 1) + 2
        end
    from movies_ext
    union all
    select
        dbms_lob.substr(
            actors,
            case dbms_lob.instr(actors, '||', idx)
                when 0 then dbms_lob.getlength(actors) - 1
                else dbms_lob.instr(actors, '||', idx)
            end - idx,
            idx
        ),
        actors,
        case dbms_lob.instr(actors, '||', idx, 1)
            when 0 then dbms_lob.getlength(actors)
            else dbms_lob.instr(actors, '||', idx, 1)
        end + 2
    from split_actors
    where idx < dbms_lob.getlength(actors)
) select * from split_actors;




with split_production_countries(production_country, production_countries, idx) as (
    select
        substr(
            production_countries,
            3,
            case instr(production_countries, '||', 3, 1)
                when 0 then length(production_countries) - 4
                else instr(production_countries, '||', 3, 1) - 3
            end
        ),
        production_countries,
        case instr(production_countries, '||', 3, 1)
            when 0 then length(production_countries)
            else instr(production_countries, '||', 3, 1) + 2
        end
    from movies_ext
    union all
    select
        substr(
            production_countries,
            idx,
            case instr(production_countries, '||', idx)
                when 0 then length(production_countries) - 1
                else instr(production_countries, '||', idx)
            end - idx
        ),
        production_countries,
        case instr(production_countries, '||', idx, 1)
            when 0 then length(production_countries)
            else instr(production_countries, '||', idx, 1)
        end + 2
    from split_production_countries
    where idx < length(production_countries)
) select * from split_production_countries;




with split(splitted, field, idx) as (
    select
        substr(
            actors,
            3,
            case instr(actors, '||', 3, 1)
                when 0 then length(actors) - 4
                else instr(actors, '||', 3, 1) - 3
            end
        ),
        actors,
        case instr(actors, '||', 3, 1)
            when 0 then length(actors)
            else instr(actors, '||', 3, 1) + 2
        end
    from movies_ext
    union all
    select
        substr(
            field,
            idx,
            case instr(field, '||', idx)
                when 0 then length(field) - 1
                else instr(field, '||', idx)
            end - idx
        ),
        field,
        case instr(field, '||', idx, 1)
            when 0 then length(field)
            else instr(field, '||', idx, 1)
        end + 2
    from split
    where idx < length(field)
) select * from split;


declare
    res varchar2_t;

begin
    with split_actors(actor, actors, idx) as (
        select
            substr(
                actors,
                3,
                case instr(actors, '||', 3, 1)
                    when 0 then length(actors) - 4
                    else instr(actors, '||', 3, 1) - 3
                end
            ),
            actors,
            case instr(actors, '||', 3, 1)
                when 0 then length(actors)
                else instr(actors, '||', 3, 1) + 2
            end
        from movies_ext
        union all
        select
            substr(
                actors,
                idx,
                case instr(actors, '||', idx)
                    when 0 then length(actors) - 1
                    else instr(actors, '||', idx)
                end - idx
            ),
            actors,
            case instr(actors, '||', idx, 1)
                when 0 then length(actors)
                else instr(actors, '||', idx, 1)
            end + 2
        from split_actors
        where idx < length(actors)
    )
    select actor bulk collect into res
    from split_actors;

    dbms_output.put_line(res.count);
end;
