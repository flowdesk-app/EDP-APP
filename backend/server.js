const express = require('express');
const path = require('path');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const hpp = require('hpp');
const rateLimit = require('express-rate-limit');
const connectDB = require('./config/db');
// require('./cron'); // Initialize cron jobs (DISABLED: delayed logic removed)
const hashExistingPasswords = require('./scripts/hashPasswords');

dotenv.config();

// Connect DB and then run migrations
connectDB().then(() => {
    hashExistingPasswords();
});

const app = express();
app.set('trust proxy', 1); // Required for rate limiting behind Render's reverse proxy

// Set security HTTP headers (disable CSP for Flutter Web compatibility)
app.use(helmet({
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false,
}));

// Enable CORS
app.use(cors());

// Body parser, reading data from body into req.body
app.use(express.json({ limit: '10kb' }));

// Prevent parameter pollution
app.use(hpp());

// Rate limiting: 100 requests per 10 mins for all API routes
const limiter = rateLimit({
    max: 1000, // 1000 requests to accommodate Flutter app loading assets via API if any
    windowMs: 10 * 60 * 1000,
    message: 'Too many requests from this IP, please try again in 10 minutes!'
});
app.use('/api', limiter);

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/jobs', require('./routes/jobs'));
app.use('/api/suppliers', require('./routes/suppliers'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/parts', require('./routes/parts'));
app.use('/api/movements', require('./routes/movements'));
app.use('/api/dashboard', require('./routes/dashboard'));
app.use('/api/logistics', require('./routes/logistics'));
app.use('/api/binbox', require('./routes/binbox'));
app.use('/api/spare-suppliers', require('./routes/spareSuppliers'));
app.use('/api/customers', require('./routes/customers'));
app.use('/api/leads', require('./routes/leads'));

app.use('/api/master-data', require('./routes/masterData'));
app.use('/api/spares', require('./routes/spares'));

// Serve static files from the public folder (Flutter Web App)
app.use(express.static(path.join(__dirname, 'public')));

// Catch-all route to serve index.html for Flutter's web routing
app.use((req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

const PORT = process.env.PORT || 5001;

app.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT}`));
