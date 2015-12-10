create or replace package link_check is

    -- Checks wether cb is back up and raises 20100 that applications
    -- should handle by retrying the request on cb.
    --
    -- Calling this procedure on cb has no effect.
    procedure check_link_available;

end link_check;
/
