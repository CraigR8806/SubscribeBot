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
downloadToolsRHEL(){
    if [ "$(sudo subscription-manager status | grep -oP "(?<=^Overall Status:).+" | tr -d " ")" != "Current" ];then
        echo "Please register your RHEL installation before continuing with this install"
        exit 1
    fi

    sudo cp $this_dir/../resources/mongodb-org-4.2.repo /etc/yum.repos.d
    if [ -n "$(sudo yum install -y mongodb-org | grep 'Package mongodb-org-4.2.3-1.el8.x86_64 is already installed.')" ];then
        read  -p "Hmm.. Looks like mongo is already installed."$'\n'"Continuing with the installtion will remove any existing mongo database"$'\n'"located at $base_dir/data."$'\n'"Are you sure you want to continue?(y/n):" res
        [ "$res" = "n" ] && echo "OK Exiting now!" && exit 1
    fi
    if [ -z "$(which node)" ];then
        sudo yum install -y gcc-c++ make
        curl -sL https://rpm.nodesource.com/setup_13.x | sudo -E bash -
        sudo yum install nodejs
    fi
}
downloadToolsDebian(){
    if [ -n "$(which mongo)" ] || [ -n "$(which mongod)" ];then
        read  -p "Hmm.. Looks like mongo is already installed."$'\n'"Continuing with the installtion will remove any existing mongo database"$'\n'"located at $base_dir/data."$'\n'"Are you sure you want to continue?(y/n):" res
        [ "$res" = "n" ] && echo "OK Exiting now!" && exit 1
    else
        sudo apt update
        sudo apt install -y software-properties-common dirmngr
        sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
        sudo add-apt-repository 'deb http://repo.mongodb.org/apt/debian stretch/mongodb-org/4.2 main'
        sudo apt install -y mongodb-org
    fi
    if [ -z "$( which node)" ] || [ -z "$(which npm)" ];then
        sudo apt update
        sudo apt install -y nodejs npm
    fi
}

release=$(cat /etc/*release | grep -P "^ID_LIKE=\"?[^\"]+" | awk -F= '{print $2}' | tr -d '\"')

if [ "$release" = "fedora" ];then
    downloadToolsRHEL
elif [ "$release" = "debian" ];then
    downloadToolsDebian
fi

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



