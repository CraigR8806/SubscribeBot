db.createUser(
    {
        user: "${mongo.app.user.username}", 
        pwd:  "${mongo.app.user.password}", 
        roles: [
            {
                role: "readWrite",
                db:   "${mongo.app.db}"
            }
        ]
    }
)
