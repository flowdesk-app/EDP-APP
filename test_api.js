const http = require('http');

async function run() {
  const loginRes = await fetch('http://localhost:5001/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'admin@edp.com', password: 'password123' })
  });
  const loginData = await loginRes.json();
  const token = loginData.token;
  
  if (!token) {
    console.log("LOGIN FAILED", loginData);
    return;
  }

  const jobRes = await fetch('http://localhost:5001/api/jobs', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
    body: JSON.stringify({
      jobId: 'TEST-126',
      jobType: 'New',
      status: 'Blank Order',
      currentLocation: 'EDP',
      createdAt: new Date().toISOString()
    })
  });
  console.log(jobRes.status);
  console.log(await jobRes.text());
}
run();
