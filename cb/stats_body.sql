create or replace package body stats is

    -- Types
    -- -----
    type result_r is record (
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
    type result_t is table of result_r;

    -- Constants
    -- ---------
    split_request_template constant varchar2(2000) := q'[with split(splitted, field, idx) as (
        select
            substr(
                :column,
                3,
                case instr(:column, '||', 3, 1)
                    when 0 then length(:column) - 4
                    else instr(:column, '||', 3, 1) - 3
                end
            ),
            :column,
            case instr(:column, '||', 3, 1)
                when 0 then length(:column)
                else instr(:column, '||', 3, 1) + 2
            end
        from movies_ext
        where 1 = 1
            and :column is not null
            and :column <> trim('[[]] ')
            and length(:column) <> 0
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
    ) select distinct splitted from split]';

    stat_request_template constant varchar2(2000) := 'select :name,
        median(length(:column)),
        stddev(length(:column)),
        max(length(:column)),
        min(length(:column)),
        avg(length(:column)),
        percentile_cont(0.99) within group (order by length(:column)),
        percentile_cont(0.9999) within group (order by length(:column)),
        -1, -1, -1
        from movies_ext';

    split_request_actor constant varchar2(2000) := q'[with split(splitted, field, idx) as (
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
        from (
            select actors, rownum rnum from movies_ext
            where rownum <= :max
                and actors is not null
                and actors <> trim('[[]] ')
                and length(actors) <> 0
        ) where rnum > :min
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
    ) select distinct splitted from split]';

    columns_names constant varchar2_t := varchar2_t('genres',
        'production_companies',
        'spoken_languages',
        'production_countries'
    );

    single_columns constant varchar2_t := varchar2_t(
        'id', 'title', 'original_title', 'release_date', 'status',
        'vote_average', 'vote_count', 'runtime', 'certification',
        'poster_path', 'budget', 'revenue', 'homepage', 'tagline',
        'overview'
    );

    procedure analyze_table(
        p_file varchar2)
    is
        tab_result result_t := result_t();

        split_request varchar2(2000);
        stat_request  varchar2(2000);
        splitted      varchar2(1000);
        t             varchar2(1000);

        j pls_integer := 0;

        chars1_v varchar2_t;
        chars2_v varchar2_t := varchar2_t();
        chars3_v varchar2_t := varchar2_t();
        chars4_v varchar2_t := varchar2_t();
        chars5_v varchar2_t := varchar2_t();
        chars6_v varchar2_t := varchar2_t();

        c pls_integer := 0;
        chunk_size constant pls_integer := 5000;
        i_min pls_integer := 0;
        i_max pls_integer := chunk_size;
    begin
        timer.init;

        -- Actors
        --------------------------
        select count(*) into c from movies_ext
        where actors is not null
            and actors <> '[[]]'
            and length(actors) <> 0;
        dbms_output.put_line('counted ' || c || ' actor rows in ' || timer.lap);

        while i_min < c loop
            execute immediate split_request_actor bulk collect into chars1_v using in i_max, in i_min;
            i_min := i_min + chunk_size;
            i_max := i_max + chunk_size;

            for i in chars1_v.first..chars1_v.last loop
                j := 1;
                splitted := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);

                while length(splitted) <> 0 loop
                    splitted := trim(',' from splitted);
                    case j
                        when 1 then
                            chars2_v.extend;
                            chars2_v(chars2_v.count) := splitted;
                        when 2 then
                            chars3_v.extend;
                            chars3_v(chars3_v.count) := splitted;
                        when 3 then
                            chars4_v.extend;
                            chars4_v(chars4_v.count) := splitted;
                        when 4 then
                            chars5_v.extend;
                            chars5_v(chars5_v.count) := splitted;
                        when 5 then
                            chars6_v.extend;
                            chars6_v(chars6_v.count) := splitted;
                    end case;
                    j := j + 1;
                    splitted := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
                end loop;
            end loop;
        end loop;
        dbms_output.put_line('Collected actors in ' || timer.lap);

        tab_result.extend;
        tab_result(tab_result.count) := field_stat('Actors id', chars2_v);
        tab_result(tab_result.count).nbvalue := chars2_v.count;

        tab_result.extend;
        tab_result(tab_result.count) := field_stat('Actors name', chars3_v);
        tab_result(tab_result.count).nbvalue := chars3_v.count;

        tab_result.extend;
        tab_result(tab_result.count) := field_stat('Actors cast_id', chars4_v);
        tab_result(tab_result.count).nbvalue := chars4_v.count;

        tab_result.extend;
        tab_result(tab_result.count) := field_stat('Actors character', chars5_v);
        tab_result(tab_result.count).nbvalue := chars5_v.count;

        tab_result.extend;
        tab_result(tab_result.count) := field_stat('Actors profile_path', chars6_v);
        tab_result(tab_result.count).nbvalue := chars6_v.count;
        dbms_output.put_line('Actor stats in ' || timer.lap);


        for l in columns_names.first..columns_names.last loop
            split_request := replace(split_request_template, ':column', columns_names(l));

            execute immediate split_request bulk collect into chars1_v;

            chars2_v := varchar2_t();
            chars3_v := varchar2_t();
            for i in chars1_v.first..chars1_v.last loop
                j := 1;
                splitted := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);

                while length(splitted) <> 0 loop
                    splitted := trim(',' from splitted);
                    case j
                        when 1 then
                            chars2_v.extend;
                            chars2_v(chars2_v.count) := splitted;
                        when 2 then
                            chars3_v.extend;
                            chars3_v(chars3_v.count) := splitted;
                    end case;
                    j := j + 1;
                    splitted := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
                end loop;
            end loop;
            dbms_output.put_line('Fetched ' || columns_names(l) || ' in ' || timer.lap);

            tab_result.extend;
            tab_result(tab_result.count) := field_stat(columns_names(l) || ' id', chars2_v);
            tab_result(tab_result.count).nbvalue := chars2_v.count;

            tab_result.extend;
            tab_result(tab_result.count) := field_stat(columns_names(l) || ' value', chars3_v);
            tab_result(tab_result.count).nbvalue := chars3_v.count;
            dbms_output.put_line(columns_names(l) || ' stats in ' || timer.lap);
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
            splitted := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);

            while length(splitted) <> 0 loop
                splitted := trim(',' from splitted);
                case j
                    when 1 then
                        chars2_v.extend;
                        chars2_v(chars2_v.count) := splitted;
                    when 2 then
                        chars3_v.extend;
                        chars3_v(chars3_v.count) := splitted;
                    when 3 then
                        chars4_v.extend;
                        chars4_v(chars4_v.count) := splitted;
                end case;
                j := j + 1;
                splitted := regexp_substr(chars1_v(i), '(.*?)(\,{2}|$)', 1, j);
            end loop;
        end loop;
        dbms_output.put_line('Fetched directors in ' || timer.lap);

        tab_result.extend;
        tab_result(tab_result.count) := field_stat('Directors id', chars2_v);
        tab_result(tab_result.count).nbvalue := chars2_v.count;

        tab_result.extend;
        tab_result(tab_result.count) := field_stat('Directors name', chars3_v);
        tab_result(tab_result.count).nbvalue := chars3_v.count;

        tab_result.extend;
        tab_result(tab_result.count) := field_stat('Directors profile_path', chars4_v);
        tab_result(tab_result.count).nbvalue := chars4_v.count;
        dbms_output.put_line('Director stats in ' || timer.lap);


        for m in single_columns.first..single_columns.last loop
            stat_request := replace(stat_request_template, ':column', single_columns(m));
            tab_result.extend;
            execute immediate stat_request into tab_result(tab_result.count) using single_columns(m);

            execute immediate 'select count(*) from movies_ext where ' || single_columns(m) || ' is not null' into tab_result(tab_result.count).nbvalue;
            execute immediate 'select count(*) from movies_ext where ' || single_columns(m) || ' is null' into tab_result(tab_result.count).nbnull;

            select data_type into t from USER_TAB_COLUMNS where column_name = upper(single_columns(m)) and lower(table_name) = 'movies_ext';

            case t
                when 'NUMBER' then
                    execute immediate 'select count(*) from movies_ext where ' || single_columns(m) || ' = 0' into tab_result(tab_result.count).nbzero;
                when 'VARCHAR2' then
                    execute immediate 'select count(*) from movies_ext where ' || single_columns(m) || ' = ''''' into tab_result(tab_result.count).nbzero;
                else
                    null;
            end case;
            dbms_output.put_line(single_columns(m) || ' stats in ' || timer.lap);
        end loop;

        dbms_output.put_line('Displaying results');
        write_results_to_file(p_file, tab_result);
        dbms_output.put_line('Wrote to file in ' || timer.lap);
        dbms_output.put_line('Script took '      || timer.total);
    exception
        when others then
            dbms_output.put_line(sqlerrm);
            dbms_output.put_line(dbms_utility.format_call_stack);
            dbms_output.put_line(dbms_utility.format_error_backtrace);
            raise;
    end;

    function field_stat(
        p_name  in varchar2,
        p_table in varchar2_t) return result_r
    is
        result_v result_r;
    begin
        select
            p_name,
            median(length(column_value)),
            stddev(length(column_value)),
            max(length(column_value)),
            min(length(column_value)),
            avg(length(column_value)),
            percentile_cont(0.99) within group(order by length(column_value)),
            percentile_cont(0.9999) within group(order by length(column_value)),
            -1, -1, -1
        into result_v
        from table(p_table);
        return result_v;
    end;

    procedure write_results_to_file(
        p_file   in varchar2,
        p_result in result_t)
    is
        output_file utl_file.file_type;
    begin
        output_file := utl_file.fopen('MOVIES_DIR', p_file, 'W');
        utl_file.put_line(output_file, 'analysis report for movies_ext');
        utl_file.put_line(output_file, '');
        utl_file.put_line(output_file,
               'Name                       | '
            || ' Median | '
            || ' Stddev | '
            || '  Max | '
            || '  Min | '
            || '  Avg | '
            || ' Cperc | '
            || ' Mperc | '
            || ' Nbvalue | '
            || ' Nbnull | '
            || ' Nbzero'
        );
        for i in p_result.first..p_result.last loop
            utl_file.put_line(output_file,
                   rpad(p_result(i).name,   26, ' ') || ' | '
                || lpad(p_result(i).median,  7, ' ') || ' | '
                || lpad(p_result(i).stddev,  7, ' ') || ' | '
                || lpad(p_result(i).max,     5, ' ') || ' | '
                || lpad(p_result(i).min,     5, ' ') || ' | '
                || lpad(p_result(i).average, 5, ' ') || ' | '
                || lpad(p_result(i).cperc,   6, ' ') || ' | '
                || lpad(p_result(i).mperc,   6, ' ') || ' | '
                || lpad(p_result(i).nbvalue, 8, ' ') || ' | '
                || lpad(p_result(i).nbnull,  7, ' ') || ' | '
                || lpad(p_result(i).nbzero,  7, ' ')
            );
        end loop;
        utl_file.fclose(output_file);
    exception
        when others then
            if utl_file.is_open(output_file) then
                utl_file.fclose(output_file);
            end if;
            raise;
    end;

end stats;
/
