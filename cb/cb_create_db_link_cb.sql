-- use in cb
create database link link.backup connect to
cbb identified by &1 using 'xe';

exit
