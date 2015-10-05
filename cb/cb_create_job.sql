begin
    dbms_scheduler.drop_job(
        job_name        => 'job_async_backup'
    );
end;
/

begin
    dbms_scheduler.create_job(
        job_name        => 'job_async_backup',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'cb_thing.async_backup',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY;byhour=0; byminute=0; bysecond=0;',
        auto_drop       => FALSE,
        comments        => 'async_backup',
        enabled         => true
    );
end;
/

exit
