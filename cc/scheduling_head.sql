create or replace package scheduling is

    type schedule_r is record (
        movie_id number(6, 0),
        start_time char(5),
        hall_id number(3, 0)
    );

    -- TODO Doc
    procedure read_file;

    procedure schedule(
        p_movie xmltype,
        p_schedule schedule_r,
        p_report in out nocopy xmltype,
        p_index pls_integer);

    procedure insert_schedule(
        p_movie_id number,
        p_copy_id number,
        p_hall_id number,
        p_time_start timestamp);

    function get_filename return varchar2;

    function is_hall_free(
        p_time_start timestamp,
        p_time_end timestamp,
        p_hall number) return xmltype;

    -- @return a copy_id available at that time
    function get_copy(
        p_movie_id number,
        p_time_start timestamp,
        p_time_end timestamp) return number;

    procedure report(
        p_msg xmltype,
        p_index number,
        p_xml in out nocopy xmltype);

    function success(
        p_time timestamp) return xmltype;

    function error(
        p_msg varchar2,
        p_time timestamp := current_timestamp) return xmltype;

end scheduling;
/
