create or replace package utils is

    procedure check_size(
        var in out varchar2,
        size_var in pls_integer,
        size_max in pls_integer,
        remplacement in varchar2 default 'undefined'
    );

    procedure check_size(
        var in out number,
        size_var in pls_integer,
        size_max in pls_integer,
        remplacement in number default 0
    );

end utils;
/

create or replace package body utils is

    procedure check_size(
        var in out varchar2,
        size_var in pls_integer,
        size_max in pls_integer,
        remplacement in varchar2
    ) is
        v_before varchar2(2000);
    begin
        if var is null then
            logging.i('String is null. Replacing by : "' || coalesce(remplacement, '(null)' ) || '"');
            var := remplacement;
            return;
        end if;

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
    end;

    procedure check_size(
        var in out number,
        size_var in pls_integer,
        size_max in pls_integer,
        remplacement in number
    ) is
        v_before number;
    begin
        if var is null then
            logging.i('Number is null. Replacing by : "' || coalesce(remplacement, '(null)')  || '"');
            var := remplacement;
            return;
        end if;

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
    end;

end utils;
/
