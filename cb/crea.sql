-- users
-- -------
create table users (
    username varchar2(63) constraint pk_users primary key,
    password varchar2(63) not null,
    lastname varchar2(63),
    firstname varchar2(63),
    creation_date date default current_date,
    backup_flag number(1, 0) -- 1 = backed up, 0 = to backup, 2 = to delete
);

-- actors
-- --------
create table actors (
    actor_id number(7, 0) constraint pk_actors primary key,
    actor_name varchar2(22),
    actor_profile_path varchar2(32)
);

-- certifications
-- --------
create table certifications (
    certification_id number(6, 0) constraint pk_certifications primary key,
    certification_name varchar2(9)
);

-- statuses
-- --------
create table statuses (
    status_id number(6, 0) constraint pk_statuses primary key,
    status_name varchar2(8)
);

-- spoken_languages
-- --------
create table spoken_languages (
    spoken_language_id varchar2(2) constraint pk_spoken_languages primary key,
    spoken_language_name varchar2(15)
);

-- production_countries
-- --------
create table production_countries (
    production_country_id varchar2(2) constraint pk_production_countries primary key,
    production_country_name varchar2(31)
);

-- production_companies
-- --------
create table production_companies (
    production_company_id number(5, 0) constraint pk_production_companies primary key,
    production_company_name varchar2(45)
);

-- directors
-- --------
create table directors (
    director_id number(7, 0) constraint pk_directors primary key,
    director_name varchar2(23),
    director_profile_path varchar2(32)
);

-- genres
-- --------
create table genres (
    genre_id number(5, 0) constraint pk_genres primary key,
    genre_name varchar2(16)
);

-- movies
-- --------
create table movies (
    movie_id number(6, 0) constraint pk_movies primary key,
    movie_title varchar2(58),
    movie_original_title varchar2(59),
    movie_release_date date,
    movie_status_id number(6, 0) constraint fk_movies_status_id references statuses(status_id),
    movie_certification_id number(6, 0) constraint fk_movies_certification_id references certifications(certification_id),
    movie_vote_avg number(2, 1),
    movie_vote_count number(4), -- TODO Check
    movie_runtime number(5), -- TODO Check
    movie_poster_path varchar2(32),
    movie_budget number(8, 0), -- TODO Check
    movie_revenue number(8, 0), -- TODO Check
    movie_homepage varchar2(112),
    movie_tagline varchar2(172),
    movie_overview clob
);

-- characters
-- --------
create table characters (
    movie_id number(6, 0) constraint fk_characters_movie_id references movies(movie_id),
    character_id number(4, 0),
    character_name varchar2(111),
    constraint pk_characters primary key (movie_id, character_id)
);

-- reviews
-- ---------
create table reviews (
    username varchar2(63) constraint fk_reviews_username references users(username),
    movie_id number(6, 0) constraint fk_reviews_movie_id references movies(movie_id),
    rating number(2, 0),
    creation_date date default current_date,
    content varchar2(511),
    backup_flag number(1, 0),
    constraint pk_reviews primary key (username, movie_id)
);

-- movies_actors_characters
-- --------
create table movies_actors_characters (
    movie_id number(6, 0) not null,
    character_id number(4, 0) not null,
    actor_id number(7, 0) constraint fk_mov_act_cha_actor_id references actors(actor_id),
    constraint pk_movies_actors_characters primary key (movie_id, character_id, actor_id),
    constraint fk_mov_act_cha_cha_pk foreign key (movie_id, character_id) references characters(movie_id, character_id)
);

-- movies_spoken_languages
-- --------
create table movies_spoken_languages (
    movie_id number(6, 0) constraint fk_mov_spo_lan_movie_id references movies(movie_id),
    spoken_language_id varchar2(2) constraint fk_mov_spo_lan_spo_language_id references spoken_languages(spoken_language_id),
    constraint pk_movies_spoken_languages primary key (movie_id, spoken_language_id)
);

-- movies_production_countries
-- --------
create table movies_production_countries (
    movie_id number(6, 0) constraint fk_mov_pro_cou_movie_id references movies(movie_id),
    production_country_id varchar2(2) constraint fk_mov_pro_cou_prod_country_id references production_countries(production_country_id),
    constraint pk_movies_production_countries primary key (movie_id, production_country_id)
);

-- movies_production_companies
-- --------
create table movies_production_companies (
    movie_id number(6, 0) constraint fk_mov_pro_com_movie_id references movies(movie_id),
    production_company_id number(5, 0) constraint fk_mov_pro_com_prod_company_id references production_companies(production_company_id),
    constraint pk_movies_production_companies primary key (movie_id, production_company_id)
);

-- movies_directors
-- --------
create table movies_directors (
    movie_id number(6, 0) constraint fk_mov_dir_movie_id references movies(movie_id),
    director_id number(7, 0) constraint fk_mov_dir_director_id references directors(director_id),
    constraint pk_movies_directors primary key (movie_id, director_id)
);

-- movies_genres
-- --------
create table movies_genres (
    movie_id number(6, 0) constraint fk_mov_gen_movie_id references movies(movie_id),
    genre_id number(5, 0) constraint fk_mov_gen_genre_id references genres(genre_id),
    constraint pk_movies_genres primary key (movie_id, genre_id)
);

exit
