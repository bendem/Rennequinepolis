create database link link.backup connect to
    cbb identified by &cbb_pwd using 'xe';

create database link link.cc connect to
    cc identified by &cc_pwd using 'xe';
