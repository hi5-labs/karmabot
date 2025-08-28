// Connect to MongoDB and create indexes
db = db.getSiblingDB('karmabot');

// Create indexes for better performance
db.karmabot.createIndex({ "expires": 1 }, { expireAfterSeconds: 0 });
db.karmabot.createIndex({ "subject": 1 });
db.karmabot.createIndex({ "type": 1 });
db.karmabot.createIndex({ "gifter": 1 });
db.karmabot.createIndex({ "date": 1 });
