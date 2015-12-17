create or replace package cc_alim is

    -- Sends a random amount of the copies in cb to cc.
    --
    -- This method will also trigger the process on cc to send unused copies back.
    -- @transaction this method will commit on success and rollback on error
    procedure send_copies_of_all;

    -- Send copies of a specific movie to CC
    -- @param Id of the movie'd copies to send
    procedure send_copies(
        p_id movies.movie_id%type);

    -- Send a movie and all it's related information to CC
    -- @param Id of the movie to send
    procedure send_movie(
        p_id movies.movie_id%type);

end cc_alim;
/
