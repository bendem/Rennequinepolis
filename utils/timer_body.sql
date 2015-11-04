create or replace package body timer is

    m_start       timestamp;
    m_current_lap timestamp;

    function init return timestamp is
    begin
        select current_timestamp into m_start from dual;
        m_current_lap := m_start;
        return m_start;
    end;

    function lap return interval day to second is
        now timestamp;
        i   interval day to second;
    begin
        select current_timestamp into now from dual;
        i := now - m_current_lap;
        m_current_lap := now;
        return i;
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

    function total return interval day to second is
        now timestamp;
    begin
        select current_timestamp into now from dual;
        return now - m_start;
    end;

end timer;
/

exit
