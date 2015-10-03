-- Use in CB
create database link link.backup connect to
CBB identified by dummy using 'xe'; -- Change xe to final database handle added in TNSNAME.ORA

-- Use in CBB
create database link link.backup connect to
CB identified by dummy using 'xe'; -- Change xe to final database handle added in TNSNAME.ORA
