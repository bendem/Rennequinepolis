create table logs (
    id       number(10, 0) constraint pk_logs primary key,
    severity varchar2(10) not null,
    message  varchar2(2000) not null,
    stack    varchar2(2000) not null,
    time     timestamp default current_timestamp not null
);

create sequence logs_seq;
create or replace trigger logs_autoinc
before insert on logs
for each row begin
    select logs_seq.nextval into :new.id from dual;
end;
/

create or replace package logging is

    procedure log(
        p_severity in logs.severity%type,
        p_message  in logs.message%type);

    procedure d(p_message in logs.message%type);
    procedure i(p_message in logs.message%type);
    procedure e(p_message in logs.message%type);

end logging;
/

create or replace package body logging is

    procedure log(
        p_severity in logs.severity%type,
        p_message  in logs.message%type)
    is
        pragma autonomous_transaction;
    begin
        insert into logs(severity, message, stack) values (p_severity, p_message, dbms_utility.format_call_stack);
        commit;
    end;

    procedure d(p_message in logs.message%type) is begin
        logging.log('debug', p_message);
    end;

    procedure i(p_message in logs.message%type) is begin
        logging.log('info', p_message);
    end;

    procedure e(p_message in logs.message%type) is begin
        logging.log('error', p_message);
    end;

end logging;
/
