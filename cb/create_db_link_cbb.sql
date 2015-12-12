create database link link.backup connect to
    cb identified by &cb_pwd using 'xe';

create database link link.cc connect to
    cc identified by &cb_pwd using 'xe';
