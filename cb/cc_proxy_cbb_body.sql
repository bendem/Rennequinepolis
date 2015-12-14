create or replace package cc_proxy is

    procedure pull_movies
    is
    begin
        cbb_transfer.pull_movies@link.cc;
    end;

    procedure pull_copies
    is
    begin
        cbb_transfer.pull_copies@link.cc;
    end;

    function movie_exists(
        p_movie_id number) return boolean
    is
    begin
        return cbb_transfer.movie_exists@link.cc(p_movie_id);
    end;

    procedure push_copies
    is
    begin
        cbb_transfer.push_copies@link.cc;
    end;

end cc_proxy;
/
