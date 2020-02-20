const fs = require('fs');
var properties = []
module.exports = {
    readproperties : (file)=>{
        for(property of fs.readFileSync(file).toString().split('\n').slice(0,-1)){
            propAndValue=property.split("=");
            properties.push(JSON.parse("{\"key\":\"" + propAndValue[0] + "\",\"value\":\"" + propAndValue[1] + "\"}"));
        }
    },
    getProperty : (prop)=>{ return properties.find((e)=>e.key===prop).value;},
    safelyParseJSON : (str)=>{ return JSON.parse(str.replace(/\s+/, " "));},
    getUniqueRecords : (records)=>{
        return Array.from(new Set(records.map((e)=>e.title))).map((e)=>records.map((f)=>f.title).indexOf(e)).map((g)=>records[g]);
    }
}

