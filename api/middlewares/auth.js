const jwt = require('jsonwebtoken');
const User = require('../models/User');

const jwtConfig = {
  expiresIn: '1h',
  issuer: 'your-app-name'
};

// Middleware d'authentification
exports.authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.sendStatus(401);

  jwt.verify(token, process.env.JWT_SECRET, async (err, decoded) => {
    if (err) return res.sendStatus(403);
    
    try {
      const user = await User.findById(decoded.id).select('-motDePasse');
      if (!user) return res.sendStatus(403);
      
      req.user = user;
      next();
    } catch (error) {
      res.status(500).json({ message: "Erreur serveur" });
    }
  });
};

// Middleware d'autorisation par rôle
exports.authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ message: "Accès non autorisé" });
    }
    next();
  };
};

// Générateur de token
exports.generateToken = (user) => {
  return jwt.sign(
    {
      id: user._id,
      role: user.role,
      email: user.email
    },
    process.env.JWT_SECRET,
    jwtConfig
  );
};