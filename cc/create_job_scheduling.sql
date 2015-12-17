begin
    dbms_scheduler.create_job(
        job_name        => 'job_scheduling',
        job_type        => 'stored_procedure',
        job_action      => 'scheduling.read_file',
        start_date      => systimestamp,
        repeat_interval => 'freq=daily; byhour=0; byminute=0; bysecond=0;',
        auto_drop       => false,
        comments        => 'daily scheduling of movies',
        enabled         => true
    );
end;
/

-- Drop it with
-- execute dbms_scheduler.drop_job('job_scheduling');
