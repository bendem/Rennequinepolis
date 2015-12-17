create or replace package body archive is

    type number_t is table of number;

    procedure archive
    is
        dml_exception exception;
        pragma exception_init(dml_exception, -24381);

        v_movie_ids number_t;
        a pls_integer := 1;
        b pls_integer := 0;
    begin
        with schedules_(copy_id, movie_id, schedule_start) as (
            select
                extractvalue(s.object_value, '/schedule/copy_id'),
                extractvalue(s.object_value, '/schedule/movie_id'),
                to_timestamp_tz(extractvalue(t.object_value, '/time_schedule/schedule_start'))
            from
                schedules s,
                xmltable('/schedule/time_schedule' passing s.object_value) t
        )
        select distinct
            movie_id
        bulk collect into v_movie_ids
        from schedules_
        where
            schedule_start < trunc(current_timestamp)
            and schedule_start > trunc(current_timestamp) - interval '1' day
        ;

        begin
            forall i in indices of v_movie_ids save exceptions
                insert into archives values (
                    xmlelement("archive",
                    xmlforest(
                        v_movie_ids(i) "movie_id",
                        a "running_days",
                        b "places_sold")));
        exception
            when dml_exception then
                for i in 1..sql%bulk_exceptions.count loop
                    if sql%bulk_exceptions(i).error_code = 1 then
                        a := sql%bulk_exceptions(i).error_index;
                        update archives set object_value = updatexml(
                            object_value,
                            '/archive/running_days/text()',
                            extractvalue(object_value, '/archive/running_days') + 1
                        ) where extractvalue(object_value, '/archive/movie_id')
                            = v_movie_ids(a)
                        ;
                    else
                        logging.e('Failed to update movie ' || v_movie_ids(sql%bulk_exceptions(i).error_index)
                            || ': ' || sqlerrm(sql%bulk_exceptions(i).error_code));
                    end if;
                end loop;
        end;
        commit;
    exception
        when others then
            logging.e('Failed to run archiving: ' || sqlerrm);
            rollback;
    end archive;

end archive;
/
