create or replace package cb_pull is

    -- Pulls the movies made available by cb into the database.
    procedure pull_movies;

    -- Pulls the copies made available by cb into the database.
    procedure pull_copies;

end cb_pull;
/
