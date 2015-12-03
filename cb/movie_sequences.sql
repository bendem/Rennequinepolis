create sequence images_seq;
create or replace trigger images_autoinc
before insert on images
for each row begin
    select images_seq.nextval into :new.image_id from dual;
end;
/

create sequence certifications_seq;
create or replace trigger certifications_autoinc
before insert on certifications
for each row begin
    select certifications_seq.nextval into :new.certification_id from dual;
end;
/

create sequence statuses_seq;
create or replace trigger statuses_autoinc
before insert on statuses
for each row begin
    select statuses_seq.nextval into :new.status_id from dual;
end;
/

