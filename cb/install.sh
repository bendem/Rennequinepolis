#!/bin/sh
# Usage:
#   CB_IP=<ip[:<port>]> ./install.sh <sys_pwd> <cb_pwd>
ROOT=`dirname \`realpath $0\``

if [ $# -ne 2 ]; then
    echo
    echo ' Needs exactly 2 args'
    echo
    echo ' Usage:'
    echo '  CB_IP=<ip[:<port>]> ./install.sh <sys_pwd> <cb_pwd>'
    echo
    exit 1
fi

if [ "$CB_IP" == "" ]; then
    echo
    echo ' CB_IP not provided'
    echo
    exit 2
fi

SYS_PWD=$1
CB_PWD=$2

sqlplus -S sys/$SYS_PWD@$CB_IP as sysdba @$ROOT/create_users $CB_PWD

sqlplus -S cb/$CB_PWD@$CB_IP @$ROOT/create_db_link_cb $CB_PWD
sqlplus -S cbb/$CB_PWD@$CB_IP @$ROOT/create_db_link_cbb $CB_PWD

sqlplus -S cb/$CB_PWD@$CB_IP @$ROOT/crea
sqlplus -S cbb/$CB_PWD@$CB_IP @$ROOT/crea

sqlplus -S cb/$CB_PWD@$CB_IP @$ROOT/logs
sqlplus -S cbb/$CB_PWD@$CB_IP @$ROOT/logs

sqlplus -S cb/$CB_PWD@$CB_IP @$ROOT/backup_trigger
sqlplus -S cbb/$CB_PWD@$CB_IP @$ROOT/backup_trigger

sqlplus -S cb/$CB_PWD@$CB_IP @$ROOT/backup_head
sqlplus -S cbb/$CB_PWD@$CB_IP @$ROOT/backup_head

sqlplus -S cb/$CB_PWD@$CB_IP @$ROOT/backup_body
sqlplus -S cbb/$CB_PWD@$CB_IP @$ROOT/backup_body

sqlplus -S cb/$CB_PWD@$CB_IP @$ROOT/package_head
sqlplus -S cbb/$CB_PWD@$CB_IP @$ROOT/package_head

sqlplus -S cb/$CB_PWD@$CB_IP @$ROOT/package_body
sqlplus -S cbb/$CB_PWD@$CB_IP @$ROOT/package_body

sqlplus -S cb/$CB_PWD@$CB_IP @$ROOT/create_job
sqlplus -S cbb/$CB_PWD@$CB_IP @$ROOT/create_job
