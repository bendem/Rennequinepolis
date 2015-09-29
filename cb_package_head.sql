-- fk_exception: 20001

create or replace package cb_thing is

    -- types
    -- -------

    -- example
    -- type emppro_t is table of emppro%rowtype index by pls_integer;

    -- methods
    -- ---------

    -- Inserts a user into the db
    -- @param lastname the user's last name
    -- @param firstname the user's first name
    procedure add_user(
        lastname  users.lastname%type,
        firstname users.firstname%type
    );

    -- Inserts a review into the db
    -- @param user_id       the user id
    -- @param movie_id      the movie id
    -- @param rating        the rating
    -- @param creation_date the creation date
    -- @param content       the content
    procedure add_user(
        user_id       reviews.user_id%type,
        movie_id      reviews.movie_id%type,
        rating        reviews.rating%type,
        creation_date reviews.creation_date%type,
        content       reviews.content%type
    );

    -- Synchonizes the db with it's backup counter part
    procedure async_backup();

end cb_thing;
