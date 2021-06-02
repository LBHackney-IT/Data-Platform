# #!/bin/bash

# MYSQL_USER="dbuser"
# MYSQL_PASS="userpass"
# MYSQL_CONN_PARAMS="--user=${MYSQL_USER} --password=${MYSQL_PASS} --host=mysql"

# while ! mysqladmin ping ${MYSQL_CONN_PARAMS} --silent; do
#   sleep 1
# done
#
# echo "start: $now"
# mysql ${MYSQL_CONN_PARAMS} --database=myimage_db < data_warehouse.sql
# echo "end: $now"

x=1
while [ $x -le 5 ]
do
  echo 'hello'
  sleep 1
  x=$(( $x + 1 ))
done
