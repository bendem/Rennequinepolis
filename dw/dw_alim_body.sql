create or replace package body dw_alim is

    procedure load_dimensions
    is
    begin
        merge into dimension_countries here using (
            select
                nationality
            from actors@link.alim
        ) there on (here.country = there.nationality)
        when not matched then
            insert values (
                there.nationality
            );

        merge into dimension_countries here using (
            select
                name
            from production_countries@link.alim
        ) there on (here.country = there.name)
        when not matched then
            insert values (
                there.name
            );

        merge into dimension_genre here using (
            select
                name
            from genres@link.alim
        ) there on (here.genre = there.name)
        when not matched then
            insert values (
                there.name
            );

        merge into dimension_hall here using (
            select
                hall_id,
                theater_id
            from halls@link.alim
        ) there on (here.hall = there.hall_id and here.theater = there.theater_id)
        when not matched then
            insert values (
                there.hall_id,
                there.theater_id
            );

        merge into dimension_movie here using (
            select
                movie_id
            from movies@link.alim
        ) there on (here.movie = there.movie_id)
        when not matched then
            insert values (
                there.movie_id
            );

        merge into dimension_time here using (
            select
                showing_time
            from schedules@link.alim
        ) there on (here.time = there.showing_time)
        when not matched then
            insert values (
                there.showing_time
            );


    exception
        when others then
            dbms_output.put_line(sqlerrm);
            dbms_output.put_line(dbms_utility.format_call_stack);
            dbms_output.put_line(dbms_utility.format_error_backtrace);
    end;

    procedure load_facts
    is
    begin
        null;
    exception
        when others then
            dbms_output.put_line(sqlerrm);
            dbms_output.put_line(dbms_utility.format_call_stack);
            dbms_output.put_line(dbms_utility.format_error_backtrace);
    end;

    procedure load_all
    is
    begin
        dw_alim.load_dimensions;
        dw_alim.load_facts;
        commit;
    exception
        when others then
        rollback;
            dbms_output.put_line(sqlerrm);
            dbms_output.put_line(dbms_utility.format_call_stack);
            dbms_output.put_line(dbms_utility.format_error_backtrace);
    end;

end dw_alim;
/
