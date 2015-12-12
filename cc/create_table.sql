create table movies of xmltype
xmltype store as object relational
xmlschema "http://xmlns.bendem.be/cc"
element "movie"
varray "XMLDATA"."actor" store as table actor_table (
    (primary key (nested_table_id, sys_nc_array_index$))
)
varray "XMLDATA"."director" store as table director_table (
    (primary key (nested_table_id, sys_nc_array_index$))
)
varray "XMLDATA"."production_company" store as table production_company_table (
    (primary key (nested_table_id, sys_nc_array_index$))
)
varray "XMLDATA"."production_country" store as table production_country_table (
    (primary key (nested_table_id, sys_nc_array_index$))
)
varray "XMLDATA"."genre" store as table genre_table (
    (primary key (nested_table_id, sys_nc_array_index$))
)
varray "XMLDATA"."review" store as table review_table (
    (primary key (nested_table_id, sys_nc_array_index$))
)
varray "XMLDATA"."spoken_language" store as table spoken_language_table (
    (primary key (nested_table_id, sys_nc_array_index$))
)
;

create table copies of xmltype
xmltype store as object relational
xmlschema "http://xmlns.bendem.be/cc"
element "copy";

create table schedules of xmltype
xmltype store as object relational
xmlschema "http://xmlns.bendem.be/cc"
element "schedule"
varray "XMLDATA"."time_schedule" store as table time_schedule_table (
    (primary key (nested_table_id, sys_nc_array_index$))
)
;

alter table movies add constraint pk_movies primary key (XMLDATA."id");
alter table copies add constraint pk_copies primary key (XMLDATA."copy_id", XMLDATA."movie_id");
alter table schedules add constraint pk_schedules primary key (XMLDATA."copy_id", XMLDATA."movie_id");
alter table copies add constraint fk_copies foreign key (XMLDATA."movie_id") references movies(XMLDATA."id");
alter table schedules add constraint fk_schedules foreign key (XMLDATA."movie_id") references movies(XMLDATA."id");
