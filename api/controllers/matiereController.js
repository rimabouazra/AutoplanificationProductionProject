const Matiere = require("../models/matiere");

// Ajouter une matière
exports.addMatiere = async (req, res) => {
  try {
    const { reference, couleur, quantite } = req.body;
    const newMatiere = new Matiere({
        reference,
        couleur,
        quantite,
        historique: [{ action: "Ajout", quantite, date: new Date() }]
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
        const { quantite } = req.body;  
        const matiere = await Matiere.findById(id);  

        if (!matiere) {
            return res.status(404).json({ message: "Matière introuvable" });
        }

        // Calcul de la différence (quantité réellement ajoutée ou consommée)
        let difference = quantite; // Par défaut, on suppose que l'utilisateur envoie la quantité à ajouter ou consommer
        let action;

        if (quantite > 0) {  
            action = "Ajout";
            matiere.quantite += quantite;  // Ajout de la quantité
        } else {  
            action = "Consommation";
            difference = Math.abs(quantite);  // Convertir en positif
            if (matiere.quantite < difference) {
                return res.status(400).json({ message: "Quantité insuffisante" });
            }
            matiere.quantite -= difference;  // Soustraction de la quantité
        }

        // Ajout dans l'historique avec la vraie quantité ajoutée/consommée
        matiere.historique.push({ action, quantite: difference, date: new Date() });

        await matiere.save();
        res.status(200).json(matiere);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la mise à jour de la matière", error });
    }
};

  
