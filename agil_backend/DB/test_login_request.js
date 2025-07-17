const http = require('http');

const data = JSON.stringify({
    email: 'test@example.com',
    password: 'password123'
});

const options = {
    hostname: 'localhost',
    port: 8000,
    path: '/api/login',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
    }
};

console.log('Sending login request...');
console.log('Request data:', JSON.parse(data));

const req = http.request(options, (res) => {
    let responseBody = '';
    
    console.log('Status Code:', res.statusCode);
    console.log('Headers:', res.headers);
    
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
        } catch (e) {
            console.log('\nRaw response:', responseBody);
        }
    });
});

req.on('error', (error) => {
    console.error('Error:', error.message);
});

req.write(data);
req.end();
