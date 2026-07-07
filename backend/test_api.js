const http = require('http');

async function run() {
  const loginRes = await fetch('http://localhost:5001/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'admin@flowdesk.com', password: 'password123' })
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
      "jobId": "JOB-12345",
      "jobType": "New",
      "customerOrderDate": "2026-06-27T10:00:00.000Z",
      "purchaseOrderReceived": false,
      "purchaseOrderDate": null,
      "purchaseOrderNumber": null,
      "poNotGiven": true,
      "status": "Blank Order",
      "currentLocation": "EDP",
      "createdDate": "2026-06-27T10:00:00.000Z",
      "quantity": null,
      "partNumber": null
    })
  });
  console.log("CREATE JOB STATUS:", jobRes.status);
  const text = await jobRes.text();
  console.log("RESPONSE:", text);
}
run();
