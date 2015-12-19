#!/bin/sh
set -e
ROOT=`dirname \`realpath $0\``

if [ $# -ne 11 ]; then
    echo ' Needs exactly 11 args'
    echo ' Usage:'
    echo '  ./install.sh <cb_ip> <cbb_ip> <cc_ip>       \'
    echo '      <cb_sys_pwd> <cbb_sys_pwd> <cc_sys_pwd> \'
    echo '      <cb_pwd> <cbb_pwd> <cc_pwd>             \'
    echo '      <cb_dir> <cc_dir>'
    echo
    echo '  <cb_ip>       the IP [and port] of the CB oracle instance (i.e. 127.0.0.1:4509)'
    echo '  <cbb_ip>      the IP [and port] of the CBB oracle instance'
    echo '  <cc_ip>       the IP [and port] of the CC oracle instance'
    echo '  <cb_sys_pwd>  the sys password of the CB oracle instance'
    echo '  <cbb_sys_pwd> the sys password of the CBB oracle instance'
    echo '  <cc_sys_pwd>  the sys password of the CC oracle instance'
    echo '  <cb_pwd>      the password to give to the CB user'
    echo '  <cbb_pwd>     the password to give to the CBB user'
    echo '  <cc_pwd>      the password to give to the CC user'
    echo '  <cb_dir>      the directory to use to find the movies.txt file'
    echo '  <cc_dir>      the directory to use to find the CC XSDs'
    exit 1
fi

CB_IP=$1
CBB_IP=$2
CC_IP=$3

CB_SYS_PWD=$4
CBB_SYS_PWD=$5
CC_SYS_PWD=$6

CB_PWD=$7
CBB_PWD=$8
CC_PWD=$9

# Greater than 9 parameters, gotta shift to access them
shift
echo $9
CB_DIR=$9
shift
echo $9
CC_DIR=$9

SQLPLUS="sqlplus -S -L"

INSERT_CB_PWD="s/&cb_pwd/$CB_PWD/g"
INSERT_CBB_PWD="s/&cbb_pwd/$CBB_PWD/g"
INSERT_CC_PWD="s/&cc_pwd/$CC_PWD/g"

export NLS_LANG=.UTF8

echo "Creating cb"
echo "==========="
cat $ROOT/cb/create_user_cb.sql \
    | sed "$INSERT_CB_PWD"      \
    | $SQLPLUS sys/$CB_SYS_PWD@$CB_IP as sysdba

echo "Creating cbb"
echo "============"
cat $ROOT/cb/create_user_cbb.sql \
    | sed "$INSERT_CBB_PWD"      \
    | $SQLPLUS sys/$CBB_SYS_PWD@$CBB_IP as sysdba

echo "Creating cc"
echo "==========="
cat $ROOT/cc/create_user.sql \
    | sed "$INSERT_CC_PWD"   \
    | $SQLPLUS sys/$CC_SYS_PWD@$CC_IP as sysdba


echo "Creating cb links"
echo "================="
cat $ROOT/cb/create_db_link_cb.sql  \
    | sed "$INSERT_CBB_PWD"         \
    | sed "$INSERT_CC_PWD"          \
    | $SQLPLUS cb/$CB_PWD@$CB_IP

cat $ROOT/cb/create_db_link_cbb.sql \
    | sed "$INSERT_CB_PWD"          \
    | sed "$INSERT_CC_PWD"          \
    | $SQLPLUS cbb/$CBB_PWD@$CBB_IP

cat $ROOT/cc/create_db_link_cc.sql  \
    | sed "$INSERT_CB_PWD"          \
    | sed "$INSERT_CBB_PWD"         \
    | $SQLPLUS cc/$CC_PWD@$CC_IP

echo "Initializing cb"
echo "==============="
cat $ROOT/cb/create_tables.sql        \
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
        | sed "s/&cb_dir/$(echo $CB_DIR | sed 's/\//\\\//g')/g" \
        | $SQLPLUS cb/$CB_PWD@$CB_IP

echo "Initializing cbb"
echo "================"
cat $ROOT/cb/create_tables.sql       \
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
        | $SQLPLUS cbb/$CBB_PWD@$CBB_IP

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
cat $ROOT/cc/create_xsd.sql            \
    $ROOT/utils/logs.sql               \
    $ROOT/cc/create_table.sql          \
    $ROOT/cc/cb_transfer_head.sql      \
    $ROOT/cc/cb_transfer_body.sql      \
    $ROOT/cc/cbb_transfer_head.sql     \
    $ROOT/cc/cbb_transfer_body.sql     \
    $ROOT/cc/scheduling_head.sql       \
    $ROOT/cc/scheduling_body.sql       \
    $ROOT/cc/create_job_scheduling.sql \
    $ROOT/cc/archive_head.sql          \
    $ROOT/cc/archive_body.sql          \
    $ROOT/cc/create_job_archiving.sql  \
        | sed "s/&cc_dir/$(echo $CC_DIR | sed 's/\//\\\//g')/g" \
        | $SQLPLUS cc/$CC_PWD@$CC_IP

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
        | $SQLPLUS cbb/$CBB_PWD@$CBB_IP
