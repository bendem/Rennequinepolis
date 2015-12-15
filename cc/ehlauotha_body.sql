create or replace package body ehlauotha is

    type schedules_t is table of schedule_r;

    unknown_film_exception exception;

    procedure read_schedule_file
    is
        v_schedules schedules_t;
    begin
        with xml(value) as (
            select
                *
            from xmltable(
                '/schedules/schedule' passing
                xmltype(bfilename('MOVIES_DIR', 'schedules.xml'), nls_charset_id('AL32UTF8'))
            )
        )
        select
            extractvalue(value, '/schedule/movie_id'),
            extractvalue(value, '/schedule/start'),
            extractvalue(value, '/schedule/hall_id')
            bulk collect into v_schedules
        from xml;

        for i in v_schedules.first..v_schedules.last loop
            begin
                schedule(v_schedules(i));
            exception
                when unknown_film_exception then
                    -- TODO
                    null;
            end;
        end loop;
    end;

    procedure schedule(
        p_schedule schedule_r)
    is
        v_days pls_integer;
        time timestamp(0);
    begin
        -- TODO:
        -- + Check there is no movie at that time in that hall
        -- + Check there is a copy available at that time
        if not cb_transfer.movie_exists(p_schedule.movie_id) then
            raise unknown_film_exception;
        end if;

        v_days := round(abs(sys.dbms_random.normal * 3) + 8);

        for i in 1..v_days loop
            time := to_timestamp(to_char(current_date, 'DD-MM-YYYY') || ' ' || p_schedule.start_time, 'DD-MM-YYYY HH24:MI');
            dbms_output.put_line(time);
            schedule(p_schedule, time);
        end loop;
    end;

    procedure schedule(
        p_schedule schedule_r,
        time timestamp)
    is
    begin
        null;
    end;

end ehlauotha;
/
