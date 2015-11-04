#!/bin/sh
# Usage:
#   CB_IP=<ip[:<port>]> ./install.sh <sys_pwd> <cb_pwd>
set -e
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

$SQLPLUS sys/$SYS_PWD@$CB_IP as sysdba @$ROOT/cb/create_users $CB_PWD

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/cb/create_db_link_cb $CB_PWD
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/cb/create_db_link_cbb $CB_PWD

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/cb/crea
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/cb/crea

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/utils/logs
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/utils/logs

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/cb/backup_trigger
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/cb/backup_trigger

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/cb/backup_head
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/cb/backup_head

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/cb/backup_body
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/cb/backup_body

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/cb/package_head
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/cb/package_head

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/cb/package_body
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/cb/package_body

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/cb/create_job
$SQLPLUS cbb/$CB_PWD@$CB_IP @$ROOT/cb/create_job

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/cb/create_ext_table

$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/utils/timer_head
$SQLPLUS cb/$CB_PWD@$CB_IP @$ROOT/utils/timer_body
