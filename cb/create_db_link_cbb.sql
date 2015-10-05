-- use in cbb
create database link link.backup connect to
cb identified by &1 using 'xe';

exit
