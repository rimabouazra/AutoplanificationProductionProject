const jwt = require('jsonwebtoken');
const User = require('../models/User');

const jwtConfig = {
  expiresIn: '1h',
  issuer: 'your-app-name'
};

// Middleware d'authentification
exports.authenticateToken = (req, res, next) => {
  console.log('Environment JWT_SECRET:', process.env.JWT_SECRET); // Debug
  console.log('Headers reçus:', req.headers); // DEBUG
  const authHeader = req.headers['authorization'] || 
  req.headers['Authorization'] ||
  req.get('authorization') || 
  req.get('Authorization');
  console.log('🔍 Raw headers:', req.headers);
  console.log('Header Authorization complet:', authHeader);//Debug
  const token = authHeader && authHeader.split(' ')[1];
  console.log('Token reçu:', token); // Debug
  if (!token) {
    console.log('Aucun token trouvé dans les headers');
    return res.sendStatus(401);
  }
  // Debug: Vérifiez que le secret est bien disponible
  if (!process.env.JWT_SECRET) {
    console.error('ERREUR CRITIQUE: JWT_SECRET non défini');
    return res.status(500).json({ message: "Erreur de configuration serveur" });
  }

  jwt.verify(token, process.env.JWT_SECRET, async (err, decoded) => {
    if (err) {
      console.error('Erreur de vérification JWT:', err); // Debug
      console.error('Secret utilisé:', process.env.JWT_SECRET); // Debug
      return res.sendStatus(403);
    }
    console.log('Décodé JWT:', decoded);
    try {
      const user = await User.findById(decoded.id).select('-motDePasse');      console.log('Utilisateur trouvé:', user); // Debug
      if (!user) {
        console.error('Utilisateur non trouvé pour ID:', decoded._id);//Debug
        return res.sendStatus(403);
      }
      
      req.user = user;
      next();
    } catch (error) {
      console.error('Erreur:', error); // Debug
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