const dotenv = require("dotenv");
const path = require('path');

const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const envPath = path.resolve(__dirname, '.env');
const result = dotenv.config({ path: envPath });
// Routes
const commandeRoutes = require("./routes/commandeRoutes");
const salleRoutes = require("./routes/salleRoutes");
const modeleRoutes = require("./routes/modeleRoutes");
const machineRoutes = require("./routes/machineRoutes");
const matiereRoutes = require("./routes/matiereRoutes");
const produitsRoutes = require("./routes/produitsRoutes");
const planificationRoutes = require("./routes/planificationRoutes");
const clientRoutes = require("./routes/clientRoutes");
const UserRoutes = require("./routes/userRoutes");

//dotenv.config();

const app = express();

// Middleware
app.use(helmet());
app.use(express.json());
app.use(cors());
//TEST
if (result.error) {
  console.error('Erreur de chargement du .env:', result.error);
} else {
  console.log('Configuration .env chargée:', {
    JWT_SECRET: process.env.JWT_SECRET ? 'défini' : 'non défini',
    MONGO_URI: process.env.MONGO_URI ? 'défini' : 'non défini'
  });
} 

// Rate limiter pour auth uniquement
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: {
    status: 429,
    error: "Trop de requêtes. Réessaie plus tard.",
  },
});
app.use("/api/Users", authLimiter);
// Routes
app.use("/api/commandes", commandeRoutes);
app.use("/api/salles", salleRoutes);
app.use("/api/modeles", modeleRoutes);
app.use("/api/machines", machineRoutes);
app.use("/api/matieres", matiereRoutes);
app.use("/api/produits", produitsRoutes);
app.use("/api/planifications", planificationRoutes);
app.use("/api/Users", UserRoutes);

app.get("/", (req, res) => {
  res.send("API Running...");
});

const uri = "mongodb+srv://mayarabouazra:O3DXC206BrDTWUr0@clustercoque.vhlic.mongodb.net/?retryWrites=true&w=majority&appName=clusterCoque";
//const uri = process.env.MONGO_URI;

 mongoose.connect(uri, {
   useNewUrlParser: true,
   useUnifiedTopology: true,
 })
 .then(() => console.log("Connected to MongoDB successfully!"))
 .catch((err) => console.error("MongoDB connection error:", err));

// Gestion globale des erreurs
app.use((err, req, res, next) => {
  console.error("Erreur serveur :", err.stack);
  res.status(500).json({ message: "Erreur interne du serveur." });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
