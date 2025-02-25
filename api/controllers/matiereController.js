const Matiere = require("../models/matiere");

// Ajouter une matière
exports.addMatiere = async (req, res) => {
  try {
    const { reference, couleur, quantite } = req.body;
    const newMatiere = new Matiere({ reference, couleur, quantite });
    await newMatiere.save();
    res.status(201).json({ message: "Matière ajoutée avec succès", matiere: newMatiere });
  } catch (error) {
    res.status(500).json({ message: "Erreur lors de l'ajout de la matière", error });
  }
};

// Obtenir toutes les matières
exports.getMatieres = async (req, res) => {
  try {
    const matieres = await Matiere.find();
    res.status(200).json(matieres);
  } catch (error) {
    res.status(500).json({ message: "Erreur lors de la récupération des matières", error });
  }
};

// Supprimer une matière par ID
exports.deleteMatiere = async (req, res) => {
  try {
    const { id } = req.params;
    await Matiere.findByIdAndDelete(id);
    res.status(200).json({ message: "Matière supprimée avec succès" });
  } catch (error) {
    res.status(500).json({ message: "Erreur lors de la suppression de la matière", error });
  }
};

exports.updateMatiere = async (req, res) => {
    try {
        const { id } = req.params;
        const { quantite } = req.body;

        const matiere = await Matiere.findById(id);
        if (!matiere) {
            return res.status(404).json({ message: "Matière non trouvée" });
        }

        matiere.quantite = quantite; // Mise à jour de la quantité
        await matiere.save();

        res.status(200).json(matiere);
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error });
    }
};
