create or replace type number_t is table of number;
/

create or replace type varchar2_t is table of varchar2(4000);
/

create or replace type copy_r is object(
    movie_id number(6, 0),
    copy_id  number(4, 0)
);
/

create or replace type copies_t is table of copy_r;
/
