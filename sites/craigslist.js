const { execSync } = require('child_process');
const { getUniqueRecords, safelyParseJSON } = require(__dirname + "/../bin/util.js");
module.exports = {
    name:"craigslist",
    urlpattern:/http[s]?:\/\/[^\.]+\.craigslist\.org.+/,
    getRecords:(link, file)=>{
        return getUniqueRecords(safelyParseJSON("[" + execSync("wget --output-file=/dev/null -O " + file + " \"" + link + "\"; cat " + file + " | head -$(if [ -z \"$(grep -n 'ban nearby' " + file + " | awk -F: '{print $1}')\" ];then echo $(wc -l " + file + " | awk '{print $1}');else echo $(grep -n 'ban nearby' " + file + " | awk -F: '{print $1}');fi;) " + file + " | grep -P \"<a.+?result-title hdrlnk\" | grep -oP \"(?<=<a href=\\\").+?(?=</a>)\" | sed -r \"s/^([^\\\"]++)[^>]+>(.+)/\\{\\\"link\\\":\\\"\\1\\\",\\\"title\\\":\\\"\\2\\\"\\}/\" | tr '\\n' ',';rm -f " + file).toString().slice(0,-1) + "]"));
    },
    getNotificationList:(thisCheck, lastCheck)=>{
        return thisCheck.map((e)=>e.title).filter((e)=>!lastCheck.map((f)=>f.title).includes(e)).map(e=>thisCheck.map(f=>f.title).indexOf(e)).map(e=>thisCheck[e]);
    },
    composeEmbeddedMessage:(sub,notificationList)=>{
        let f = notificationList.map(e=> new Object({name:e.title,value:e.link}));
        return {
            color: 0x0099ff,
            title: sub.name,
            description: "New listings from " + sub.link,
            fields: f,
            timestamp: new Date()
        };
    }
}
