#!/bin/bash

this_dir="$(cd "$(dirname ${BASH_SOURCE[0]})" > /dev/null && pwd)"

imagename=$1

readprop(){
    echo "$(grep -oP "(?<=^$1=).+" $this_dir/app.properties)"
}

cp $this_dir/.Dockerfile $this_dir/Dockerfile

sed -ri "s/<adminpass>/$(readprop mongo.admin.password)/" $this_dir/Dockerfile
sed -ri "s/<appuserpass>/$(readprop mongo.app.user.password)/" $this_dir/Dockerfile
sed -ri "s/<bottoken>/$(readprop discord.bot.token)/" $this_dir/Dockerfile


