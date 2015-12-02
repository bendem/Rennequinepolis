create or replace package body link_check is

    procedure check_link_available
    is
        x tab.tname%type;
    begin
        select tname into x from tab@link.backup where rownum = 1;
        raise_application_error(20100, 'DB link is up');
    exception
        when others then
            null;
    end;

end link_check;
/
