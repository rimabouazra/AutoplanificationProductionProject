const express = require("express");
const router = express.Router();
const Commande = require("../models/Commande");
const Machine = require("../models/Machine");
const Salle = require("../models/Salle");

const getSalleByCouleur = async (couleur) => {
    const type = ["noir", "gris", "marron"].includes(couleur.toLowerCase()) ? "noir" : "blanc";
    return await Salle.findOne({ type });
};

// Fonction pour trouver une machine disponible
const getMachineDisponible = async (modeles) => {
    return await Machine.findOne({ modelesCompatibles: { $in: modeles }, etat: "disponible" });
};

// Route pour ajouter une commande et l'affecter
router.post("/add", async (req, res) => {
    try {
        console.log("📩 Nouvelle requête POST reçue :", req.body); // Vérifie les données reçues

        if (!req.body.client || !req.body.quantite || !req.body.couleur || !req.body.taille || !req.body.conditionnement || !req.body.delais) {
            return res.status(400).json({ message: "Tous les champs sont requis !" });
        }

        const newCommande = new Commande(req.body);
        await newCommande.save();

        console.log("✅ Commande ajoutée :", newCommande);
        res.status(201).json(newCommande);
    } catch (error) {
        console.error("❌ Erreur lors de l'ajout de la commande :", error); // Affiche l'erreur complète
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
});

// Obtenir toutes les commandes
router.get("/", async (req, res) => {
    try {
        const commandes = await Commande.find();
        res.status(200).json(commandes);
    } catch (err) {
        res.status(500).json(err);
    }
});

// Modifier une commande
router.put("/:id", async (req, res) => {
    try {
        const updatedCommande = await Commande.findByIdAndUpdate(req.params.id, req.body, { new: true });
        res.status(200).json(updatedCommande);
    } catch (err) {
        res.status(500).json(err);
    }
});

// Supprimer une commande
router.delete("/:id", async (req, res) => {
    try {
        await Commande.findByIdAndDelete(req.params.id);
        res.status(200).json("Commande supprimée.");
    } catch (err) {
        res.status(500).json(err);
    }
});

module.exports = router;
