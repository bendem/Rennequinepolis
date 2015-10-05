-- users
-- -------
create table users (
    username varchar2(63) constraint pk_users primary key,
    password varchar2(63) not null,
    lastname varchar2(63),
    firstname varchar2(63),
    creation_date date default current_date,
    backup_flag number(1, 0) -- 1 = backed up, 0 = to backup
);

-- reviews
-- ---------
create table reviews (
    username varchar2(63) constraint fk_reviews_username references users(username),
    movie_id number(8, 0), --constraint fk_reviews_movie_id references movies(movie_id),
    rating number(2, 0),
    creation_date date default current_date,
    content varchar2(511),
    backup_flag number(1, 0),
    constraint pk_reviews primary key (username, movie_id)
);

exit
