-- users
-- -------
create table users (
    username varchar2(63 char) constraint pk_users primary key,
    password varchar2(63 char) not null,
    lastname varchar2(63 char),
    firstname varchar2(63 char),
    creation_date date default current_date,
    backup_flag number(1, 0) -- 1 = backed up, 0 = to backup, 2 = to delete
);

-- images
-- --------

create table images (
    image_id number(6, 0) constraint pk_images primary key,
    image_path varchar2(32 char) not null,
    image blob default empty_blob(),
    constraint image_path_unique unique (image_path)
);

-- people
-- --------
create table people (
    person_id number(7, 0) constraint pk_people primary key,
    person_name varchar2(23 char) not null,
    person_profile_id number(6, 0) constraint fk_people_profile_id references images(image_id)
);

-- certifications
-- --------
create table certifications (
    certification_id number(6, 0) constraint pk_certifications primary key,
    certification_name varchar2(9 char) not null,
    constraint certification_name_unique unique (certification_name)
);

-- statuses
-- --------
create table statuses (
    status_id number(6, 0) constraint pk_statuses primary key,
    status_name varchar2(8 char) not null,
    constraint status_name_unique unique (status_name)
);

-- spoken_languages
-- --------
create table spoken_languages (
    spoken_language_id varchar2(2 char) constraint pk_spoken_languages primary key,
    spoken_language_name varchar2(15 char)
);

-- production_countries
-- --------
create table production_countries (
    production_country_id varchar2(2 char) constraint pk_production_countries primary key,
    production_country_name varchar2(31 char)
);

-- production_companies
-- --------
create table production_companies (
    production_company_id number(5, 0) constraint pk_production_companies primary key,
    production_company_name varchar2(45 char) not null
);

-- genres
-- --------
create table genres (
    genre_id number(5, 0) constraint pk_genres primary key,
    genre_name varchar2(16 char) not null
);

-- movies
-- --------
create table movies (
    movie_id number(6, 0) constraint pk_movies primary key,
    movie_title varchar2(58 char) not null,
    movie_original_title varchar2(59 char) not null,
    movie_release_date date,
    movie_status_id number(6, 0) constraint fk_movies_status_id references statuses(status_id),
    movie_certification_id number(6, 0) constraint fk_movies_certification_id references certifications(certification_id),
    movie_vote_avg number(3, 1) not null,
    movie_vote_count number(4) not null,
    movie_runtime number(5),
    movie_poster_id number(6, 0) constraint fk_movies_image_id references images(image_id),
    movie_budget number(9, 0) not null,
    movie_revenue number(10, 0) not null,
    movie_homepage varchar2(122 char),
    movie_tagline varchar2(172 char),
    movie_overview clob,
    movie_copies number(4, 0),
    backup_flag number(1, 0),
    constraint ck_vote_avg_pos check (movie_vote_avg >= 0),
    constraint ck_vote_count_pos check (movie_vote_count >= 0),
    constraint ck_runtime_pos check (movie_runtime >= 0),
    constraint ck_budget_pos check (movie_budget >= 0),
    constraint ck_revenue_pos check (movie_revenue >= 0),
    constraint ck_copies_pos check (movie_copies >= 0)
);

-- copies
-- --------
create table copies (
    movie_id number(6, 0) not null,
    copy_id number(4, 0) not null,
    backup_flag number(1, 0),
    constraint pk_copies primary key (movie_id, copy_id),
    constraint fk_copies_movies_id foreign key (movie_id) references movies(movie_id)
);

-- characters
-- --------
create table characters (
    movie_id number(6, 0) not null,
    character_id number(4, 0) not null,
    person_id number(7, 0) not null,
    character_name varchar2(111 char) not null,
    constraint pk_characters primary key (movie_id, character_id),
    constraint fk_characters_movie_id foreign key (movie_id) references movies(movie_id),
    constraint fk_characters_person_id foreign key (person_id) references people(person_id)
);

-- reviews
-- ---------
create table reviews (
    username varchar2(63 char) not null,
    movie_id number(6, 0) not null,
    rating number(2, 0),
    creation_date date default current_date,
    content varchar2(511 char),
    backup_flag number(1, 0),
    constraint pk_reviews primary key (username, movie_id),
    constraint fk_reviews_movie_id foreign key (movie_id) references movies(movie_id),
    constraint fk_reviews_username foreign key (username) references users(username),
    constraint ck_rating_pos check (rating >= 0)
);

-- movies_spoken_languages
-- --------
create table movies_spoken_languages (
    movie_id number(6, 0) not null,
    spoken_language_id varchar2(2 char) not null,
    constraint pk_movies_spoken_languages primary key (movie_id, spoken_language_id),
    constraint fk_mov_spo_lan_movie_id foreign key (movie_id) references movies(movie_id),
    constraint fk_mov_spo_lan_spo_language_id foreign key (spoken_language_id) references spoken_languages(spoken_language_id)
);

-- movies_production_countries
-- --------
create table movies_production_countries (
    movie_id number(6, 0) not null,
    production_country_id varchar2(2 char) not null,
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
    person_id number(7, 0) not null,
    constraint pk_movies_directors primary key (movie_id, person_id),
    constraint fk_mov_dir_movie_id foreign key (movie_id) references movies(movie_id),
    constraint fk_mov_dir_person_id foreign key (person_id) references people(person_id)
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
