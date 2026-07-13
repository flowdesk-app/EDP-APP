require('dotenv').config({ path: __dirname + '/../.env' });

async function test() {
  try {
    const loginRes = await fetch('http://localhost:5001/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'siddarth@flowdesk.in', password: 'password123' })
    });
    const loginData = await loginRes.json();
    const token = loginData.token;

    const res = await fetch('http://localhost:5001/api/spares', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-auth-token': token },
      body: JSON.stringify({
        partNumber: '1417',
        quantity: 12,
        description: '200x4',
        jobType: 'New'
      })
    });
    
    if (res.ok) {
      console.log("Success:", await res.json());
    } else {
      console.error("Error:", res.status, await res.text());
    }
  } catch (err) {
    console.error("Network Error:", err.message);
  }
}
test();
