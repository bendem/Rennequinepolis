begin
    dbms_scheduler.create_job(
        job_name        => 'alim_dw',
        job_type        => 'stored_procedure',
        job_action      => 'dw_alim.load_all',
        start_date      => systimestamp,
        repeat_interval => 'freq=daily;byhour=0; byminute=0; bysecond=0;',
        auto_drop       => false,
        comments        => 'alim dw',
        enabled         => true
    );
end;
/
