begin
    dbms_scheduler.create_job(
        job_name        => 'job_async_backup',
        job_type        => 'stored_procedure',
        job_action      => 'backup.do_the_thing',
        start_date      => systimestamp,
        repeat_interval => 'freq=daily;byhour=0; byminute=0; bysecond=0;',
        auto_drop       => false,
        comments        => 'async_backup',
        enabled         => true
    );
end;
/

-- Drop it with
-- execute dbms_scheduler.drop_job('job_async_backup');
