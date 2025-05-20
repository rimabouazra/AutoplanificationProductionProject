const Matiere = require("../models/matiere");

// Ajouter une matière
exports.addMatiere = async (req, res) => {
  try {
    const { reference, couleur, quantite } = req.body;
    const newMatiere = new Matiere({
        reference,
        couleur,
        quantite,
        historique: [{ action: "ajout", quantite, date: new Date() }]
      });
    await newMatiere.save();
    res.status(201).json({ message: "Matière ajoutée avec succès", matiere: newMatiere });
  } catch (error) {
    res.status(500).json({ message: "Erreur lors de l'ajout de la matière", error });
  }
};

exports.getHistoriqueMatiere = async (req, res) => {
    try {
      const { id } = req.params;
      const matiere = await Matiere.findById(id).select("historique");
      if (!matiere) {
        return res.status(404).json({ message: "Matière non trouvée" });
      }
      res.status(200).json(matiere.historique);
    } catch (error) {
      res.status(500).json({ message: "Erreur lors de la récupération de l'historique", error });
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
      const { quantite, action } = req.body; // action = "ajout" ou "consommation"
      if (!action || !["ajout", "consommation"].includes(action)) {
      return res.status(400).json({ message: "Le champ 'action' est requis et doit être 'ajout' ou 'consommation'" });
    }
      const matiere = await Matiere.findById(id);
      if (!matiere) {
        return res.status(404).json({ message: "Matière introuvable" });
      }
  
      // Enregistrement de l'historique
      matiere.historique.push({ action, quantite, date: new Date() });
  
      // Mise à jour de la quantité
      if (action === "ajout") {
        matiere.quantite += quantite;
      } else if (action === "consommation") {
        if (matiere.quantite < quantite) {
          return res.status(400).json({ message: "Quantité insuffisante" });
        }
        matiere.quantite -= quantite;
      }
  
      await matiere.save();
      res.status(200).json(matiere);
    } catch (error) {
      res.status(500).json({ message: "Erreur lors de la mise à jour de la matière", error });
    }
  };
  
// Renommer une matière
exports.renameMatiere = async (req, res) => {
  try {
    const { id } = req.params;
    const { reference } = req.body;

    if (!reference) {
      return res.status(400).json({ message: "La référence est requise" });
    }

    const matiere = await Matiere.findByIdAndUpdate(
      id,
      { reference },
      { new: true }
    );

    if (!matiere) {
      return res.status(404).json({ message: "Matière non trouvée" });
    }

    res.status(200).json({ message: "Matière renommée avec succès", matiere });
  } catch (error) {
    res.status(500).json({ message: "Erreur lors du renommage de la matière", error });
  }
};