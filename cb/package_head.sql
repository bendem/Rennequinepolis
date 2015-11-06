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

    -- Marks a user for removal and removes all his reviews
    -- @param username the username of the user to delete
    procedure delete_user(
        p_username  users.username%type
    );

    -- Removes the review of a user for a movie
    -- @param username the username of the user
    -- @param movie_id the movie id
    procedure delete_review(
        p_username reviews.username%type,
        p_movie_id reviews.movie_id%type
    );

    procedure modify_user(
        p_userbefore in users%rowtype,
        p_userafter  in users%rowtype
    );

    procedure modify_review(
        p_reviewbefore in reviews%rowtype,
        p_reviewafter  in reviews%rowtype
    );

end cb_thing;
/
