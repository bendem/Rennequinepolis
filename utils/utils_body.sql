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

    function split(
        p_string in varchar2,
        p_separator in varchar2) return varchar2_t
    is
        r varchar2_t  := varchar2_t();

        len_str       pls_integer := length(p_string);
        len_sep       pls_integer := length(p_separator);
        last_index    pls_integer := 1;
        current_index pls_integer;
    begin
        while last_index < len loop
            current_index := instr(p_string, p_separator, last_index);
            if current_index = 0 then
                current_index := len + 1;
            end if;

            r.extend;
            r(r.count) := substr(p_string, last_index, current_index - last_index);
            last_index := current_index + len_sep;
        end loop;
        return r;
    end;

end utils;
/
