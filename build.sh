#!/bin/sh

# This script compiles/installs MCS from scratch skiping long
# OAM initialization step that is usually unnecessary for
# development. 
# The script presumes that server's source code is two directories
# above the MCS engine source.

#MDB_BUILD_TYPE=relWithDebInfo
MDB_BUILD_TYPE=release
#MDB_BUILD_TYPE=debug
BUILD_TYPE=debug
MCS_SCRIPTS_REPO_PREFIX=/home/denis/cs-docker-tools
MDB_SOURCE_PATH=/home/denis/data/mdb-server
MCS_SOURCE_PATH=$MDB_SOURCE_PATH/storage/columnstore
MCS_CONFIG_DIR=/etc/columnstore
MDB_GIT_URL=https://github.com/MariaDB/server.git
MCS_GIT_URL=https://github.com/mariadb-corporation/mariadb-columnstore-engine.git
MDB_GIT_TAG=10.5
MCS_GIT_TAG=develop

echo 'stop the service'
systemctl stop mariadb-columnstore.service
systemctl stop mcs-storagemanager.service

if [ $? -ne 0 ]; then
    return 1
fi

MCS_INSTALL_PREFIX=/var/lib/
rm -rf /var/lib/columnstore/data1/
rm -rf /var/lib/columnstore/data/
rm -rf /var/lib/columnstore/local/
rm -f /var/lib/columnstore/storagemanager/storagemanager-lock
rm -rf /var/lib/columnstore/storagemanager/*


MCS_TMP_DIR=/tmp/columnstore_tmp_files
TMP_PATH=/tmp

# script
rm -rf $MCS_TMP_DIR/*
rm -rf /var/lib/mysql

# Werror in connector
#CFLAGS='Wno-error'
#CXXFLAGS='Wno-error'

CPU=16

cd $MDB_SOURCE_PATH
 #MDB_CMAKE_FLAGS='-DWITH_SYSTEMD=yes -DPLUGIN_TOKUDB=NO -DPLUGIN_ROCKSDB=NO -DPLUGIN_MROONGA=NO -DPLUGIN_GSSAPI=NO -DWITH_MARIABACKUP=NO -DDEB=bionic -DPLUGIN_COLUMNSTORE=YES'
MDB_CMAKE_FLAGS='-DWITH_SYSTEMD=yes -DPLUGIN_COLUMNSTORE=YES -DPLUGIN_MROONGA=NO -DPLUGIN_ROCKSDB=NO -DPLUGIN_TOKUDB=NO -DPLUGIN_CONNECT=YES -DPLUGIN_SPIDER=NO -DPLUGIN_OQGRAPH=NO -DPLUGIN_SPHINX=NO -DBUILD_CONFIG=mysql_release -DWITH_SHARED_COMP_TESTS=0 -DWITH_REBUILD_EM_UT=1 -DWITH_GTEST=1 -DWITH_WSREP=OFF -DWITH_ROWGROUP_UT=1 -DWITH_SSL=system -DDEB=bionici  -DWITH_COLUMNSTORE_LZ4=ON -DWITH_URING=0' 
#-DWITH_PCRE=bundle
# These flags will be available in 1.5
#MDB_CMAKE_FLAGS="${MDB_CMAKE_FLAGS} -DWITH_GTEST=1 -DWITH_ROWGROUP_UT=1 -DWITH_DATACONVERT_UT=1 -DWITH_ARITHMETICOPERATOR_UT=1 -DWITH_ORDERBY_UT=1 -DWITH_CSDECIMAL_UT=1 -DWITH_SORTING_COMPARATORS_UT=1"
 #MDB_CMAKE_FLAGS="${MDB_CMAKE_FLAGS} -DWITH_PP_SCAN_UT=1"
cmake . -DCMAKE_INSTALL_PREFIX="/usr" -DCMAKE_BUILD_TYPE=$MDB_BUILD_TYPE ${MDB_CMAKE_FLAGS} && \
#make VERBOSE=1 -j $CPUS
make -j $CPU 
make install

if [ $? -ne 0 ]; then
    return 1
fi

mv /usr/lib/mysql/plugin/ha_columnstore.so /tmp/ha_columnstore_1.so

# make sure plugin config is installed
cp ${MCS_SOURCE_PATH}/columnstore/dbcon/mysql/columnstore.cnf /etc/my.cnf.d
echo 'plugin_maturity=beta' >> /etc/my.cnf.d/columnstore.cnf

/usr/bin/mysql_install_db --rpm --user=mysql

mv /tmp/ha_columnstore_1.so /usr/lib/mysql/plugin/ha_columnstore.so

cp -r /etc/mysql/conf.d /etc/my.cnf.d/
cp $MDB_SOURCE_PATH/storage/columnstore/columnstore/oam/etc/Columnstore.xml /etc/columnstore/Columnstore.xml
cp $MDB_SOURCE_PATH/storage/columnstore/columnstore/storage-manager/storagemanager.cnf /etc/columnstore/storagemanager.cnf


#echo 'copy service files'
rm -f /lib/systemd/system/mariadb*
cp  $MDB_SOURCE_PATH/support-files/*.service /lib/systemd/system/
cp  $MDB_SOURCE_PATH/storage/columnstore/columnstore/oam/install_scripts/*.service /lib/systemd/system/
cp  $MDB_SOURCE_PATH/debian/additions/debian-start.inc.sh /usr/share/mysql/debian-start.inc.sh
cp  $MDB_SOURCE_PATH/debian/additions/debian-start /etc/mysql/debian-start

#
#systemctl daemon-reload
rm -f /etc/mysql/my.cnf
cp -r /etc/mysql/conf.d/ /etc/my.cnf.d
mkdir /var/lib/columnstore/data1
mkdir /var/lib/columnstore/data1/systemFiles
mkdir /var/lib/columnstore/data1/systemFiles/dbrm
chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql
chown -R mysql.mysql /var/run/mysqld 
chmod +x /usr/bin/mariadb*

ldconfig    
systemctl start mcs-storagemanager
columnstore-post-install

/usr/sbin/install_mcs_mysql.sh

chown -R mysql:mysql /var/log/mariadb/ 
chmod 777 /var/log/mariadb/ 
chmod 777 /var/log/mariadb/columnstore 

echo "restart mariadb server"
systemctl restart mariadb
#systemctl start mcs-storagemanager

exit 0 
