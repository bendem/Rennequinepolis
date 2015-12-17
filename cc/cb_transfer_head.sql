create or replace package cb_transfer is

    -- Pulls the movies made available by cb into the database.
    procedure pull_movies;

    -- Pulls the copies made available by cb into the database.
    procedure pull_copies;

    -- Checks wether cc has information about a movie.
    -- @param p_movie_id the id of the movie to check for
    -- @return true if the movie is already known, false otherwise
    function movie_exists(
        p_movie_id number) return boolean;

    -- Pushes copies that are not scheduled anymore back to cb.
    -- @transaction this method will commit on success and rollback on error
    -- @autonomous_transaction
    procedure push_copies;

end cb_transfer;
/
