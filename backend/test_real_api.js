const request = require('supertest');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
// The app must be exported from server.js. If not, we can construct one or just run a manual fetch using fetch/axios against the running server.

// Let's just use native fetch against the locally running server on port 5001.
(async () => {
    try {
        // First login
        const loginRes = await fetch('http://127.0.0.1:5001/api/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: 'admin@flowdesk.com', password: 'password123' })
        });
        
        if (!loginRes.ok) {
            console.log('Login failed:', loginRes.status, await loginRes.text());
            process.exit(1);
        }
        const authData = await loginRes.json();
        const token = authData.token;
        console.log('Logged in, got token.');
        
        // Fetch jobs filter
        const filterRes = await fetch('http://127.0.0.1:5001/api/jobs/filter', {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        
        console.log('Filter API status:', filterRes.status);
        const jobs = await filterRes.json();
        console.log(`Fetched ${jobs.length} jobs.`);
        if (jobs.length > 0) {
            console.log('First job status:', jobs[0].status);
        } else {
            console.log('Empty jobs array:', jobs);
        }
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
})();
