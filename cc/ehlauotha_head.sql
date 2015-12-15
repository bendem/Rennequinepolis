create or replace package ehlauotha is

    type schedule_r is record (
        movie_id number(6, 0),
        start_time timestamp(0),
        hall_id number(3, 0)
    );

    -- TODO
    procedure read_schedule_file;

    procedure schedule(
        p_schedule schedule_r);

    procedure schedule(
        p_schedule schedule_r,
        time timestamp);

end ehlauotha;
/
