const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB setup
const uri = 'mongodb://localhost:27017';
const client = new MongoClient(uri);
let db, users;

// Database connection
async function connectDB() {
    try {
        await client.connect();
        console.log('✓ Connected to MongoDB');
        db = client.db('agil');
        users = db.collection('users');
        console.log('✓ Users collection initialized');
        
        // Ensure test user exists
        const testUser = await users.findOne({ email: 'test@example.com' });
        if (!testUser) {
            await users.insertOne({
                email: 'test@example.com',
                password: 'password123',
                full_name: 'Test User',
                phone: '1234567890',
                created_at: new Date()
            });
            console.log('✓ Test user created');
        } else {
            console.log('✓ Test user already exists');
        }
        return true;
    } catch (err) {
        console.error('✗ MongoDB connection error:', err);
        return false;
    }
}

// Routes
app.get('/test', (req, res) => {
    res.json({ status: 'ok', message: 'Server is running' });
});

// Health check endpoint
app.get('/', (req, res) => {
    res.json({ status: 'ok', message: 'Server is running' });
});

app.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        console.log('\n[LOGIN] Attempt:', { email, timestamp: new Date().toISOString() });

        // Input validation
        if (!email || !password) {
            console.log('✗ Missing required fields:', { email: !!email, password: !!password });
            return res.status(400).json({
                success: false,
                message: 'Email and password are required'
            });
        }

        // Find user
        console.log('➤ Looking for user...');
        const user = await users.findOne({ email, password });
        
        if (!user) {
            console.log('✗ User not found or invalid password');
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password'
            });
        }

        console.log('✓ User authenticated:', { email: user.email, id: user._id.toString() });

        // Generate token with expiration
        const tokenData = {
            id: user._id.toString(),
            email: user.email,
            timestamp: Date.now(),
            exp: Date.now() + (24 * 60 * 60 * 1000) // 24 hours
        };
        const token = Buffer.from(JSON.stringify(tokenData)).toString('base64');
        console.log('✓ Token generated:', { length: token.length });

        // Prepare response
        const response = {
            success: true,
            message: 'Login successful',
            access: token,
            user: {
                id: user._id.toString(),
                email: user.email,
                full_name: user.full_name || '',
                phone: user.phone || ''
            }
        };

        console.log('✓ Sending response:', {
            success: response.success,
            hasToken: !!response.access,
            tokenLength: response.access.length,
            user: { ...response.user, id: user._id.toString() }
        });

        return res.status(200).json(response);
    } catch (error) {
        console.error('✗ Login error:', error);
        return res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

// Start server
async function startServer() {
    const dbConnected = await connectDB();
    if (!dbConnected) {
        console.error('Failed to connect to database. Server not started.');
        process.exit(1);
    }

    const port = 8000;
    app.listen(port, () => {
        console.log(`✓ Server running on http://localhost:${port}`);
        console.log('✓ Test the server with:');
        console.log('  curl http://localhost:8000/test');
    });
}

startServer();
