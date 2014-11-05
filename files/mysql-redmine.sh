#!/bin/bash

if [ ! $1 ]; then
	echo 'password is required'
	exit 1;
else
	password=$1
fi;

expect -c "
spawn mysql -uroot -p

set password [lindex $argv 0]

expect \"Enter password:\"
send \"$password\r\"

expect \"mysql>\"
send \"create database db_redmine default character set utf8;\"

expect \"mysql>\"
send \"grant all on db_redmine.* to user_redmine@localhost identified by '$password';\r\"

expect \"mysql>\"
send \"flush privileges;\r\"

expect \"mysql>\"
send \"exit;\r\"
"
