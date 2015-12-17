create or replace package movie_alim is

    -- Inserts a set amount of movies from movies_ext into the main database.
    --
    -- This method will also trigger sending movies to cc.
    -- @param p_count the number of movies to transfer
    -- @transaction this method will commit on success and rollback on error
    procedure insert_movies(
        p_count pls_integer);

    -- Inserts a movies_ext row into the main database
    -- @param p_movie the rowtype to decompose and insert
    -- @transaction this method will commit on success and rollback on error
    procedure insert_movie(
        p_movie movies_ext%rowtype);

    -- Checks wether sql%bulk_exceptions contains another exception code than
    -- the one provided.
    -- @param p_error the error code to ignore in sql%bulk_exceptions
    -- @return true if sql%bulk_exceptions contained another error code than
    --         the one provided
    function exceptions_contains_not(
        p_error pls_integer) return boolean;

end movie_alim;
/
