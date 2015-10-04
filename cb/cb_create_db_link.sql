-- Use in CB
create database link link.backup connect to
CBB identified by dummy using 'xe';

-- Use in CBB
create database link link.backup connect to
CB identified by dummy using 'xe';
