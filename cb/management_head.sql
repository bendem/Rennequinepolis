create or replace package cb_management is

    -- Inserts a user into the db
    -- @param p_username  the user's username
    -- @param p_password  the user's password
    -- @param p_lastname  the user's last name
    -- @param p_firstname the user's first name
    procedure add_user(
        p_username  in users.username%type,
        p_password  in users.password%type,
        p_lastname  in users.lastname%type,
        p_firstname in users.firstname%type);

    -- Inserts a review into the db
    -- @param p_username the user's username
    -- @param p_movie_id the movie id
    -- @param p_rating   the rating
    -- @param p_content  the content
    procedure add_review(
        p_username in reviews.username%type,
        p_movie_id in reviews.movie_id%type,
        p_rating   in reviews.rating%type,
        p_content  in reviews.content%type);

    -- Marks a user for removal and removes all his reviews
    -- @param p_username the username of the user to delete
    procedure delete_user(
        p_username users.username%type);

    -- Removes the review of a user for a movie
    -- @param p_username the username of the user
    -- @param p_movie_id the movie id
    procedure delete_review(
        p_username in reviews.username%type,
        p_movie_id in reviews.movie_id%type);

    -- Modifies a user, checking if it has not been modified in the meantime
    -- @param p_userbefore the previous value of the user
    -- @param p_userafter  the new value for the user
    procedure modify_user(
        p_userbefore in users%rowtype,
        p_userafter  in users%rowtype);

    -- Modifies a review, checking if it has not been modified in the meantime
    -- @param p_reviewbefore the previous value of the review
    -- @param p_reviewafter  the new value for the review
    procedure modify_review(
        p_reviewbefore in reviews%rowtype,
        p_reviewafter  in reviews%rowtype);

end cb_management;
/
