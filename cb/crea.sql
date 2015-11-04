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
    actor_name varchar2(22) not null,
    actor_profile_path varchar2(32)
);

-- certifications
-- --------
create table certifications (
    certification_id number(6, 0) constraint pk_certifications primary key,
    certification_name varchar2(9) not null,
    constraint certification_name_unique unique (certification_name)
);

create sequence certifications_seq;
create or replace trigger logs_autoinc
before insert on certifications
for each row begin
    select certifications_seq.nextval into :new.certification_id from dual;
end;
/

-- statuses
-- --------
create table statuses (
    status_id number(6, 0) constraint pk_statuses primary key,
    status_name varchar2(8) not null,
    constraint status_name_unique unique (status_name)
);

create sequence statuses_seq;
create or replace trigger logs_autoinc
before insert on statuses
for each row begin
    select statuses_seq.nextval into :new.status_id from dual;
end;
/

-- spoken_languages
-- --------
create table spoken_languages (
    spoken_language_id varchar2(2) constraint pk_spoken_languages primary key,
    spoken_language_name varchar2(15) not null
);

-- production_countries
-- --------
create table production_countries (
    production_country_id varchar2(2) constraint pk_production_countries primary key,
    production_country_name varchar2(31) not null
);

-- production_companies
-- --------
create table production_companies (
    production_company_id number(5, 0) constraint pk_production_companies primary key,
    production_company_name varchar2(45) not null
);

-- directors
-- --------
create table directors (
    director_id number(7, 0) constraint pk_directors primary key,
    director_name varchar2(23) not null,
    director_profile_path varchar2(32)
);

-- genres
-- --------
create table genres (
    genre_id number(5, 0) constraint pk_genres primary key,
    genre_name varchar2(16) not null
);

-- movies
-- --------
create table movies (
    movie_id number(6, 0) constraint pk_movies primary key,
    movie_title varchar2(58) not null,
    movie_original_title varchar2(59) not null,
    movie_release_date date,
    movie_status_id number(6, 0) constraint fk_movies_status_id references statuses(status_id),
    movie_certification_id number(6, 0) constraint fk_movies_certification_id references certifications(certification_id),
    movie_vote_avg number(2, 1) not null,
    movie_vote_count number(4) not null, -- TODO Check
    movie_runtime number(5), -- TODO Check
    movie_poster_path varchar2(32),
    movie_budget number(8, 0) not null, -- TODO Check
    movie_revenue number(8, 0) not null, -- TODO Check
    movie_homepage varchar2(112),
    movie_tagline varchar2(172),
    movie_overview clob
);

-- characters
-- --------
create table characters (
    movie_id number(6, 0) not null,
    character_id number(4, 0) not null,
    character_name varchar2(111) not null,
    constraint pk_characters primary key (movie_id, character_id),
    constraint fk_characters_movie_id foreign key (movie_id) references movies(movie_id)
);

-- reviews
-- ---------
create table reviews (
    username varchar2(63) not null,
    movie_id number(6, 0) not null,
    rating number(2, 0),
    creation_date date default current_date,
    content varchar2(511),
    backup_flag number(1, 0),
    constraint pk_reviews primary key (username, movie_id),
    constraint fk_reviews_movie_id foreign key (movie_id) references movies(movie_id),
    constraint fk_reviews_username foreign key (username) references users(username)
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
    movie_id number(6, 0) not null,
    spoken_language_id varchar2(2) constraint fk_mov_spo_lan_spo_language_id references spoken_languages(spoken_language_id),
    constraint pk_movies_spoken_languages primary key (movie_id, spoken_language_id),
    constraint fk_mov_spo_lan_movie_id foreign key (movie_id) references movies(movie_id)
);

-- movies_production_countries
-- --------
create table movies_production_countries (
    movie_id number(6, 0) not null,
    production_country_id varchar2(2) not null,
    constraint pk_movies_production_countries primary key (movie_id, production_country_id),
    constraint fk_mov_pro_cou_movie_id foreign key (movie_id) references movies(movie_id),
    constraint fk_mov_pro_cou_prod_country_id foreign key (production_country_id) references production_countries(production_country_id)
);

-- movies_production_companies
-- --------
create table movies_production_companies (
    movie_id number(6, 0) not null,
    production_company_id number(5, 0) not null,
    constraint pk_movies_production_companies primary key (movie_id, production_company_id),
    constraint fk_mov_pro_com_movie_id foreign key (movie_id) references movies(movie_id),
    constraint fk_mov_pro_com_prod_company_id foreign key (production_company_id) references production_companies(production_company_id)
);

-- movies_directors
-- --------
create table movies_directors (
    movie_id number(6, 0) not null,
    director_id number(7, 0) not null,
    constraint pk_movies_directors primary key (movie_id, director_id),
    constraint fk_mov_dir_movie_id foreign key (movie_id) references movies(movie_id),
    constraint fk_mov_dir_director_id foreign key (director_id) references directors(director_id)
);
-- movies_genres
-- --------
create table movies_genres (
    movie_id number(6, 0) not null,
    genre_id number(5, 0) not null,
    constraint pk_movies_genres primary key (movie_id, genre_id),
    constraint fk_mov_gen_movie_id foreign key (movie_id) references movies(movie_id),
    constraint fk_mov_gen_genre_id foreign key (genre_id) references genres(genre_id)
);

exit
