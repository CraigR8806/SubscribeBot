#!/bin/bash

this_dir=$(cd $(dirname ${BASH_SOURCE[0]}) > /dev/null 2>&1 && pwd)
base_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" > /dev/null 2>&1 && pwd)

readprop(){
    echo "$(grep -oP "(?<=^$1=).+" $base_dir/properties/app.properties)"
}

mongo --port $(readprop mongo.port) -u $(readprop mongo.admin.username) -p $(readprop mongo.admin.password) --authenticationDatabase admin $base_dir/bin/mongoscripts/shutdown.js > /dev/null 2>&1

