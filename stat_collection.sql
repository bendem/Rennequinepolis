create or replace procedure field_analysis is
    type r_result is record (
        name            varchar2(100),
        median          pls_integer,
        stddev          pls_integer,
        max             pls_integer,
        min             pls_integer,
        average         pls_integer,
        cperc           pls_integer,
        mperc           pls_integer,
        nbvalue         pls_integer,
        nbnull          pls_integer,
        nbzero          pls_integer
    );

    type t_result is table of r_result; --index by binary_integer;

    type id_t           is table of movies_ext.id%type;
    type actor_t        is table of movies_ext.actors%type;
    type director_t     is table of movies_ext.directors%type;
    type genre_t        is table of movies_ext.genres%type;
    type prod_company_t is table of movies_ext.production_companies%type;
    type prod_country_t is table of movies_ext.production_countries%type;
    type spoken_lang_t  is table of movies_ext.spoken_languages%type;

    id_v number_t;

    tab_result t_result := t_result();

    split_request_template varchar2(2000) := 'with split(splitted, field, idx) as (
        select
            substr(
                :column,
                3,
                case instr(:column, ''||'', 3, 1)
                    when 0 then length(:column) - 4
                    else instr(:column, ''||'', 3, 1) - 3
                end
            ),
            :column,
            case instr(:column, ''||'', 3, 1)
                when 0 then length(:column)
                else instr(:column, ''||'', 3, 1) + 2
            end
        from movies_ext
        where 1 = 1
            and :column is not null
            and :column <> ''[[]]''
            and length(:column) <> 0
        union all
        select
            substr(
                field,
                idx,
                case instr(field, ''||'', idx)
                    when 0 then length(field) - 1
                    else instr(field, ''||'', idx)
                end - idx
            ),
            field,
            case instr(field, ''||'', idx, 1)
                when 0 then length(field)
                else instr(field, ''||'', idx, 1)
            end + 2
        from split
        where idx < length(field)
    ) select distinct splitted from split';

    split_request varchar2(2000);

    stat_request_template varchar2(2000) := 'select :name,
        median(length(:column)),
        stddev(length(:column)),
        max(length(:column)),
        min(length(:column)),
        avg(length(:column)),
        percentile_cont(0.99) within group (order by length(:column)),
        percentile_cont(0.9999) within group (order by length(:column)),
        -1, -1, -1
        from movies_ext';
    stat_request varchar2(2000);

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

    columns_names varchar2_t := varchar2_t('genres',
        'production_companies',
        'spoken_languages',
        'production_countries'
    );

    single_columns varchar2_t := varchar2_t(
        'id', 'title', 'original_title', 'release_date', 'status',
        'vote_average', 'vote_count', 'runtime', 'certification',
        'poster_path', 'budget', 'revenue', 'homepage', 'tagline',
        'overview'
    );

    split_request_actor varchar2(2000) := 'with split(splitted, field, idx) as (
        select
            substr(
                actors,
                3,
                case instr(actors, ''||'', 3, 1)
                    when 0 then length(actors) - 4
                    else instr(actors, ''||'', 3, 1) - 3
                end
            ),
            actors,
            case instr(actors, ''||'', 3, 1)
                when 0 then length(actors)
                else instr(actors, ''||'', 3, 1) + 2
            end
        from (
            select actors, rownum rnum from movies_ext
            where rownum <= :max
                and actors is not null
                and actors <> ''[[]]''
                and length(actors) <> 0
        ) where rnum > :min
        union all
        select
            substr(
                field,
                idx,
                case instr(field, ''||'', idx)
                    when 0 then length(field) - 1
                    else instr(field, ''||'', idx)
                end - idx
            ),
            field,
            case instr(field, ''||'', idx, 1)
                when 0 then length(field)
                else instr(field, ''||'', idx, 1)
            end + 2
        from split
        where idx < length(field)
    ) select distinct splitted from split';

    c pls_integer := 0;
    chunk_size pls_integer := 6500;
    i_min pls_integer := 0;
    i_max pls_integer := chunk_size;
begin

    chars2_v := varchar2_t();
    chars3_v := varchar2_t();
    chars4_v := varchar2_t();
    chars5_v := varchar2_t();
    chars6_v := varchar2_t();

    -- Actors
    --------------------------

    select count(*) into c from movies_ext
    where actors is not null
        and actors <> '[[]]'
        and length(actors) <> 0;
    dbms_output.put_line('counted ' || c || ' rows');

    while i_min < c loop
        execute immediate split_request bulk collect into chars1_v using in i_max, in i_min;
        dbms_output.put_line('batch ' || i_min || ':' || i_max || ', got ' || chars1_v.count || ' results');
        i_min := i_min + chunk_size;
        i_max := i_max + chunk_size;

        dbms_output.put_line(chars1_v.count);

        for i in chars1_v.first..chars1_v.last loop
            j := 1;
            y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);

            while length(y) <> 0 loop
                y := trim(trailing ',' from y);
                case j
                    when 1 then
                        chars2_v.extend;
                        chars2_v(chars2_v.count) := y;
                    when 2 then
                        chars3_v.extend;
                        chars3_v(chars3_v.count) := y;
                    when 3 then
                        chars4_v.extend;
                        chars4_v(chars4_v.count) := y;
                    when 4 then
                        chars5_v.extend;
                        chars5_v(chars5_v.count) := y;
                    when 5 then
                        chars6_v.extend;
                        chars6_v(chars6_v.count) := y;
                end case;
                j := j + 1;
                y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
            end loop;
        end loop;
    end loop;

    tab_result.extend;
    select
        'Actors id profile',
        median(length(column_value)),
        stddev(length(column_value)),
        max(length(column_value)),
        min(length(column_value)),
        avg(length(column_value)),
        percentile_cont(0.99) within group (order by length(column_value)),
        percentile_cont(0.9999) within group (order by length(column_value)),
        -1, -1, -1
    into tab_result(tab_result.count)
    from table(chars2_v);

    tab_result.extend;
    select
        'Actors name profile',
        median(length(column_value)),
        stddev(length(column_value)),
        max(length(column_value)),
        min(length(column_value)),
        avg(length(column_value)),
        percentile_cont(0.99) within group (order by length(column_value)),
        percentile_cont(0.9999) within group (order by length(column_value)),
        -1, -1, -1
    into tab_result(tab_result.count)
    from table(chars3_v);

    tab_result.extend;
    select
        'Actors cast_id profile',
        median(length(column_value)),
        stddev(length(column_value)),
        max(length(column_value)),
        min(length(column_value)),
        avg(length(column_value)),
        percentile_cont(0.99) within group (order by length(column_value)),
        percentile_cont(0.9999) within group (order by length(column_value)),
        -1, -1, -1
    into tab_result(tab_result.count)
    from table(chars4_v);

    tab_result.extend;
    select
        'Actors character profile',
        median(length(column_value)),
        stddev(length(column_value)),
        max(length(column_value)),
        min(length(column_value)),
        avg(length(column_value)),
        percentile_cont(0.99) within group (order by length(column_value)),
        percentile_cont(0.9999) within group (order by length(column_value)),
        -1, -1, -1
    into tab_result(tab_result.count)
    from table(chars5_v);

    tab_result.extend;
    select
        'Actors profile_path profile',
        median(length(column_value)),
        stddev(length(column_value)),
        max(length(column_value)),
        min(length(column_value)),
        avg(length(column_value)),
        percentile_cont(0.99) within group (order by length(column_value)),
        percentile_cont(0.9999) within group (order by length(column_value)),
        -1, -1, -1
    into tab_result(tab_result.count)
    from table(chars6_v);

    for l in columns_names.first..columns_names.last loop
        split_request := replace(split_request_template, ':column', columns_names(l));

        execute immediate split_request bulk collect into chars1_v;

        dbms_output.put_line(chars1_v.count);

        chars2_v := varchar2_t();
        chars3_v := varchar2_t();
        for i in chars1_v.first..chars1_v.last loop
            j := 1;
            y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);

            while length(y) <> 0 loop
                y := trim(trailing ',' from y);
                case j
                    when 1 then
                        chars2_v.extend;
                        chars2_v(chars2_v.count) := y;
                    when 2 then
                        chars3_v.extend;
                        chars3_v(chars3_v.count) := y;
                end case;
                j := j + 1;
                y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
            end loop;
        end loop;

        tab_result.extend;
        select
            columns_names(l) || ' id profile',
            median(length(column_value)),
            stddev(length(column_value)),
            max(length(column_value)),
            min(length(column_value)),
            avg(length(column_value)),
            percentile_cont(0.99) within group (order by length(column_value)),
            percentile_cont(0.9999) within group (order by length(column_value)),
            -1, -1, -1
        into tab_result(tab_result.count)
        from table(chars2_v);

        tab_result.extend;
        select
            columns_names(l) || ' value profile',
            median(length(column_value)),
            stddev(length(column_value)),
            max(length(column_value)),
            min(length(column_value)),
            avg(length(column_value)),
            percentile_cont(0.99) within group (order by length(column_value)),
            percentile_cont(0.9999) within group (order by length(column_value)),
            -1, -1, -1
        into tab_result(tab_result.count)
        from table(chars3_v);

    end loop;

    -- ---------------------------
    -- Directors
    split_request := replace(split_request_template, ':column', 'directors');

    execute immediate split_request bulk collect into chars1_v;

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
                    chars2_v.extend;
                    chars2_v(chars2_v.count) := y;
                when 2 then
                    chars3_v.extend;
                    chars3_v(chars3_v.count) := y;
                when 3 then
                    chars4_v.extend;
                    chars4_v(chars4_v.count) := y;
            end case;
            j := j + 1;
            y := regexp_substr(chars1_v(i), '(.+?)(\,{2,}|$)', 1, j);
        end loop;
    end loop;

    tab_result.extend;
    select
        'Directors id profile',
        median(length(column_value)),
        stddev(length(column_value)),
        max(length(column_value)),
        min(length(column_value)),
        avg(length(column_value)),
        percentile_cont(0.99) within group (order by length(column_value)),
        percentile_cont(0.9999) within group (order by length(column_value)),
        -1, -1, -1
    into tab_result(tab_result.count)
    from table(chars2_v);

    tab_result.extend;
    select
        'Directors name profile',
        median(length(column_value)),
        stddev(length(column_value)),
        max(length(column_value)),
        min(length(column_value)),
        avg(length(column_value)),
        percentile_cont(0.99) within group (order by length(column_value)),
        percentile_cont(0.9999) within group (order by length(column_value)),
        -1, -1, -1
    into tab_result(tab_result.count)
    from table(chars3_v);

    tab_result.extend;

    select
        'Directors profile_path profile',
        median(length(column_value)),
        stddev(length(column_value)),
        max(length(column_value)),
        min(length(column_value)),
        avg(length(column_value)),
        percentile_cont(0.99) within group (order by length(column_value)),
        percentile_cont(0.9999) within group (order by length(column_value)),
        -1, -1, -1
    into tab_result(tab_result.count)
    from table(chars4_v);


    for m in single_columns.first..single_columns.last loop
        stat_request := replace(stat_request_template, ':column', single_columns(m));
        tab_result.extend;
        execute immediate stat_request into tab_result(tab_result.count) using single_columns(m);

        execute immediate 'select count(*) from movies_ext where ' || single_columns(m) || ' is not null' into tab_result(tab_result.count).nbvalue;
        execute immediate 'select count(*) from movies_ext where ' || single_columns(m) || ' is null' into tab_result(tab_result.count).nbnull;

        select data_type into z from USER_TAB_COLUMNS where column_name = upper(single_columns(m));

        case z
            when 'NUMBER' then
                execute immediate 'select count(*) from movies_ext where ' || single_columns(m) || ' = 0' into tab_result(tab_result.count).nbzero;
            when 'VARCHAR2' then
                execute immediate 'select count(*) from movies_ext where ' || single_columns(m) || ' = ''''' into tab_result(tab_result.count).nbzero;
            else
                dbms_output.put_line('else');
        end case;
    end loop;

    dbms_output.put_line('displaying results');

    indx := tab_result.first;
    while indx is not null loop
        dbms_output.put_line('Nom: ' || tab_result(indx).name);
        dbms_output.put_line('Median: ' || tab_result(indx).median
            || ' stddev: '  || tab_result(indx).stddev
            || ' max: '     || tab_result(indx).max
            || ' min: '     || tab_result(indx).min
            || ' avg: '     || tab_result(indx).average
            || ' cperc: '   || tab_result(indx).cperc
            || ' mperc: '   || tab_result(indx).mperc
            || ' nbvalue: ' || tab_result(indx).nbvalue
            || ' nbnull: '  || tab_result(indx).nbnull
            || ' nbzero: '  || tab_result(indx).nbzero);
        indx := tab_result.next(indx);
    end loop;
exception
    when others then
        dbms_output.put_line(sqlerrm);
        dbms_output.put_line(dbms_utility.format_call_stack);
        dbms_output.put_line(dbms_utility.format_error_backtrace);
        raise;
end;
/
