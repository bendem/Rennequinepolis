create or replace package cc_proxy is

    -- Pulls the movies made available by cb into the database.
    procedure pull_movies;

    -- Pulls the copies made available by cb into the database.
    procedure pull_copies;

    -- Checks wether cc has information about a movie.
    -- @param p_movie_id the id of the movie to check for
    -- @return true if the movie is already known, false otherwise
    function movie_exists(
        p_movie_id number) return boolean;

    -- TODO
    procedure push_copies;

end cc_proxy;
/
