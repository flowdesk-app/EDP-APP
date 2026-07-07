const http = require('http');

async function run() {
  const loginRes = await fetch('http://localhost:5001/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'owner@flowdesk.com', password: 'password123' })
  });
  const loginData = await loginRes.json();
  const token = loginData.token;

  if (!token) {
    // try admin@edp.com? No, what was the email I used before?
    const adminRes = await fetch('http://localhost:5001/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'owner@edp.com', password: 'password123' })
    });
    const adminData = await adminRes.json();
    if (adminData.token) {
      fetchJobs(adminData.token);
    } else {
        console.log("LOGIN FAILED", adminData);
    }
  } else {
    fetchJobs(token);
  }
}

async function fetchJobs(token) {
  const jobRes = await fetch('http://localhost:5001/api/jobs/filter?month=2026-06', {
    method: 'GET',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` }
  });
  const jobs = await jobRes.json();
  console.log(jobs.filter(j => j.status === 'Blank Order').map(j => j.jobId));
}

run();
