begin
    dbms_scheduler.create_job(
        job_name        => 'job_archiving',
        job_type        => 'stored_procedure',
        job_action      => 'archive.archive',
        start_date      => systimestamp,
        repeat_interval => 'freq=daily; byhour=0; byminute=0; bysecond=0;',
        auto_drop       => false,
        comments        => 'daily archiving of scheduled movies',
        enabled         => true
    );
end;
/

-- Drop it with
-- execute dbms_scheduler.drop_job('job_archiving');
