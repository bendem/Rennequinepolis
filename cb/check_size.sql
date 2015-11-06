create or replace procedure check_size_varchar(
    var in out varchar2,
    size_var in number,
    size_max in number
) is
begin
    if var is not null then
        if length(var) > size_var then
            if length(var) > size_max then
                var := null;
                -- LOG
            else
                var := substr(var, 1, size_var - 1) || '…';
                -- LOG
            end if;
        end if;
    else
        var := '(undefined)';
    end if;
exception
    when others then
        dbms_output.put_line(sqlerrm);
        dbms_output.put_line(dbms_utility.format_call_stack);
        dbms_output.put_line(dbms_utility.format_error_backtrace);
        rollback;
        raise;
end;
/

create or replace procedure check_size_number(
    var in out number,
    size_var in number,
    size_max in number
) is
begin
    if var is not null then
        if length(var) > size_var then
            if length(var) > size_max then
                var := null;
                -- LOG
            else
                var := substr(var, 1, size_var);
                -- LOG
            end if;
        end if;
    else
        var := 0;
    end if;
exception
    when others then
        dbms_output.put_line(sqlerrm);
        dbms_output.put_line(dbms_utility.format_call_stack);
        dbms_output.put_line(dbms_utility.format_error_backtrace);
        rollback;
        raise;
end;
/

exit
