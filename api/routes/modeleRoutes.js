const express = require("express");
const router = express.Router();
const Modele = require("../models/Modele");

// Ajouter un nouveau modèle
router.post("/add", async (req, res) => {
    try {
        const { nom, tailles } = req.body;
        const newModele = new Modele({ nom, tailles });
        await newModele.save();
        res.status(201).json(newModele);
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
});

// Obtenir tous les modèles
router.get("/", async (req, res) => {
    try {
        const modeles = await Modele.find();
        res.status(200).json(modeles);
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
});

module.exports = router;
