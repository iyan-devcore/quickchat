/**
 * JWT Authentication Middleware
 * 
 * Extracts the Bearer token from the Authorization header,
 * verifies it against JWT_SECRET, and attaches the decoded
 * user payload (userId) to req.user for downstream handlers.
 * 
 * Usage: router.get('/protected', authMiddleware, handler);
 */
const jwt = require('jsonwebtoken');

module.exports = function authMiddleware(req, res, next) {
  try {
    // Extract token from "Bearer <token>" format
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No token provided. Access denied.' });
    }

    const token = authHeader.split(' ')[1];
    
    // Verify and decode the token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Attach user info to the request object
    req.user = { userId: decoded.userId };
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
};
