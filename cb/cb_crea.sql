-- users
-- -------
create table users (
    user_id number constraint pk_users primary key,
    lastname varchar2(63),
    firstname varchar2(63),
    creation_date date default current_date,
    backup_flag number(1) -- 1 = backed up, 0 = to backup
);
-- create sequence user_seq;
-- create or replace trigger user_autoinc
-- before insert on users
-- for each row begin
--     select user_seq.nextval into :new.user_id from dual;
-- end;

-- reviews
-- ---------
create table reviews (
    review_id number constraint pk_reviews primary key,
    user_id number constraint fk_reviews_user_id references users(user_id),
    movie_id number, --constraint fk_reviews_movie_id references movies(movie_id),
    rating number,
    creation_date date default current_date,
    content varchar2(511),
    backup_flag number(1)
);
-- create sequence review_seq;
-- create or replace trigger review_autoinc
-- before insert on reviews
-- for each row begin
--     select review_seq.nextval into :new.review_id from dual;
-- end;
