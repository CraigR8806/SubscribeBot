db.createUser(
    {
        user: "${mongo.admin.username}", 
        pwd:  "${mongo.admin.password}", 
        roles: [
            {
                role: "userAdminAnyDatabase",
                db:   "admin"
            },
            {
                role: "dbOwner",
                db: "admin"
            },
            {
                role: "clusterAdmin",
                db: "admin"
            },
            "readWriteAnyDatabase"
        ]
    }
)
