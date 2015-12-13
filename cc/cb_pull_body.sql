create or replace package body cb_pull is

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
        delete from cc_queue@link.cb where type = 'type';
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

end cb_pull;
/
