drop table logs;
create table logs (
    log_id   number(10, 0) constraint pk_logs primary key,
    message  varchar2(127),
    log_time timestamp default current_timestamp
);

drop sequence logs_seq;
create sequence logs_seq;
create or replace trigger logs_autoinc
before insert on logs
for each row begin
    select logs_seq.nextval into :new.log_id from dual;
end;
/

create or replace procedure insert_log(
    p_message in logs.message%type
) is
    pragma autonomous_transaction;
begin
    insert into logs(message) values (p_message);
    commit;
end;
/

exit
