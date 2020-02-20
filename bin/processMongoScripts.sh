#!/bin/bash

this_dir=$(cd $(dirname ${BASH_SOURCE[0]}) > /dev/null 2>&1 && pwd)
base_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" > /dev/null 2>&1 && pwd)

readprop(){
    echo "$(grep -oP "(?<=^$1=).+" $base_dir/properties/app.properties)"
}

for prop in $(cat $base_dir/properties/app.properties | grep "^mongo\.");do
    key=$(echo $prop | awk -F= '{print $1}')
    val=$(echo $prop | grep -oP "(?<=$key=).+")
    sed -ri "s/\\$\\{$key\\}/$val/g" $base_dir/bin/mongoscripts/*
done
