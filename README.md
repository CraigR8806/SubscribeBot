# SubscribeBot
This is a discord bot that allows users to subscribe to different webpages.  When defined events occur, the user will get a discord message with information associated with the events.  (e.g. Events might be a new record added to the site, or a change of status to a record)

This is mainly built for a RHEL enviornment and can most easily installed there.
Some tweaks may be required to get this into another distro, but I was able to successfully install this on a Raspberry PI 4 running Ubuntu 18.04.4 Arm64

Before installation, you need to create a properties/app.properties
There is a default template for this property sheet located at properties/.app.properties
You can copy that file to app.properties
Add your discord bot token
Update the admin and app db user password fields
And you should be ready to run the install script

To install all of the necesary components for the bot to run, run bin/install.sh
You may need to fiddle with getting the right version of mongodb-org, node and npm depending on your environment

To verify that mongo installed properly, you can run:
mongo --port <your port> -u <your app user username> -p <your app user password> --authenticationDatabase <your application database name>
If you can properly authenticate with the designated user on the application database, mongo was successfully installed and configured

At this point, you should be able to start the application
Run bin/start.sh
The output for the discord bot will be recorded in logs/bot.log

To safely stop the application, run bin/stop.js

------------------------------------------------------------------------------
---------------------- Defining New Sites ------------------------------------
------------------------------------------------------------------------------

One of the really neat features of this bot is that it allows you to easily define support for new sites
Site definitions are located within sites/
The required fields and functions are required for new site definitions
    field {name} - This is the name of the site (This is used when a user queries the supported sites using !sb supported)
    field {urlpattern} - This is a regular expression that is used to determine if a user supplied link is associated with this site defnition
    function {getRecords(link, file) return array} - This function defines how to scrape the site to extract the desired information
        link - is the link that the user supplies that is intended to be scraped
        file - is a file that will be used as a temporary parking place for the HTML that is pulled from the site
        return array - the return value must be a JSON array containing the desired information from the site
    function {getNotificationList(thisCheck, lastCheck) return array} - This function compares the current state of the site vs the previous state
        thisCheck - is a JSON array containing the current results of getRecords
        lastCheck - is a JSON array containing the previous results of getRecords
        return array - the return value must be a JSON array containing the records that are intended to be relayed back to the user
    function {composeEmbeddedMessage:(sub, notificationList) return embeddedMessage - This function creates an embeded message from the supplied notificationList
        sub - this is the full subscription object that is stored in mongodb
        notificationList - This is the value returned from getNotificationList
        return embeddedMessage - The return value must be a discord embedded message

For reference, you can take a look at sites/craiglist.js to see how to properly compose a site definition

All you need to do to integrate a new site definition is to place it in the sites folder
The code automatically reloads the sites every time the interval executes, a user issues a subscribe request, or a user issues the supported request
So you don't even need to restart the bot to add functionality :)
