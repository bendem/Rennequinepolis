#!/bin/sh
set -e

if [ $# -ne 6 ]; then
    echo ' Needs exactly 6 args'
    echo ' Usage:'
    echo '  ./uninstall.sh <cb_ip> <cbb_ip> <cc_ip> \'
    echo '      <cb_sys_pwd> <cbb_sys_pwd> <cc_sys_pwd>'
    echo
    echo '  <cb_ip>       the IP [and port] of the CB oracle instance (i.e. 127.0.0.1:4509)'
    echo '  <cbb_ip>      the IP [and port] of the CBB oracle instance'
    echo '  <cc_ip>       the IP [and port] of the CC oracle instance'
    echo '  <cb_sys_pwd>  the sys password of the CB oracle instance'
    echo '  <cbb_sys_pwd> the sys password of the CBB oracle instance'
    echo '  <cc_sys_pwd>  the sys password of the CC oracle instance'
    exit 1
fi

CB_IP=$1
CBB_IP=$2
CC_IP=$3

CB_SYS_PWD=$4
CBB_SYS_PWD=$5
CC_SYS_PWD=$6

echo "drop user cb cascade;
    drop role cb_role;
    execute dbms_network_acl_admin.drop_acl('http.xml');
    commit;
" | sqlplus -S -L sys/$CB_SYS_PWD@$CB_IP as sysdba

echo "drop user cbb cascade;
    drop role cbb_role;
" | sqlplus -S -L sys/$CBB_SYS_PWD@$CBB_IP as sysdba

echo "drop user cc cascade;
    drop role cc_role;
" | sqlplus -S -L sys/$CC_SYS_PWD@$CC_IP as sysdba
