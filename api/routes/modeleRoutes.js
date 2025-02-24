const express = require("express");
const router = express.Router();
const Modele = require("../models/Modele");

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

router.get("/:id", async (req, res) => {
    try {
        const modele = await Modele.findById(req.params.id);
        if (!modele) {
            return res.status(404).json({ message: "Modèle non trouvé" });
        }
        res.status(200).json({ nom: modele.nom });
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
});





router.get("/findByName/:nomModele", async (req, res) => {
    try {
        console.log("Recherche du modèle :", req.params.nomModele);
        const modele = await Modele.findOne({ nom: req.params.nomModele });

        if (!modele) {
            console.log("Modèle non trouvé !");
            return res.status(404).json({ message: "Modèle non trouvé" });
        }

        console.log("Modèle trouvé :", modele);
        res.status(200).json({ id: modele._id });
    } catch (error) {
        console.error("Erreur serveur :", error);
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
});


router.get("/", async (req, res) => {
    try {
        const modeles = await Modele.find();
        res.status(200).json(modeles);
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
});

module.exports = router;
