#!/bin/sh
set -e
ROOT=`dirname \`realpath $0\``

if [ $# -ne 3 ]; then
    echo
    echo ' Needs exactly 3 args'
    echo
    echo ' Usage:'
    echo '  CB_IP=<ip[:<port>]> ./install.sh <sys_pwd> <cb_pwd> <cc_pwd>'
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
CC_PWD=$3
SQLPLUS="sqlplus -S -L"
INSERT_CB_PWD="s/&cb_pwd/$CB_PWD/g"
INSERT_CC_PWD="s/&cc_pwd/$CC_PWD/g"

export NLS_LANG=.UTF8

echo "Creating users"
echo "=============="
cat $ROOT/cb/create_users.sql \
    $ROOT/cc/create_user.sql  \
    | sed "$INSERT_CB_PWD"    \
    | sed "$INSERT_CC_PWD"    \
    | $SQLPLUS sys/$SYS_PWD@$CB_IP as sysdba

echo "Creating db links"
echo "================="
cat $ROOT/cb/create_db_link_cbb.sql \
    | sed "$INSERT_CB_PWD"          \
    | sed "$INSERT_CC_PWD"          \
    | $SQLPLUS cbb/$CB_PWD@$CB_IP

cat $ROOT/cb/create_db_link_cb.sql  \
    | sed "$INSERT_CB_PWD"          \
    | sed "$INSERT_CC_PWD"          \
    | $SQLPLUS cb/$CB_PWD@$CB_IP

cat $ROOT/cc/create_db_link_cc.sql  \
    | sed "$INSERT_CB_PWD"          \
    | sed "$INSERT_CB_PWD"          \
    | $SQLPLUS cc/$CC_PWD@$CB_IP

echo "Initializing cb"
echo "==============="
cat $ROOT/cb/crea.sql                 \
    $ROOT/cb/movie_sequences.sql      \
    $ROOT/utils/logs.sql              \
    $ROOT/utils/types.sql             \
    $ROOT/utils/utils_head.sql        \
    $ROOT/utils/utils_body.sql        \
    $ROOT/utils/timer_head.sql        \
    $ROOT/utils/timer_body.sql        \
    $ROOT/cb/create_ext_table.sql     \
    $ROOT/cb/link_check_head.sql      \
    $ROOT/cb/link_check_body_cb.sql   \
    $ROOT/cb/search_head.sql          \
    $ROOT/cb/search_body.sql          \
        | $SQLPLUS cb/$CB_PWD@$CB_IP

echo "Initializing cbb"
echo "================"
cat $ROOT/cb/crea.sql                \
    $ROOT/utils/logs.sql             \
    $ROOT/utils/types.sql            \
    $ROOT/utils/utils_head.sql       \
    $ROOT/utils/utils_body.sql       \
    $ROOT/cb/backup_head.sql         \
    $ROOT/cb/backup_body.sql         \
    $ROOT/cb/link_check_head.sql     \
    $ROOT/cb/link_check_body_cbb.sql \
    $ROOT/cb/management_head.sql     \
    $ROOT/cb/management_body.sql     \
    $ROOT/cb/create_job.sql          \
    $ROOT/cb/search_head.sql         \
    $ROOT/cb/search_body.sql         \
        | $SQLPLUS cbb/$CB_PWD@$CB_IP

echo "Setting up cb backup"
echo "===================="
cat $ROOT/cb/backup_trigger.sql  \
    $ROOT/cb/backup_head.sql     \
    $ROOT/cb/backup_body.sql     \
    $ROOT/cb/management_head.sql \
    $ROOT/cb/management_body.sql \
    $ROOT/cb/create_job.sql      \
        | $SQLPLUS cb/$CB_PWD@$CB_IP

echo "Setting up cc"
echo "============="
cat $ROOT/cc/create_xsd.sql        \
    $ROOT/cc/create_table.sql      \
    $ROOT/cc/cb_transfer_head.sql  \
    $ROOT/cc/cb_transfer_body.sql  \
    $ROOT/cc/cbb_transfer_head.sql \
    $ROOT/cc/cbb_transfer_body.sql \
        | $SQLPLUS cc/$CC_PWD@$CB_IP

echo "Setting up cb proxy and alims"
echo "==================="
cat $ROOT/cb/cc_proxy_head.sql    \
    $ROOT/cb/cc_proxy_cb_body.sql \
    $ROOT/cb/cc_alim_head.sql     \
    $ROOT/cb/cc_alim_body.sql     \
    $ROOT/cb/movie_alim_head.sql  \
    $ROOT/cb/movie_alim_body.sql  \
        | $SQLPLUS cb/$CB_PWD@$CB_IP

echo "Setting up cbb proxy"
echo "==================="
cat $ROOT/cb/cc_proxy_head.sql     \
    $ROOT/cb/cc_proxy_cbb_body.sql \
        | $SQLPLUS cbb/$CB_PWD@$CB_IP
