#!/bin/bash

this_dir=$(cd $(dirname ${BASH_SOURCE[0]}) > /dev/null 2>&1 && pwd)
base_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" > /dev/null 2>&1 && pwd)

readprop(){
    echo "$(grep -oP "(?<=^$1=).+" $base_dir/properties/app.properties)"
}

[ -n "$(ps aux | grep '[n]ode' | grep 'bot.js')" ] && kill $(ps aux | grep '[n]ode' | grep 'bot.js' | awk '{print $2}' | tr '\n' ' ')

[ -n "$(ps aux | grep '[m]ongo' | grep -P "\-p(ort) $(readprop mongo.port)")" ] && mongo --port $(readprop mongo.port) -u $(readprop mongo.admin.username) -p $(readprop mongo.admin.password) --authenticationDatabase admin $base_dir/bin/mongoscripts/shutdown.js > /dev/null 2>&1

