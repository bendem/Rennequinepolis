create or replace package body cbb_transfer is

    -- TODO Pulls should get a flag to pull from cbb instead of cb.

    procedure pull_movies is
    begin
        insert into movies
            select data from cc_queue@link.cbb
            where type = 'movie'
                and extractvalue(data, '/movie/id') not in (
                    select extractvalue(object_value, '/movie/id') from movies
                );
        delete from cc_queue@link.cbb where type = 'movie';
    end;

    procedure pull_copies is
    begin
        insert into copies
            select data from cc_queue@link.cbb
            where type = 'copy';
        delete from cc_queue@link.cbb where type = 'copy';
    end;

    function movie_exists(
        p_movie_id number) return boolean
    is
    begin
        return cb_transfer.movie_exists(p_movie_id);
    end;

    procedure push_copies
        -- TODO Should get a flag to send to cbb instead of cb
    is
        pragma autonomous_transaction;
        v_copies management.copies_t@link.cbb;
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

        forall i in indices of v_copies
            delete from copies
            where
                extractvalue(object_value, '/copy/movie_id') = v_copies(i).movie_id
                and extractvalue(object_value, '/copy/copy_id') = v_copies(i).copy_id
            ;

        for i in v_copies.first..v_copies.last loop
            insert into copies@link.cbb(movie_id, copy_id, backup_flag) values (
                v_copies(i).movie_id, v_copies(i).copy_id, 0
            );
        end loop;

        commit;
    exception
        when others then
            rollback;
            raise;
    end;

end cb_transfer;
/
