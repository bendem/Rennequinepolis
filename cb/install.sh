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
SQLPLUS="sqlplus -S -L"

$SQLPLUS sys/$SYS_PWD@$CB_IP as sysdba @$ROOT/create_users $CB_PWD

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/create_db_link_cb $CB_PWD
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/create_db_link_cbb $CB_PWD

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/crea
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/crea

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/logs
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/logs

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/backup_trigger
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/backup_trigger

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/backup_head
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/backup_head

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/backup_body
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/backup_body

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/package_head
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/package_head

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/package_body
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/package_body

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/create_job
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/create_job
