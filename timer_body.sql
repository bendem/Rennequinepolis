create or replace package body timer is

    m_start timestamp;

    procedure init is
    begin
        select current_timestamp into m_start from dual;
    end;

    function lap return interval day to second is
        now timestamp;
    begin
        select current_timestamp into now from dual;
        return now - m_start;
    end;

    function restart return interval day to second is
        now timestamp;
        i   interval day to second;
    begin
        select current_timestamp into now from dual;
        i := now - m_start;
        m_start := now;
        return i;
    end;

end timer;
/
