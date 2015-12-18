drop table schedules;
drop table halls;
drop table theaters;
drop table movies_production_countries;
drop table movies_genres;
drop table movies_actors;
drop table movies;
drop table production_countries;
drop table genres;
drop table actors;

-- actors
-- ------
create table actors (
    actor_id number(7, 0) constraint pk_actors primary key,
    name varchar2(23 char) not null,
    nationality varchar2(23 char) not null
);

-- genres
-- ------
create table genres (
    genre_id number(7, 0) constraint pk_genres primary key,
    name varchar2(23 char) not null
);

-- production_countries
-- --------------------
create table production_countries (
    production_country_id number(7, 0) constraint pk_production_countries primary key,
    name varchar2(23 char) not null
);

-- movies
-- ------
create table movies (
    movie_id number(6, 0) constraint pk_movies primary key,
    movie_title varchar2(58 char) not null,
    movie_vote_avg number(3, 1) not null
);


-- movies_actors
-- -------------
create table movies_actors (
    movie_id number(6, 0) not null,
    actor_id number(7, 0) not null,
    constraint pk_movies_actors primary key (movie_id, actor_id),
    constraint fk_amovie_id foreign key (movie_id) references movies(movie_id),
    constraint fk_aactor_id foreign key (actor_id) references actors(actor_id)
);

-- movies_genres
-- -------------
create table movies_genres (
    movie_id number(6, 0) not null,
    genre_id number(7, 0) not null,
    constraint pk_movies_genres primary key (movie_id, genre_id),
    constraint fk_gmovie_id foreign key (movie_id) references movies(movie_id),
    constraint fk_ggenre_id foreign key (genre_id) references genres(genre_id)
);

-- movies_production_countries
-- -------------
create table movies_production_countries (
    movie_id number(6, 0) not null,
    production_country_id number(7, 0) not null,
    constraint pk_movies_production_countries primary key (movie_id, production_country_id),
    constraint fk_pmovie_id foreign key (movie_id) references movies(movie_id),
    constraint fk_pproduction_country_id foreign key (production_country_id) references production_countries(production_country_id)
);

-- theaters
-- --------
create table theaters (
    theater_id number(6, 0) constraint pk_theaters primary key
);

-- halls
-- -----
create table halls (
    hall_id number(6, 0),
    theater_id number(6, 0),
    number_places number(4, 0),
    constraint pk_halls primary key (hall_id, theater_id),
    constraint fk_theater_id foreign key (theater_id) references theaters(theater_id)
);

-- schedules
-- ---------
create table schedules (
    schedule_id number(6, 0) constraint pk_schedules primary key,
    movie_id number(6, 0),
    hall_id number(6, 0),
    theater_id number(6, 0),
    showing_time timestamp,
    number_occupied number(4, 0),
    constraint fk_sch_movie_id foreign key (movie_id) references movies(movie_id),
    constraint fk_sch_hall_id foreign key (hall_id, theater_id) references halls(hall_id, theater_id)
);
