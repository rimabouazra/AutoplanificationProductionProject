const Produits = require("../models/produits");
const Modele = require("../models/modele");


exports.addProduit = async (req, res) => {
    try {
        const { modeleId, tailles } = req.body;  // Attends un tableau de tailles

        // Vérifier que le modèle existe
        const modele = await Modele.findById(modeleId);
        if (!modele) {
            return res.status(404).json({ message: "Modèle non trouvé" });
        }

        // Créer un produit avec plusieurs tailles
        const newProduit = new Produits({
            modele: modeleId,
            tailles: tailles  // Attendu comme tableau de tailles
        });

        await newProduit.save();
        res.status(201).json(newProduit);
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};


exports.getAllProduits = async (req, res) => {
    try {
        const produits = await Produits.find()
            .populate("modele")
            .populate("tailles.matiere");  // Ajout pour inclure la matière
        res.status(200).json(produits);
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};



exports.getProduitById = async (req, res) => {
    try {
        const { id } = req.params;
        const produit = await Produits.findById(id).populate("modele");
        if (!produit) return res.status(404).json({ message: "Produit non trouvé" });

        res.status(200).json({ id: produit._id, modele: produit.modele.nom });
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};


exports.updateProduit = async (req, res) => {
    try {
        const { id } = req.params;
        const updatedData = req.body;

        const produit = await Produits.findByIdAndUpdate(id, updatedData, { new: true });
        if (!produit) return res.status(404).json({ message: "Produit non trouvé" });

        res.status(200).json(produit);
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};

exports.deleteProduit = async (req, res) => {
    try {
        const { id } = req.params;
        const produit = await Produits.findByIdAndDelete(id);
        if (!produit) return res.status(404).json({ message: "Produit non trouvé" });

        res.status(200).json({ message: "Produit supprimé avec succès" });
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};

