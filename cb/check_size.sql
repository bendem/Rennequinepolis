create or replace function is_number (p_string in varchar2)
   return int
is
   v_new_num number;
begin
   v_new_num := to_number(p_string);
   return 1;
exception
when value_error then
   return 0;
end is_number;
/

create or replace procedure check_size (var in out varchar2, size_var in number, size_max in number) is
begin
    if length(var) > size_var then
        if length(var) > size_max then
            var := null;
            -- LOG
        else
            if is_number(var) = 1 then
                var := substr(var, 1, size_var);
                -- LOG
            else
                var := substr(var, 1, size_var - 1) || '…';
                -- LOG
            end if;
        end if;
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
