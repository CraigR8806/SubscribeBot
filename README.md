# SubscribeBot
This is a discord bot that allows users to subscribe to different webpages.  When defined events occur, the user will get a discord message with information associated with the events.  (e.g. Events might be a new record added to the site, or a change of status to a record)

This is mainly built for a RHEL enviornment and can most easily installed there.<br>
Some tweaks may be required to get this into another distro, but I was able to successfully install this on a Raspberry PI 4 running Ubuntu 18.04.4 Arm64

Before installation, you need to create a properties/app.properties<br>
There is a default template for this property sheet located at properties/.app.properties<br>
You can copy that file to app.properties<br>
Add your discord bot token<br>
Update the admin and app db user password fields<br>
And you should be ready to run the install script

To install all of the necesary components for the bot to run, run bin/install.sh<br>
You may need to fiddle with getting the right version of mongodb-org, node and npm depending on your environment

To verify that mongo installed properly, you can run:<br>
mongo --port \<your port\> -u \<your app user username\> -p \<your app user password\> --authenticationDatabase \<your application database name\><br>
If you can properly authenticate with the designated user on the application database, mongo was successfully installed and configured

At this point, you should be able to start the application<br>
Run bin/start.sh<br>
The output for the discord bot will be recorded in logs/bot.log

To safely stop the application, run bin/stop.js

------------------------------------------------------------------------------
---------------------- Defining New Sites ------------------------------------
------------------------------------------------------------------------------

One of the really neat features of this bot is that it allows you to easily define support for new sites<br>
Site definitions are located within sites/<br>
The required fields and functions are required for new site definitions<br>
&nbsp;&nbsp;&nbsp;&nbsp;field {name} - This is the name of the site (This is used when a user queries the supported sites using !sb supported)<br>
&nbsp;&nbsp;&nbsp;&nbsp;field {urlpattern} - This is a regular expression that is used to determine if a user supplied link is associated with this site defnition<br>
&nbsp;&nbsp;&nbsp;&nbsp;function {getRecords(link, file) return array} - This function defines how to scrape the site to extract the desired information<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;link - is the link that the user supplies that is intended to be scraped<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;file - is a file that will be used as a temporary parking place for the HTML that is pulled from the site<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return array - the return value must be a JSON array containing the desired information from the site<br>
&nbsp;&nbsp;&nbsp;&nbsp;function {getNotificationList(thisCheck, lastCheck) return array} - This function compares the current state of the site vs the previous state<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;thisCheck - is a JSON array containing the current results of getRecords<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;lastCheck - is a JSON array containing the previous results of getRecords<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return array - the return value must be a JSON array containing the records that are intended to be relayed back to the user<br>
&nbsp;&nbsp;&nbsp;&nbsp;function {composeEmbeddedMessage:(sub, notificationList) return embeddedMessage - This function creates an embeded message from the supplied notificationList<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sub - this is the full subscription object that is stored in mongodb<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;notificationList - This is the value returned from getNotificationList<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return embeddedMessage - The return value must be a discord embedded message<br>

For reference, you can take a look at sites/craiglist.js to see how to properly compose a site definition

All you need to do to integrate a new site definition is to place it in the sites folder<br>
The code automatically reloads the sites every time the interval executes, a user issues a subscribe request, or a user issues the supported request<br>
So you don't even need to restart the bot to add functionality :)
