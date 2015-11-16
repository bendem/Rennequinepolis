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
INSERT_CB_PWD="s/&cb_pwd/$CB_PWD/g"

export NLS_LANG=.UTF8

echo "Creating users"
echo "=============="
cat $ROOT/cb/create_users.sql | sed "$INSERT_CB_PWD" | $SQLPLUS sys/$SYS_PWD@$CB_IP as sysdba

echo "Creating db links"
echo "================="
cat $ROOT/cb/create_db_link_cbb.sql | sed "$INSERT_CB_PWD" | $SQLPLUS cbb/$CB_PWD@$CB_IP
cat $ROOT/cb/create_db_link_cb.sql | sed "$INSERT_CB_PWD" | $SQLPLUS cb/$CB_PWD@$CB_IP

echo "Initializing cb"
echo "==============="
cat $ROOT/cb/crea.sql                 \
    $ROOT/utils/logs.sql              \
    $ROOT/utils/types.sql             \
    $ROOT/utils/utils_head.sql        \
    $ROOT/utils/utils_body.sql        \
    $ROOT/utils/timer_head.sql        \
    $ROOT/utils/timer_body.sql        \
    $ROOT/cb/create_ext_table.sql     \
    $ROOT/cb/movie_alim_head.sql      \
    $ROOT/cb/movie_alim_body.sql      \
    $ROOT/cb/search_head.sql          \
    $ROOT/cb/search_body.sql          \
        | $SQLPLUS cb/$CB_PWD@$CB_IP

echo "Initializing cbb"
echo "================"
cat $ROOT/cb/crea.sql            \
    $ROOT/utils/logs.sql         \
    $ROOT/cb/management_head.sql \
    $ROOT/cb/management_body.sql \
    $ROOT/cb/backup_trigger.sql  \
    $ROOT/cb/backup_head.sql     \
    $ROOT/cb/backup_body.sql     \
    $ROOT/cb/create_job.sql      \
    $ROOT/cb/search_head.sql     \
    $ROOT/cb/search_body.sql     \
        | $SQLPLUS cbb/$CB_PWD@$CB_IP

echo "Setting up cb backup"
echo "================"
cat $ROOT/cb/backup_trigger.sql  \
    $ROOT/cb/management_head.sql \
    $ROOT/cb/management_body.sql \
    $ROOT/cb/backup_head.sql     \
    $ROOT/cb/backup_body.sql     \
    $ROOT/cb/create_job.sql      \
        | $SQLPLUS cb/$CB_PWD@$CB_IP
