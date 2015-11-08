create or replace package body utils is

    procedure check_size(
        p_var         in out varchar2,
        p_size_var    in pls_integer,
        p_size_max    in pls_integer,
        p_replacement in varchar2)
    is
        v_before varchar2(2000);
    begin
        if p_var is null then
            logging.i('String is null. Replacing by : "' || coalesce(p_replacement, '(null)') || '"');
            p_var := p_replacement;
            return;
        end if;

        v_before := p_var;
        if length(p_var) > p_size_var then
            if length(p_var) > p_size_max then
                p_var := p_replacement;
                logging.i('String "' || v_before || '"" too long. Replacing by : "'
                    || coalesce(p_replacement, '(null)' || '"'));
            else
                p_var := substr(p_var, 1, p_size_var - 1) || '…';
                logging.i('String too long. Truncating "' || v_before ||  '"" to : "' || p_var || '"');
            end if;
        end if;
    end;

    procedure check_size(
        p_var         in out number,
        p_size_var    in pls_integer,
        p_size_max    in pls_integer,
        p_replacement in number)
    is
        v_before number;
    begin
        if p_var is null then
            logging.i('Number is null. Replacing by : "' || coalesce(p_replacement, '(null)')  || '"');
            p_var := p_replacement;
            return;
        end if;

        v_before := p_var;
        if length(p_var) > p_size_var then
            if length(p_var) > p_size_max then
                p_var := p_replacement;
                logging.i('Number "' || v_before || '"" too long. Replacing by : "'
                    || coalesce(p_replacement, '(null)' || '"'));
            else
                p_var := substr(p_var, 1, p_size_var);
                logging.i('Number too long. Truncating "' || v_before ||  '"" to : "' || p_var || '"');
            end if;
        end if;
    end;

end utils;
/
