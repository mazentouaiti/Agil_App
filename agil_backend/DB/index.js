const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');

const app = express();

// CORS configuration
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Body parser middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Basic route to test if server is running
app.get('/', (req, res) => {
  res.json({ message: 'Express backend is running!' });
});

const uri = 'mongodb://localhost:27017';
const client = new MongoClient(uri);
let users;
let isConnected = false;

async function connectDB() {
  try {
    await client.connect();
    console.log('Connected to MongoDB');
    const db = client.db('agil');
    users = db.collection('users');
    console.log('Users collection initialized');
    isConnected = true;
  } catch (err) {
    console.error('MongoDB connection error:', err);
    isConnected = false;
    // Try to reconnect after 5 seconds
    setTimeout(connectDB, 5000);
  }
}

connectDB();

app.post('/api/signup', async (req, res) => {
  try {
    console.log('Received signup request:', req.body);
    const { username, email, password, phone, full_name } = req.body;
    
    // Validate required fields
    if (!username || !email || !password || !phone || !full_name) {
      console.log('Missing required fields:', {
        hasUsername: !!username,
        hasEmail: !!email,
        hasPassword: !!password,
        hasPhone: !!phone,
        hasFullName: !!full_name
      });
      return res.status(400).json({ 
        message: 'All fields are required' 
      });
    }

    console.log('Checking if user exists with email:', email);
    // Check if user already exists
    const exists = await users.findOne({ email });
    if (exists) {
      console.log('User already exists with email:', email);
      return res.status(400).json({ 
        message: 'Email already exists' 
      });
    }

    // Create new user
    const user = {
      username,
      email,
      password,
      phone,
      full_name,
      created_at: new Date()
    };
    console.log('Creating new user:', { ...user, password: '[REDACTED]' });

    await users.insertOne(user);
    console.log('User created successfully');
    res.status(201).json({ 
      message: 'Account created successfully!' 
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ 
      message: 'An error occurred during signup' 
    });
  }
});

app.post('/api/login/', async (req, res) => {
  try {
    if (!isConnected) {
      console.error('MongoDB is not connected');
      return res.status(500).json({
        success: false,
        message: 'Database connection error'
      });
    }

    console.log('Login request received:', { ...req.body, password: '[REDACTED]' });
    const { email, password } = req.body;
    
    if (!email || !password) {
      console.log('Missing required fields:', { hasEmail: !!email, hasPassword: !!password });
      return res.status(400).json({ 
        success: false,
        message: 'Email and password are required'
      });
    }

    console.log('Looking for user with email:', email);
    const user = await users.findOne({ email, password });
    console.log('User search result:', user ? 'Found' : 'Not found');
    
    if (!user) {
      return res.status(401).json({ 
        success: false,
        message: 'Email ou mot de passe incorrect'
      });
    }

    try {
      // Generate token with additional user info
      const tokenData = {
        uid: user._id.toString(),
        email: user.email,
        timestamp: Date.now()
      };
      const tokenString = JSON.stringify(tokenData);
      const token = Buffer.from(tokenString).toString('base64');
      console.log('Token generated successfully:', { length: token.length });

      const responseData = {
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

      // Verify response data
      if (!responseData.access) {
        throw new Error('Token missing from response data');
      }

      console.log('Sending response:', {
        success: responseData.success,
        hasToken: !!responseData.access,
        tokenLength: responseData.access.length,
        hasUser: !!responseData.user
      });

      return res.status(200).json(responseData);
    } catch (tokenError) {
      console.error('Token generation error:', tokenError);
      return res.status(500).json({
        success: false,
        message: 'Error generating authentication token'
      });
    }
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).json({ 
      success: false,
      message: 'An error occurred during login'
    });
  }
});

app.get('/', (req, res) => {
  res.json({ message: 'Express backend is running!' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    message: 'Something went wrong!' 
  });
});

// Handle 404 errors
app.use((req, res) => {
  res.status(404).json({ 
    message: 'Route not found' 
  });
});

app.listen(8000, () => {
  console.log('Server running on http://localhost:8000');
});
