const http = require('http');

// Test data
const loginData = {
    email: 'test@example.com',
    password: 'password123'
};

// Colors for console output
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m'
};

function log(message, type = 'info') {
    switch (type) {
        case 'success':
            console.log(colors.green + '✓ ' + message + colors.reset);
            break;
        case 'error':
            console.log(colors.red + '✗ ' + message + colors.reset);
            break;
        case 'warning':
            console.log(colors.yellow + '! ' + message + colors.reset);
            break;
        default:
            console.log(message);
    }
}

// Test if server is running
function testServer() {
    return new Promise((resolve) => {
        const req = http.get('http://localhost:8000/', (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    const response = JSON.parse(data);
                    console.log('Server response:', response);
                    resolve(true);
                } catch (e) {
                    console.log('Failed to parse server response:', data);
                    resolve(false);
                }
            });
        });
        
        req.on('error', (error) => {
            console.log('Error connecting to server:', error.message);
            resolve(false);
        });
        
        req.setTimeout(3000, () => {
            console.log('Server connection timed out');
            req.abort();
            resolve(false);
        });
    });
}

// Try login
function testLogin() {
    return new Promise((resolve, reject) => {
        const data = JSON.stringify(loginData);
        
        const options = {
            hostname: 'localhost',
            port: 8000,
            path: '/login',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
        };

        const req = http.request(options, (res) => {
            let responseData = '';
            
            res.on('data', (chunk) => responseData += chunk);
            res.on('end', () => {
                try {
                    const result = JSON.parse(responseData);
                    resolve({ statusCode: res.statusCode, data: result });
                } catch (e) {
                    reject(new Error('Invalid JSON response: ' + responseData));
                }
            });
        });

        req.on('error', (error) => reject(error));
        req.write(data);
        req.end();
    });
}

async function main() {
    console.log('\n' + colors.bright + 'Testing Login API' + colors.reset + '\n');

    // Check if server is running
    log('Checking if server is running...', 'warning');
    const serverRunning = await testServer();
    
    if (!serverRunning) {
        log('Server is not running!', 'error');
        log('Please start the server first:', 'warning');
        log('1. Open a new terminal');
        log('2. Run: node server.js');
        log('3. Wait for "Server running" message');
        log('4. Run this test script again');
        return;
    }
    
    log('Server is running', 'success');

    // Test login
    try {
        log('\nTesting login with:', 'warning');
        log(JSON.stringify(loginData, null, 2));
        
        const { statusCode, data } = await testLogin();
        
        if (statusCode === 200) {
            if (data.success === true && data.access) {
                log('\nLogin successful!', 'success');
                log('Response:', 'success');
                log(JSON.stringify({
                    success: data.success,
                    message: data.message,
                    access: `[Token length: ${data.access.length}]`,
                    user: data.user
                }, null, 2));
            } else {
                log('\nLogin response missing required fields!', 'error');
                log('Response data:', 'warning');
                log(JSON.stringify({
                    hasSuccess: data.success !== undefined,
                    hasToken: !!data.access,
                    hasUser: !!data.user,
                    response: data
                }, null, 2));
            }
        } else {
            log('\nLogin failed!', 'error');
            log('Status code: ' + statusCode);
            log('Response: ' + JSON.stringify(data, null, 2));
        }
    } catch (error) {
        log('\nTest failed!', 'error');
        log(error.message);
    }
}

main();
