const { execSync } = require('child_process');
const { readproperties, getProperty } = require('./bin/util.js');
const fs = require('fs');
const Discord = require('discord.js');
const MongoClient = require('mongodb');

const client  = new Discord.Client();

readproperties(__dirname + "/properties/app.properties");

function loadSites(){
    return fs.readdirSync("sites").toString().split(",").filter(e=>e.endsWith(".js")).map(e=>require('./sites/' + e));
}

function getCollection(mongo){
    return mongo.db(getProperty("mongo.app.db")).collection(getProperty("mongo.app.db.collection"));
}

function getMongoConnection(){
    return MongoClient("mongodb://" + getProperty("mongo.app.user.username") + ":" + getProperty("mongo.app.user.password") + "@127.0.0.1:" + getProperty("mongo.port") + "/appdata?retryWrites=true&w=majority", {useNewUrlParser: true,  useUnifiedTopology: true});
}


client.on('ready', ()=>{
    console.log('Logged in as ${client.user.tag}!');
    setInterval(()=>{
        sites = loadSites();
        getMongoConnection().then((mongo)=>{
            let collection = getCollection(mongo);
            collection.find({}).toArray((err,res)=>{
                if(err)console.log(err);
                let subscriptions = res.map(e=>e);
                for(sub of subscriptions){
                    let site = sites.find((e)=>sub.link.match(e.urlpattern));
                    if(site){
                        let thisCheck = site.getRecords(sub.link, __dirname + "/html.tmp");
                        let notificationList = site.getNotificationList(thisCheck, sub.lastCheck);
                        if(notificationList.length > 0){
                            for(let i=0;i<Math.ceil(notificationList.length/5);i++){
                                new Discord.User(client, sub.user).send(new Object({ embed: site.composeEmbeddedMessage(sub, notificationList.slice((i*5), 5))}));
                            }
                            collection.updateOne({_id:sub._id},{$set:{lastCheck:thisCheck}});
                        }
                    }
                }
            });
        });
    }, getProperty("discord.bot.interval.ms"));
});

client.on('message', (message)=>{
    if(message.content.startsWith("!sb ")){
        let cmd=message.content.split(" ");
        let incorrect=false
        if(cmd[1] === "subscribe"){

            let sub = {
                user:message.author,
                name:cmd[2],
                link:cmd[3]
            }

            if(sub.link){
                sites = loadSites();
                let site = sites.find((e)=>sub.link.match(e.urlpattern));
                console.log(site);
                if(site){
                    getMongoConnection().then((mongo)=>{
                        let collection = getCollection(mongo);
                        collection.find({"user.id":message.author.id}).toArray((err,res)=>{
                            let userSubscriptions = res.map(e=>e);
                            let nameIndex = userSubscriptions.map((e)=>e.name).indexOf(sub.name);
                            let linkIndex = userSubscriptions.map((e)=>e.link).indexOf(sub.link);
                            if( nameIndex == -1 && linkIndex == -1){
                                let lastCheck = site.getRecords(sub.link, __dirname + "/html.tmp");
                                collection.insertOne({"name":sub.name,"link":sub.link,"lastCheck":lastCheck,"user":message.author});
                                message.channel.send("A subscription with the name " + sub.name + " and link " + sub.link + " has been created for user " + message.author.username + "\nTo see a listing of your subscriptions, run: !sb list");
                            }else{
                                let msg = ""
                                if(nameIndex != -1){
                                    msg+="A subscription with the name " + sub.name + " has previously been created for user " + message.author.username + "\n";
                                }
                                if(linkIndex != -1){
                                    msg+="A subscription with the link " + sub.link + " has previously been created for user " + message.author.username + "\n";}
                                msg+="To see a listing of your subscriptions, run: !sb list"
                                message.channel.send(msg);
                            }
                        });
                    });
                }else{
                    message.channel.send(message.author.username + " looks like the site associated with " + sub.link + " is not supported.\nTo see the currently supported sites, run: !sb supported");
                }
            }else{
                incorrect=true;
            }
        }else if(cmd[1] === "unsubscribe"){

            let subscriptionName = cmd[2];
            
            if(subscriptionName){
                getMongoConnection().then((mongo)=>{
                    let collection = getCollection(mongo);
                    if(subscriptionName === "!all"){
                        collection.remove({"user.id":message.author.id});
                        message.channel.send("All subscriptions for user " + message.author.username + " have been deleted!");
                    }else{
                        collection.remove({"user.id":message.author.id,"name":subscriptionName});
                        message.channel.send(message.author.username + "'s subcription with name " + subscriptionName + " has been deleted!");
                    }
                });
            }else{
                incorrect=true;
            }
        }else if(cmd[1] === "list"){
            getMongoConnection().then((mongo)=>{
                let collection = getCollection(mongo);
                collection.find({"user.id":message.author.id}).toArray((err,res)=>{
                    let userSubscriptions = res.map(e=>e);
                    let msg=message.author.username + " you have the following subscriptions:\n"
                    for(sub of userSubscriptions){
                        msg+=sub.name + " " + sub.link + "\n"
                    }
                    message.channel.send(msg);
                });
            });
        }else if(cmd[1] === "supported"){
            let msg = "The following sites are currently supported:\n"
            for(site of sites){
                msg+=site.name + "\n";
            }
            message.channel.send(msg);
        }else{
            incorrect = true;
        }
        if(incorrect)message.channel.send("USAGE:\n    !sb subscribe <subscription name> <subscription link>\n    !sb unsubscribe <subscription name>\n    !sb list\n    !sb supported");
    }
});


client.login(getProperty("discord.bot.token"));

