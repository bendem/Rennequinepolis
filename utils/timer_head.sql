create or replace package timer is

    -- Starts the timer.
    procedure init;

    -- Starts a new lap, returning the start of the previous one.
    function lap     return interval day to second;

    -- Restarts the timer, returning the start value.
    function restart return interval day to second;

    -- Returns the interval between now the the last call to init/restart.
    function total   return interval day to second;

end timer;
/
