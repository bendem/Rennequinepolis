-- use in cbb
create database link link.backup connect to
cb identified by &cb_pwd using 'xe';
