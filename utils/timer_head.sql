create or replace package timer is

    function init    return timestamp;
    function lap     return interval day to second;
    function restart return interval day to second;
    function total   return interval day to second;

end timer;
/

exit
