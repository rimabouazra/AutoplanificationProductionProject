const express = require("express");
const mongoose = require("mongoose");
const dotenv = require("dotenv");
const cors = require("cors");

const commandeRoutes = require("./routes/commandeRoutes");
const salleRoutes = require("./routes/salleRoutes");
const modeleRoutes = require("./routes/modeleRoutes");
const machineRoutes = require("./routes/machineRoutes");
const matiereRoutes = require("./routes/matiereRoutes");

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

// Connexion à MongoDB
mongoose.connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => console.log("MongoDB Connected...:)"))
.catch(err => console.log(err));

// Routes
app.get("/", (req, res) => {
    res.send("API Running...");
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
