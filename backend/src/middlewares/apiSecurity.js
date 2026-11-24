const rateLimit = require('express-rate-limit');
const logger = require('../config/logger');

/**
 * General API rate limiter - applies to all /apis routes
 * 1000 requests per 15 minutes per IP (skips login & auth endpoints)
 */
const generalRateLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 1000,
    skip: (req) => {
        // Never rate limit login or auth endpoints
        const url = req.originalUrl || req.url || req.path;
        return url.includes('/login') || url.includes('/auth') || url.includes('/forgot-password') || url.includes('/reset-password') || url.includes('/verify-email');
    },
    message: {
        responseType: "F",
        responseValue: { message: "Too many requests from this IP. Please try again later." }
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
        res.status(429).json({
            responseType: "F",
            responseValue: { message: "Too many requests. Please try again after 15 minutes." }
        });
    }
});

/**
 * Middleware to validate API secret key
 * Requires X-API-Key header with valid secret
 */
function validateApiKey(req, res, next) {
    const apiKey = req.headers['x-api-key'] || req.headers['X-API-Key'];
    const validApiKey = process.env.API_SECRET_KEY;

    if (!validApiKey) {
        logger.error('API_SECRET_KEY is not set in environment variables');
        return res.status(500).json({
            responseType: "F",
            responseValue: { message: "Server configuration error." }
        });
    }

    if (!apiKey) {
        return res.status(401).json({
            responseType: "F",
            responseValue: { message: "API key is required. Please include X-API-Key header." }
        });
    }

    if (apiKey !== validApiKey) {
        return res.status(403).json({
            responseType: "F",
            responseValue: { message: "Invalid API key. Access denied." }
        });
    }

    next();
}

/**
 * Rate limiter for registration endpoint
 * Limits to 5 registration attempts per IP per 15 minutes
 */
const registrationRateLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // Limit each IP to 5 requests per windowMs
    message: {
        responseType: "F",
        responseValue: { message: "Too many registration attempts. Please try again later." }
    },
    standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
    legacyHeaders: false, // Disable the `X-RateLimit-*` headers
    handler: (req, res) => {
        res.status(429).json({
            responseType: "F",
            responseValue: { message: "Too many registration attempts from this IP. Please try again after 15 minutes." }
        });
    }
});

/**
 * Optional: Validate request origin (if you want to restrict to specific domains)
 * Set ALLOWED_ORIGINS in .env as comma-separated list: "https://yourapp.com,https://www.yourapp.com"
 */
function validateOrigin(req, res, next) {
    const allowedOrigins = process.env.ALLOWED_ORIGINS;
    
    // If no allowed origins configured, skip validation
    if (!allowedOrigins) {
        return next();
    }

    const origin = req.headers.origin || req.headers.referer;
    const originList = allowedOrigins.split(',').map(o => o.trim());

    // Allow requests without origin (like Postman, direct API calls with API key)
    if (!origin) {
        return next();
    }

    const isAllowed = originList.some(allowedOrigin => {
        return origin.startsWith(allowedOrigin);
    });

    if (!isAllowed) {
        return res.status(403).json({
            responseType: "F",
            responseValue: { message: "Request origin not allowed." }
        });
    }

    next();
}

/**
 * Known AI training / scraping / site-cloning crawlers, matched against the
 * User-Agent. These identify themselves by name, so the test is a plain
 * substring match (case-insensitive) and never hits the Flutter app, which
 * sends a "Dart/..." User-Agent, or ordinary browsers.
 *
 * This is the server-side counterpart to the website's robots.txt block —
 * robots.txt is advisory, this one actually refuses the request.
 */
const AI_BOT_UA_PATTERN = new RegExp(
    [
        'GPTBot',
        'ChatGPT-User',           // only when you want to block agent fetches too
        'OAI-SearchBot',
        'ClaudeBot',
        'anthropic-ai',
        'Claude-Web',
        'CCBot',
        'Google-Extended',
        'Applebot-Extended',
        'Bytespider',
        'Amazonbot',
        'Meta-ExternalAgent',
        'Meta-ExternalFetcher',
        'FacebookBot',
        'cohere-ai',
        'Diffbot',
        'Omgili',
        'ImagesiftBot',
        'PerplexityBot',
        'YouBot',
        'Timpibot',
        'Scrapy',
        'python-requests',        // common scraping client
    ].join('|'),
    'i'
);

/**
 * Blocks requests from known AI crawlers / scrapers by User-Agent.
 * Set DISABLE_AI_BOT_GUARD=true in .env to turn it off if it ever misfires.
 */
function aiBotGuard(req, res, next) {
    if (process.env.DISABLE_AI_BOT_GUARD === 'true') return next();

    const ua = req.headers['user-agent'] || '';
    if (ua && AI_BOT_UA_PATTERN.test(ua)) {
        logger.warn(`Blocked AI/scraper bot: ${ua} -> ${req.method} ${req.originalUrl}`);
        return res.status(403).json({
            responseType: 'F',
            responseValue: { message: 'Automated access is not allowed.' }
        });
    }
    next();
}

/**
 * Tells search engines and AI crawlers not to index, follow, archive or
 * snippet API responses. Applied globally; harmless to the mobile app.
 */
function noIndexHeader(req, res, next) {
    res.setHeader('X-Robots-Tag', 'noindex, nofollow, noarchive, nosnippet');
    next();
}

module.exports = {
    generalRateLimiter,
    validateApiKey,
    registrationRateLimiter,
    validateOrigin,
    aiBotGuard,
    noIndexHeader
};
