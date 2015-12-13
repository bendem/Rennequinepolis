begin
    dbms_scheduler.create_job(
        job_name        => 'job_alim_cc',
        job_type        => 'stored_procedure',
        job_action      => 'cc_alim.send_copies_of_all',
        start_date      => systimestamp,
        repeat_interval => 'freq=weekly; byhour=0; byminute=0; bysecond=0;',
        auto_drop       => false,
        comments        => 'weekly provisioning of copies to cc',
        enabled         => true
    );
end;
/

-- Drop it with
-- execute dbms_scheduler.drop_job('job_alim_cc');
