create table movies of xmltype
xmltype store as object relational
xmlschema "http://xmlns.bendem.be/cc"
element "movie"
varray "XMLDATA"."actor"
    store as table actor_table ((primary key (nested_table_id, sys_nc_array_index$)))
varray "XMLDATA"."director"
    store as table director_table ((primary key (nested_table_id, sys_nc_array_index$)))
varray "XMLDATA"."production_company"
    store as table production_company_table ((primary key (nested_table_id, sys_nc_array_index$)))
varray "XMLDATA"."production_country"
    store as table production_country_table ((primary key (nested_table_id, sys_nc_array_index$)))
varray "XMLDATA"."genre"
    store as table genre_table ((primary key (nested_table_id, sys_nc_array_index$)))
varray "XMLDATA"."review"
    store as table review_table ((primary key (nested_table_id, sys_nc_array_index$)))
varray "XMLDATA"."spoken_language"
    store as table spoken_language_table ((primary key (nested_table_id, sys_nc_array_index$)))
varray "XMLDATA"."copy"
    store as table copy_table ((primary key (nested_table_id, sys_nc_array_index$)))
--  TODO FIX ME (Can't access child of child somehow)
--  varray "XMLDATA"."copy"."schedule"
--    store as table schedule_table ((primary key (nested_table_id, sys_nc_array_index$)))
;

alter table movies add constraint pk_movies primary key (XMLDATA."id");
