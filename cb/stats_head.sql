create or replace package stats is

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

    procedure analyze_table;

    function field_stat(
        p_name  in varchar2,
        p_table in varchar2_t) return result_r;

    procedure write_result_to_file(
        p_file   in varchar2,
        p_result in result_t);

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

end stats;
/
