create or replace package body cb_transfer is

    -- TODO Pulls should get a flag to pull from cbb instead of cb.

    procedure pull_movies is
    begin
        insert into movies
            select data from cc_queue@link.cb
            where type = 'movie'
                and extractvalue(data, '/movie/id') not in (
                    select extractvalue(object_value, '/movie/id') from movies
                );
        delete from cc_queue@link.cb where type = 'movie';
    end;

    procedure pull_copies is
    begin
        insert into copies
            select data from cc_queue@link.cb
            where type = 'copy';
        delete from cc_queue@link.cb where type = 'copy';
    end;

    function movie_exists(
        p_movie_id number) return boolean
    is
        x number;
    begin
        select 1 into x from movies where extractvalue(object_value, '/movie/id') = p_movie_id;
        return true;
    exception
        when no_data_found then
            return false;
    end;

    procedure push_copies
        -- TODO Should get a flag to send to cbb instead of cb
    is
        pragma autonomous_transaction;
        v_copies management.copies_t@link.cb;
    begin
        select
            extractvalue(object_value, '/schedule/movie_id') "movie_id",
            extractvalue(object_value, '/schedule/copy_id') "copy_id"
        bulk collect into v_copies
        from
            schedules s
        where not exists(
            select * from
                schedules s2,
                xmltable('/schedule/time_schedule/schedule_start' passing s.object_value) t
            where
                to_timestamp_tz(
                    extractvalue(t.column_value, 'schedule_start'),
                    'YYYY-MM-DD"T"HH24:MI:SS.FFTZH:TZM'
                ) + (
                    select
                        numtodsinterval(extractvalue(m.object_value, '/movie/runtime'), 'minute')
                    from movies m
                    where
                        extractvalue(m.object_value, '/movie/id') = extractvalue(s.object_value, '/schedule/movie_id')
                ) + numtodsinterval(30, 'minute') > current_timestamp
                and extractvalue(s.object_value,'/schedule/movie_id') = extractvalue(s2.object_value,'/schedule/movie_id')
                and extractvalue(s.object_value,'/schedule/copy_id') = extractvalue(s2.object_value,'/schedule/copy_id')
        );

        logging.d('Found ' || v_copies.count || ' copies to send back.');
        if v_copies.count = 0 then
            return;
        end if;

        forall i in indices of v_copies
            delete from copies
            where
                extractvalue(object_value, '/copy/movie_id') = v_copies(i).movie_id
                and extractvalue(object_value, '/copy/copy_id') = v_copies(i).copy_id
            ;

        for i in v_copies.first..v_copies.last loop
            insert into copies@link.cb(movie_id, copy_id, backup_flag) values (
                v_copies(i).movie_id, v_copies(i).copy_id, 0
            );
            logging.d('sending copy ' || v_copies(i).copy_id || ':' || v_copies(i).movie_id || ' back.');
        end loop;

        commit;
    exception
        when others then
            logging.e('Error sending copies back: ' || sqlerrm);
            rollback;
            raise;
    end;

end cb_transfer;
/
