#!/bin/bash

this_dir=$(cd $(dirname ${BASH_SOURCE[0]}) > /dev/null 2>&1 && pwd)
base_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" > /dev/null 2>&1 && pwd)

readprop(){
    echo "$(grep -oP "(?<=^$1=).+" $base_dir/properties/app.properties)"
}

[ -n "$(ps aux | grep '[m]ongo' | grep -P "\-(ort)? $(readprop mongo.port)")" ] && sudo kill $(ps aux | grep '[m]ongo' | grep -P "\-p(ort)? $(readprop mongo.port)")

nohup mongod --auth --port $(readprop mongo.port) --dbpath $base_dir/data >> $base_dir/logs/mongo.log 2>&1 &

nohup node $base_dir/bot.js >> logs/bot.log 2>&1 &
