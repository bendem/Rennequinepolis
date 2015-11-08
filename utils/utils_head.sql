create or replace package utils is

    -- Checks the size of a variable, elliding or replacing its value depending
    -- on its length.
    -- @param p_var         the variable to check
    -- @param p_size_var    the size making the variable subject to ellision
    -- @param p_size_max    the size making the variable subject to p_replacement
    -- @param p_replacement the value replacing the variable if its length is greater
    --                      than p_size_max
    procedure check_size(
        p_var in out varchar2,
        p_size_var in pls_integer,
        p_size_max in pls_integer,
        p_replacement in varchar2 default 'undefined');

    -- See above
    procedure check_size(
        p_var in out number,
        p_size_var in pls_integer,
        p_size_max in pls_integer,
        p_replacement in number default 0);

end utils;
/
