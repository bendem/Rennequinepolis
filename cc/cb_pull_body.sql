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

end cb_pull;
/
