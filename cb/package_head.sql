create or replace package cb_thing is

    -- types
    -- -------

    -- example
    -- type emppro_t is table of emppro%rowtype index by pls_integer;

    -- methods
    -- ---------

    -- Inserts a user into the db
    -- @param lastname  the user's last name
    -- @param firstname the user's first name
    procedure add_user(
        p_username  users.username%type,
        p_password  users.password%type,
        p_lastname  users.lastname%type,
        p_firstname users.firstname%type
    );

    -- Inserts a review into the db
    -- @param username the user's username
    -- @param movie_id the movie id
    -- @param rating   the rating
    -- @param content  the content
    procedure add_review(
        p_username reviews.username%type,
        p_movie_id reviews.movie_id%type,
        p_rating   reviews.rating%type,
        p_content  reviews.content%type
    );

    -- Synchonizes the db with it's backup counter part
    procedure async_backup;

end cb_thing;
/

exit
