create database link link.cb connect to
    cb identified by &cb_pwd using 'xe';

create database link link.cbb connect to
    cbb identified by &cb_pwd using 'xe';
