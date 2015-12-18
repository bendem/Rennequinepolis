drop table fact_turnover;
drop table fact_proportion;
drop table fact_rating;
drop table fact_popularity;
drop table fact_avg_rating_nationality;
drop table fact_running_days_nationality;
drop table dimension_time;
drop table dimension_period;
drop table dimension_countries;
drop table dimension_hall;
drop table dimension_genre;
drop table dimension_movie;

-- movie dimension
create table dimension_movie (
    movie number constraint pk_dimension_movie primary key
);

-- genre dimension
create table dimension_genre (
    genre varchar2(100) constraint pk_dimension_genre primary key
);

-- location dimension
create table dimension_hall (
    hall number,
    theater number,
    constraint pk_dimension_hall primary key (hall, theater)
);

create table dimension_countries (
    country varchar2(100) constraint pk_dimension_countries primary key
);


-- time dimension
create table dimension_period (
    period varchar2(100) constraint pk_dimension_period primary key
);

insert into dimension_period values ('morning');
insert into dimension_period values ('afternoon');
insert into dimension_period values ('evening');

create table dimension_time (
    time timestamp constraint pk_dimension_time primary key
);


create table fact_running_days_nationality (
    nationality varchar2(100) constraint fk_adimension_countries references dimension_countries(country),
    running_days number
);

create table fact_avg_rating_nationality (
    nationality varchar2(100) constraint fk_bdimension_countries references dimension_countries(country),
    average_rating number
);

create table fact_popularity (
    genre varchar2(100) constraint fk_adimension_genre references dimension_genre(genre),
    hall number,
    theater number,
    period varchar2(100) constraint fk_dimension_period references dimension_period(period),
    time timestamp constraint fk_adimension_time references dimension_time(time),
    popularity number,
    constraint fk_adimension_hall foreign key (hall, theater) references dimension_hall(hall, theater)
);

create table fact_rating (
    movie number constraint fk_fact_rating references dimension_movie(movie),
    running_days number,
    rating number
);

create table fact_proportion (
    hall  number,
    theater number,
    time timestamp constraint fk_bdimension_time references dimension_time(time),
    proportion number,
    constraint fk_bdimension_hall foreign key (hall, theater) references dimension_hall(hall, theater)
);

create table fact_turnover (
    genre  varchar2(100) constraint fk_bdimension_genre references dimension_genre(genre),
    time timestamp constraint fk_cdimension_time references dimension_time(time),
    country  varchar2(100) constraint fk_cdimension_countries references dimension_countries(country),
    turnover number
);
