 create or replace package body scheduling is

    type schedules_t is table of schedule_r;

    procedure read_file
    is
        v_schedules schedules_t;
        v_filename varchar2(30) := get_filename;
        v_movie xmltype;
        v_x xmltype;
        v_writing boolean := false;
    begin
        v_x := xmltype(bfilename('XML_DIR', v_filename || '.xml'), nls_charset_id('AL32UTF8'));

        if v_x.isSchemaValid('http://xmlns.bendem.be/cc_schedules') = 0 then
            logging.e('Invalid schedule file');
            return;
        end if;

        with xml(value) as (
            select * from xmltable('/schedules/schedule' passing v_x)
        )
        select
            extractvalue(value, '/schedule/movie_id'),
            extractvalue(value, '/schedule/start'),
            extractvalue(value, '/schedule/hall_id')
            bulk collect into v_schedules
        from xml;

        if v_schedules.count = 0 then
            logging.e('No schedules to add');
            return;
        end if;

        for i in v_schedules.first..v_schedules.last loop
            begin
                select object_value into v_movie
                from movies
                where extractvalue(object_value, '/movie/id') = v_schedules(i).movie_id;
            exception
                when no_data_found then
                    report(error('No information about movie ' || v_schedules(i).movie_id), i, v_x);
                    continue;
            end;

            schedule(v_movie, v_schedules(i), v_x, i);
        end loop;

        insert_stylesheet(v_x);

        v_writing := true;
        dbms_xslprocessor.clob2file(v_x.getclobval(), 'XML_DIR', v_filename || '_feedback.xml');
        commit;
    exception
        when others then
            logging.e('An error happened while scheduling movies: ' || sqlerrm);
            rollback;
            if not v_writing then
                -- If failure doesn't come from writing the report, there will be useful information in it
                dbms_xslprocessor.clob2file(v_x.getclobval(), 'XML_DIR', v_filename || '_feedback.xml');
            end if;
            raise;
    end read_file;

    function get_filename return varchar2
    is
    begin
        return SCHEDULE_FILENAME || to_char(current_date, 'DD_MM_YYYY');
    end get_filename;

    procedure schedule(
        p_movie xmltype,
        p_schedule schedule_r,
        p_report in out nocopy xmltype,
        p_index pls_integer)
    is
        v_days pls_integer;
        v_time_start timestamp(0);
        v_time_end timestamp(0);
        v_closing_time timestamp(0);
        v_x xmltype;
        v_copy_id number;
    begin
        v_closing_time := to_timestamp(current_date) + closing_hour + closing_minute;
        v_time_start := to_timestamp(
            to_char(current_date , 'DD-MM-YYYY') || ' ' || p_schedule.start_time,
            'DD-MM-YYYY HH24:MI'
        );
        v_time_end := v_time_start
            + numtodsinterval(p_movie.extract('/movie/runtime/text()').getNumberVal(), 'minute')
            + movie_interval;

        if v_time_end > v_closing_time then
            report(error('Movie ends after the closing time', v_time_start), p_index, p_report);
            return;
        end if;

        v_days := round(abs(sys.dbms_random.normal * 3) + 8);

        for i in 0..v_days loop
            v_time_start := v_time_start + interval '1' day;
            v_time_end := v_time_end + interval '1' day;

            v_x := is_hall_free(v_time_start, v_time_end, p_schedule.hall_id);
            if v_x is not null then
                report(error('The movie ' || v_x.extract('/movie/id/text()').getNumberVal() || ' (' || v_x.extract('/movie/title/text()').getStringVal() || ') is playing at that time in that hall', v_time_start), p_index, p_report);
                continue;
            end if;

            v_copy_id := get_copy(p_schedule.movie_id, v_time_start, v_time_end);
            if v_copy_id is null then
                report(error('No copy available at that time', v_time_start), p_index, p_report);
                continue;
            end if;

            insert_schedule(p_schedule.movie_id, v_copy_id, p_schedule.hall_id, v_time_start);
            report(success(v_time_start), p_index, p_report);
        end loop;
    end schedule;

    procedure insert_schedule(
        p_movie_id number,
        p_copy_id number,
        p_hall_id number,
        p_time_start timestamp)
    is
    begin
        insert into schedules values (xmlelement(
            "schedule", xmlforest(
                p_copy_id "copy_id",
                p_movie_id "movie_id",
                xmlforest(
                    p_time_start "schedule_start",
                    p_hall_id "hall_id"
                ) "time_schedule"
            )
        ));
    exception
        when dup_val_on_index then
            update schedules set
                object_value = appendchildxml(
                    object_value,
                    '/schedule',
                    xmlelement(
                        "time_schedule",
                        xmlforest(
                            p_time_start "schedule_start",
                            p_hall_id "hall_id"
                        )
                    )
                )
            where extractvalue(object_value, '/schedule/copy_id') = p_copy_id
                and extractvalue(object_value, '/schedule/movie_id') = p_movie_id
            ;
    end insert_schedule;

    function is_hall_free(
        p_time_start timestamp,
        p_time_end timestamp,
        p_hall number) return xmltype
    is
        v_x xmltype;
    begin
        with schedules_(meta, schedule_start, hall_id) as (
            select
                s.object_value,
                to_timestamp_tz(extractvalue(t.object_value, '/time_schedule/schedule_start')),
                extractvalue(t.object_value, '/time_schedule/hall_id')
            from
                schedules s,
                xmltable('/schedule/time_schedule' passing s.object_value) t
        )
        select
            object_value into v_x
        from schedules_
        inner join movies on (extractvalue(object_value, '/movie/id') = extractvalue(meta, '/schedule/movie_id'))
        where (
                -- p_time_start is between scheduled movie start and end
                schedule_start < p_time_start
                and schedule_start
                    + numtodsinterval(extractvalue(object_value, '/movie/runtime'), 'minute')
                    + movie_interval > p_time_start
            or
                -- p_time_end is between scheduled movie start and end
                schedule_start < p_time_end
                and schedule_start
                    + numtodsinterval(extractvalue(object_value, '/movie/runtime'), 'minute')
                    + movie_interval > p_time_end
            )
            and hall_id = p_hall
            and rownum = 1 -- fail safe
        ;
        return v_x;
    exception
        when no_data_found then
            return null;
    end is_hall_free;

    function get_copy(
        p_movie_id number,
        p_time_start timestamp,
        p_time_end timestamp) return number
    is
        v_duration interval day(0) to second(0) := p_time_end - p_time_start;
        v_copy_id number;
    begin
        with schedules_(meta, schedule_start) as (
            select
                s.object_value,
                to_timestamp_tz(extractvalue(t.object_value, '/time_schedule/schedule_start'))
            from
                schedules s,
                xmltable('/schedule/time_schedule' passing s.object_value) t
        )
        select
            extractvalue(object_value, '/copy/copy_id') into v_copy_id
        from copies
        left join schedules_ on (
            extractvalue(meta, '/copy/movie_id') = p_movie_id
            and extractvalue(meta, '/copy/copy_id') = extractvalue(object_value, '/copy/copy_id')
        )
        where extractvalue(object_value, '/copy/movie_id') = p_movie_id
            and
            (
                -- not scheduled ever
                meta is null
            or
                -- not scheduled at the same time
                (
                    schedule_start + v_duration < p_time_start
                or
                    schedule_start > p_time_end
                )
            )
            and rownum = 1
        ;
        return v_copy_id;
    exception
        when no_data_found then
            return null;
    end get_copy;

    procedure insert_stylesheet(
        p_xml in out nocopy xmltype)
    is
    begin
        -- Oracle allows creating PIs, but there is 0 way to insert them...
        -- select insertxmlbefore(
        --     p_xml, '/schedules',
        --     xmlpi("xml-stylesheet", 'type="text/xsl" href="feedback.xsl"')
        -- ) into p_xml
        -- from dual;
    end insert_stylesheet;

    procedure report(
        p_msg xmltype,
        p_index number,
        p_xml in out nocopy xmltype)
    is
    begin
        select
            appendchildxml(p_xml, '/schedules/schedule[' || p_index || ']', p_msg)
        into p_xml
        from dual;
    end report;

    function error(
        p_msg varchar2,
        p_time timestamp) return xmltype
    is
    begin
        return xmltype('<error>
            <msg><![CDATA[' || p_msg || ']]></msg>
            <time>' || to_char(p_time, 'DD-MM-YYYY HH24:MI') || '</time>
        </error>');
    end error;

    function success(
        p_time timestamp) return xmltype
    is
    begin
        return xmltype('<success>' || to_char(p_time, 'DD-MM-YYYY HH24:MI') || '</success>');
    end success;

end scheduling;
/
