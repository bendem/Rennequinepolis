create or replace package utils is

    procedure check_size(
        var in out varchar2,
        size_var in number,
        size_max in number,
        remplacement in varchar2
    );

    procedure check_size(
        var in out varchar2,
        size_var in number,
        size_max in number
    );

    procedure check_size(
        var in out number,
        size_var in number,
        size_max in number,
        remplacement in number
    );

    procedure check_size(
        var in out number,
        size_var in number,
        size_max in number
    );

end utils;
/

create or replace package body utils is

    procedure check_size(
        var in out varchar2,
        size_var in number,
        size_max in number,
        remplacement in varchar2
    ) is
    v_before varchar2(2000);
    begin
        if var is not null then
            v_before := var;
            if length(var) > size_var then
                if length(var) > size_max then
                    var := remplacement;
                    logging.i('String "' || v_before || '"" too long. Replacing by : "' || coalesce(remplacement, '(null)' || '"'));
                else
                    var := substr(var, 1, size_var - 1) || '…';
                    logging.i('String too long. Truncating "' || v_before ||  '"" to : "' || var || '"');
                end if;
            end if;
        else
            logging.i('String is null. Replacing by : "' || coalesce(remplacement, '(null)' ) || '"');
            var := remplacement;
        end if;
    exception
        when others then
            dbms_output.put_line(sqlerrm);
            dbms_output.put_line(dbms_utility.format_call_stack);
            dbms_output.put_line(dbms_utility.format_error_backtrace);
            rollback;
            raise;
    end;

    procedure check_size(
        var in out varchar2,
        size_var in number,
        size_max in number
    ) is begin
        check_size(var, size_var, size_max, 'undefined');
    exception
        when others then
            dbms_output.put_line(sqlerrm);
            dbms_output.put_line(dbms_utility.format_call_stack);
            dbms_output.put_line(dbms_utility.format_error_backtrace);
            rollback;
            raise;
    end;

    procedure check_size(
        var in out number,
        size_var in number,
        size_max in number,
        remplacement in number
    ) is
    v_before number;
    begin
        if var is not null then
            v_before := var;
            if length(var) > size_var then
                if length(var) > size_max then
                    var := remplacement;
                    logging.i('Number "' || v_before || '"" too long. Replacing by : "' || coalesce(remplacement, '(null)' || '"'));
                else
                    var := substr(var, 1, size_var);
                    logging.i('Number too long. Truncating "' || v_before ||  '"" to : "' || var || '"');
                end if;
            end if;
        else
            logging.i('Number is null. Replacing by : "' || coalesce(remplacement, '(null)')  || '"');
            var := remplacement;
        end if;
    exception
        when others then
            dbms_output.put_line(sqlerrm);
            dbms_output.put_line(dbms_utility.format_call_stack);
            dbms_output.put_line(dbms_utility.format_error_backtrace);
            rollback;
            raise;
    end;

    procedure check_size(
        var in out number,
        size_var in number,
        size_max in number
    ) is begin
        check_size(var, size_var, size_max, 0);
    exception
        when others then
            dbms_output.put_line(sqlerrm);
            dbms_output.put_line(dbms_utility.format_call_stack);
            dbms_output.put_line(dbms_utility.format_error_backtrace);
            rollback;
            raise;
    end;

end utils;
/
