create or replace package body link_check is

    procedure check_link_available
    is
    begin
        -- This procedure does nothing on cb side, hopefully it's
        -- optimized away by the engine.
        null;
    end;

end link_check;
/
