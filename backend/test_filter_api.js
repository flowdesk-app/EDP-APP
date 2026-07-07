const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const jwt = require('jsonwebtoken');
const request = require('supertest');
const jobsRouter = require('./routes/jobs');

dotenv.config();

const app = express();
app.use(express.json());
// Mock auth middleware for testing
app.use((req, res, next) => {
    req.user = { id: new mongoose.Types.ObjectId() };
    next();
});
app.use('/api/jobs', jobsRouter);

const testApi = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/flowdesk');
        const res = await request(app).get('/api/jobs/filter');
        console.log(`Status: ${res.statusCode}`);
        if (res.body && Array.isArray(res.body)) {
            console.log(`Returned ${res.body.length} jobs.`);
            if (res.body.length > 0) console.log(res.body[0].jobId);
        } else {
            console.log('Body:', res.body);
        }
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

testApi();
