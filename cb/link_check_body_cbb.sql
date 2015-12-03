create or replace package body link_check is

    procedure check_link_available
    is
        x tab.tname%type;
        dbup exception;
    begin
        select tname into x from tab@link.backup where rownum = 1;
        Logging.d('CB is back up');
        backup.sync_propagation;
        raise dbup;
    exception
        when dbup then
            raise_application_error(-20100, 'CB db link is back up');
        when others then
            null;
    end;

end link_check;
/
