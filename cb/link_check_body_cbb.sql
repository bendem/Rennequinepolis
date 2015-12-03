create or replace package body link_check is

    procedure check_link_available
    is
        dbup exception;
        x tab.tname%type;
    begin
        select tname into x from tab@link.backup where rownum = 1;
        raise dbup;
    exception
        when dbup then
            Logging.i('Starting restore');
            execute immediate 'alter trigger backup_reviews_trigger enable';
            execute immediate 'alter trigger backup_copies_trigger enable';
            -- FIXME This should not happen in the current transaction
            backup.propagate_review_changes();
            backup.propagate_copy_changes();
            -- commit;
            Logging.i('End of restore');
            raise_application_error(-20100, 'DB link is up');
        when others then
            Logging.i('CB Down');
            execute immediate 'alter trigger backup_reviews_trigger disable';
            execute immediate 'alter trigger backup_copies_trigger disable';
    end;

end link_check;
/
