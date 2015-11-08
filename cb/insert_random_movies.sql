create or replace procedure insert_random_movies(n in number) is

    type table_record_t is table of movies_ext%rowtype index by pls_integer;

    movies table_record_t;

    cursor query is
        select * from movies_ext order by dbms_random.value;
begin

    open query;

    for i in 1..n loop
        fetch query into movies(i);
    end loop;

    for i in movies.first..movies.last loop
        insert_movie(movies(i));
    end loop;

    close query;

exception
    when others then
        if query%isopen then
            close query;
        end if;
        dbms_output.put_line(sqlerrm);
        dbms_output.put_line(dbms_utility.format_call_stack);
        dbms_output.put_line(dbms_utility.format_error_backtrace);
        rollback;
        raise;
end;
/
