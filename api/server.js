const express = require("express");
const mongoose = require("mongoose");
const dotenv = require("dotenv");
const cors = require("cors");

const commandeRoutes = require("./routes/commandeRoutes");
const salleRoutes = require("./routes/salleRoutes");
const modeleRoutes = require("./routes/modeleRoutes");
const machineRoutes = require("./routes/machineRoutes");
const matiereRoutes = require("./routes/matiereRoutes");
const produitsRoutes = require("./routes/produitsRoutes");
const planificationRoutes = require("./routes/planificationRoutes");
const UserRoutes = require("./routes/userRoutes");

dotenv.config();

const app = express();

// Middleware
app.use(express.json());
app.use(cors());

app.use("/api/commandes", commandeRoutes);
app.use("/api/salles", salleRoutes);
app.use("/api/modeles", modeleRoutes);
app.use("/api/machines", machineRoutes);
app.use("/api/matieres", matiereRoutes);
app.use("/api/produits", produitsRoutes);
app.use("/api/planifications", planificationRoutes);
app.use("/api/Users", UserRoutes);

const uri = "mongodb+srv://mayarabouazra:O3DXC206BrDTWUr0@clustercoque.vhlic.mongodb.net/?retryWrites=true&w=majority&appName=clusterCoque";

 mongoose.connect(uri, {
   useNewUrlParser: true,
   useUnifiedTopology: true,
 })
 .then(() => console.log("Connected to MongoDB successfully!"))
 .catch((err) => console.error("MongoDB connection error:", err));

// Routes
app.get("/", (req, res) => {
    res.send("API Running...");
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
