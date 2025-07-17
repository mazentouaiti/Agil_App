const { MongoClient } = require('mongodb');

async function main() {
    const uri = 'mongodb://localhost:27017';
    const client = new MongoClient(uri);

    try {
        await client.connect();
        console.log('Connected to MongoDB');
        
        const db = client.db('agil');
        const users = db.collection('users');

        // Create a test user if it doesn't exist
        const testUser = {
            username: 'testuser',
            email: 'test@example.com',
            password: 'password123',
            phone: '1234567890',
            full_name: 'Test User',
            created_at: new Date()
        };

        const exists = await users.findOne({ email: testUser.email });
        if (!exists) {
            await users.insertOne(testUser);
            console.log('Test user created');
        } else {
            console.log('Test user already exists');
        }

        // List all users
        console.log('\nCurrent users in database:');
        const allUsers = await users.find({}).toArray();
        allUsers.forEach(user => {
            console.log(`- ${user.email} (${user.full_name})`);
        });

    } catch (err) {
        console.error('Error:', err);
    } finally {
        await client.close();
    }
}

main();
