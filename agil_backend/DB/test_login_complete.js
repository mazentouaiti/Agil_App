const { MongoClient } = require('mongodb');
const http = require('http');

async function createTestUser() {
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
            console.log('Test user created successfully');
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
        console.error('MongoDB Error:', err);
    } finally {
        await client.close();
    }
}

async function checkServer() {
    return new Promise((resolve, reject) => {
        const req = http.get('http://localhost:8000', (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                resolve(true);
            });
        });
        req.on('error', () => {
            resolve(false);
        });
        req.end();
    });
}

function testLogin() {
    return new Promise(async (resolve, reject) => {
        // Check if server is running
        const serverRunning = await checkServer();
        if (!serverRunning) {
            console.error('\nERROR: Server is not running!');
            console.log('Please start the server first with:');
            console.log('1. Open a new terminal window');
            console.log('2. Run: cd "c:\\Users\\touai\\Projects\\flutter agil\\agil_app\\agil_backend\\DB"');
            console.log('3. Run: node index.js');
            console.log('4. Wait for "Server running" message');
            console.log('5. Then run this test script again in another terminal');
            reject(new Error('Server is not running'));
            return;
        }

        const data = JSON.stringify({
            email: 'test@example.com',
            password: 'password123'
        });

        const options = {
            hostname: 'localhost',
            port: 8000,
            path: '/login',  // Updated path to match server route
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
        };

        console.log('\nTesting login...');
        console.log('Request data:', JSON.parse(data));

        const req = http.request(options, (res) => {
            let responseBody = '';
            
            console.log('Response Status:', res.statusCode);
            console.log('Response Headers:', res.headers);
            
            res.on('data', (chunk) => {
                responseBody += chunk;
            });
            
            res.on('end', () => {
                try {
                    const parsedResponse = JSON.parse(responseBody);
                    console.log('\nResponse body:', {
                        ...parsedResponse,
                        access: parsedResponse.access ? `[${parsedResponse.access.length} chars]` : null
                    });
                    
                    if (res.statusCode !== 200) {
                        console.error(`\n✗ Server returned status ${res.statusCode}`);
                        reject(new Error(parsedResponse.message || 'Server error'));
                        return;
                    }
                    
                    resolve(parsedResponse);
                } catch (e) {
                    console.log('\nRaw response:', responseBody);
                    reject(e);
                }
            });
        });

        req.on('error', (error) => {
            console.error('Request Error:', error.message);
            reject(error);
        });

        req.write(data);
        req.end();
    });
}

async function main() {
    try {
        console.log('Step 1: Creating test user if needed...');
        await createTestUser();
        
        console.log('\nStep 2: Testing login endpoint...');
        const loginResult = await testLogin();
        
        console.log('\nTest completed!');
        if (loginResult.success) {
            console.log('✓ Login successful');
            console.log('✓ Token received');
            console.log('✓ User data received');
        } else {
            console.log('✗ Login failed:', loginResult.message);
        }
    } catch (error) {
        console.error('\nTest failed:', error.message);
    }
}

main();
