create or replace package scheduling is

    type schedule_r is record (
        movie_id number(6, 0),
        start_time char(5),
        hall_id number(3, 0)
    );

    schedule_filename constant varchar2(10) := 'schedules_';

    movie_interval constant interval day(0) to second(0) := interval '30' minute;
    closing_hour   constant interval day(0) to second(0) := interval '23' hour;
    closing_minute constant interval day(0) to second(0) := interval '30' minute;

    -- Reads a file named <schedule_filename>DD_MM_YYYY.xml placed in the XML_DIR and
    -- matching cc_schedules.xsd and schedules movies based on this information.
    --
    -- Success and failures will be reported in a file named
    -- schedules_DD_MM_YYYY_feedback.xml in the same directory.
    procedure read_file;

    -- Checks provided schedule record and inserts it.
    -- @param p_movie information about the movie to be inserted (a line from cc.movies)
    -- @param p_schedule the schedule record to insert
    -- @param p_report the report file where the success / failure message will be inserted
    -- @param p_index the index of the schedule report (used to insert in the report)
    procedure schedule(
        p_movie xmltype,
        p_schedule schedule_r,
        p_report in out nocopy xmltype,
        p_index pls_integer);

    -- Actual insert in the schedule table. If the copy_id / movie_id pair already exists,
    -- the record is inserted in its time_schedule element. If not, it is created.
    -- @param p_movie_id the movie id
    -- @param p_copy_id the copy id
    -- @param p_hall_id the hall to play the movie in
    -- @param p_time_start the time the movie should start at
    procedure insert_schedule(
        p_movie_id number,
        p_copy_id number,
        p_hall_id number,
        p_time_start timestamp);

    -- Gets the filename to parse based on the current date using the
    -- cc.scheduling.schedule_filename constant.
    -- @return the filename for the current date
    function get_filename return varchar2;

    -- Checks whether no movie is played in a hall between 2 timestamps.
    -- @param p_time_start the start of the period the hall should be empty at
    -- @param p_time_end the end of the period the hall should be empty at
    -- @param p_hall the id of the hall
    -- @return the xmltype from movies of the movie played at that time or null
    --         if none was scheduled
    function is_hall_free(
        p_time_start timestamp,
        p_time_end timestamp,
        p_hall number) return xmltype;

    -- Gets an available copy for a film at a specified time.
    -- @param p_movie_id the id of the movie
    -- @param p_time_start the start of the period the copy should be free for
    -- @param p_time_end the end of the period the copy should be free for
    -- @return a copy id for the movie available at that time
    function get_copy(
        p_movie_id number,
        p_time_start timestamp,
        p_time_end timestamp) return number;

    -- Inserts a xmltype inside the report.
    -- @param p_msg the xmltype to insert (should be a success or error tag generated
    --              with the success or error methods)
    -- @param p_index the index to insert at in the report
    -- @param p_xml the report to insert into
    procedure report(
        p_msg xmltype,
        p_index number,
        p_xml in out nocopy xmltype);

    -- Inserts the stylesheet PI at the start of the document.
    -- @param p_xml the xmltype to insert to stylesheet PI in
    -- @FIXME We didn't actually find a way to insert it in, this method does nothing
    procedure insert_stylesheet(
        p_xml in out nocopy xmltype);

    -- Generates a success tag from a timestamp to insert in the report.
    -- @param p_time the timestamp at which the inserted schedule start
    function success(
        p_time timestamp) return xmltype;

    -- Generates an error tag from a message and a timestamp to insert in the report.
    -- @param p_msg the error message describing why the scheduling failed
    -- @param p_time the timestamp at which the schedule would have started
    function error(
        p_msg varchar2,
        p_time timestamp := current_timestamp) return xmltype;

end scheduling;
/
