#!/bin/sh

set -e

if [ "$CB_IP" == "" ]; then
    echo
    echo ' CB_IP not provided'
    echo
    exit 2
fi

if [ $# -ne 1 ]; then
    echo
    echo ' Needs exactly 1 args'
    echo
    echo ' Usage:'
    echo '  CB_IP=<ip[:<port>]> ./uninstall.sh <sys_pwd>'
    echo
    exit 1
fi

SYS_PWD=$1

echo "drop user cb cascade;
    drop user cbb cascade;
    drop role myrole;
    execute dbms_network_acl_admin.drop_acl('http.xml');
    commit;
    exit" | sqlplus -S -L sys/$SYS_PWD@$CB_IP as sysdba
