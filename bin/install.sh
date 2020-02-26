#!/bin/bash

this_dir=$(cd $(dirname ${BASH_SOURCE[0]}) > /dev/null 2>&1 && pwd)
base_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" > /dev/null 2>&1 && pwd)

readprop(){
    echo "$(grep -oP "(?<=^$1=).+" $base_dir/properties/app.properties)"
}
waitformongo(){
    sleep 1
    logStart=$(cat $base_dir/logs/mongo.log | grep -n "\[initandlisten\] MongoDB starting" | awk -F: '{print $1}' | tail -1)

    listening=false
    while [ "$listening" = "false" ];do
        logLength=$(wc -l $base_dir/logs/mongo.log | awk '{print $1}')
        [ -n "$(tail -$((logLength-logStart)) $base_dir/logs/mongo.log | grep "waiting for connections on port $(readprop mongo.port)")" ] && listening=true
        sleep 1
    done
}
downloadTools(){
    if [ -n "$(which mongo)" ] && [ -n "$(which mongod)" ];then
        read  -p "Hmm.. Looks like mongo is already installed."$'\n'"Continuing with the installtion will remove any existing mongo database"$'\n'"located at $base_dir/data."$'\n'"Are you sure you want to continue?(y/n):" res
        [ "$res" = "n" ] && echo "OK Exiting now!" && exit 1
    else
        wget -q0 - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
        sudo apt-get update
        sudo apt-get install -y mongodb-org      
    fi
    if [ -z "$( which node)" ] || [ -z "$(which npm)" ];then
        sudo apt-get update
        sudo apt-get install -y nodejs npm
    fi
}


downloadTools

mkdir -p $base_dir/data
rm -rf $base_dir/data/*

mkdir -p $base_dir/logs

mkdir -p $base_dir/bin/mongoscripts
rm -rf $base_dir/bin/mongoscripts/*
cp -r $base_dir/bin/mongotemplates/* $base_dir/bin/mongoscripts
$base_dir/bin/processMongoScripts.sh

nohup mongod --port $(readprop mongo.port) --dbpath $base_dir/data >> $base_dir/logs/mongo.log 2>&1 &

waitformongo

mongo --port $(readprop mongo.port) admin $base_dir/bin/mongoscripts/createAdminUser.js  > /dev/null 2>&1
mongo --port $(readprop mongo.port) admin $base_dir/bin/mongoscripts/shutdown.js > /dev/null 2>&1

nohup mongod --auth --port $(readprop mongo.port) --dbpath $base_dir/data >> $base_dir/logs/mongo.log 2>&1 &

waitformongo


mongo --port $(readprop mongo.port) $(readprop mongo.app.db) -u $(readprop mongo.admin.username) -p $(readprop mongo.admin.password) --authenticationDatabase admin $base_dir/bin/mongoscripts/createAppUser.js > /dev/null 2>&1

rm -rf $base_dir/node_modules

cd $base_dir
[ "$1" != "-n" ] && npm install



