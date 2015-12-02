create or replace package body link_check is

    procedure check_link_available
    is
        x tab.tname%type;
    begin
        select tname into x from tab@link.backup where rownum = 1;
        raise_application_error(20100, 'DB link is up');
    exception
        when others then
            if sqlcode = 20100 then
                backup.propagate_review_changes();
                backup.propagate_copy_changes();
                raise;
            end if;
    end;

end link_check;
/
