const Modele = require("../models/Modele");
const Matiere = require("../models/matiere");

exports.addModele = async (req, res) => {
  try {
    const { nom, tailles, bases, consommation, taillesBases, description } = req.body;

    // Vérifier si les bases existent
    let baseModels = [];
    if (bases && bases.length > 0) {
      baseModels = await Modele.find({ nom: { $in: bases } });
      if (baseModels.length !== bases.length) {
        return res.status(404).json({ message: "Une ou plusieurs bases non trouvées" });
      }
    }

    // Formater les taillesBases
    const formattedTaillesBases = taillesBases.map(tb => {
      const baseModel = baseModels.find(b => b._id.toString() === tb.baseId);
      return {
        baseId: baseModel ? baseModel._id : null,
        tailles: tb.tailles
      };
    });

    const newModele = new Modele({
      nom,
      tailles,
      bases: baseModels.map(b => b._id),
      taillesBases: formattedTaillesBases,
      description,
      consommation: consommation || tailles.map(taille => ({
        taille: taille,
        quantite: 0
      }))
    });

    await newModele.save();
    res.status(201).json(newModele);
  } catch (error) {
    res.status(500).json({ message: "Erreur serveur", error: error.message });
  }
};

exports.getModeleById = async (req, res) => {
    try {
        const { id } = req.params;
        const modele = await Modele.findById(id).populate("matiere").populate("bases");
        if (!modele) return res.status(404).json({ message: "Modèle non trouvé" });
        if (!modele.consommation || modele.consommation.length === 0) {
            modele.consommation = modele.tailles.map(taille => ({
                taille: taille,
                quantite: 0
            }));
        }
        if (modele.bases && modele.bases.length > 0) {
            modele.taillesBases = modele.bases.map(base => ({
                baseId: base._id,
                tailles: modele.tailles.map((taille, index) => base.tailles[index] || "?")
            }));
        }
        res.status(200).json(modele);
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};


exports.getModeleByName = async (req, res) => {
    try {
        const { nomModele } = req.params;
        const modele = await Modele.findOne({ nom: nomModele }).populate("matiere").populate("bases");
        if (!modele) return res.status(404).json({ message: "Modèle non trouvé" });

        res.status(200).json(modele);
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};

exports.getAllModeles = async (req, res) => {
    try {
        const modeles = await Modele.find().populate("matiere").populate("bases");

        // Transformez les bases en modèles dérivés pour le frontend
        const modelesAvecDerives = modeles.map(modele => {
            const modeleObj = modele.toObject();
            if (modele.bases && modele.bases.length > 0) {
                modeleObj.derives = modele.bases; // Utilisez directement les bases peuplées
            } else {
                modeleObj.derives = [];
            }
            return modeleObj;
        });

        res.status(200).json(modelesAvecDerives);
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};

exports.updateModele = async (req, res) => {
  try {
    const { id } = req.params;
    const { nom, tailles, bases, consommation, taillesBases, description } = req.body;

    // Vérifier si les bases existent
    let baseModels = [];
    if (bases && bases.length > 0) {
      baseModels = await Modele.find({ nom: { $in: bases } });
      if (baseModels.length !== bases.length) {
        return res.status(404).json({ message: "Une ou plusieurs bases non trouvées" });
      }
    }

    // Formater les taillesBases
    let formattedTaillesBases = taillesBases || [];
    if (taillesBases && taillesBases.length > 0) {
      formattedTaillesBases = taillesBases.map(tb => ({
        baseId: tb.baseId,
        tailles: tb.tailles || [],
      }));
    }

    const updateData = {
      nom,
      tailles,
      bases: baseModels.map(b => b._id),
      taillesBases: formattedTaillesBases,
      description,
    };

    if (consommation) {
      updateData.consommation = consommation;
    }

    const modele = await Modele.findByIdAndUpdate(id, updateData, { new: true })
      .populate("matiere")
      .populate("bases");
    if (!modele) return res.status(404).json({ message: "Modèle non trouvé" });

    res.status(200).json(modele);
  } catch (error) {
    console.error("Erreur serveur:", error);
    res.status(500).json({ message: "Erreur serveur", error: error.message });
  }
};

exports.deleteModele = async (req, res) => {
    try {
        const { id } = req.params;
        const modele = await Modele.findByIdAndDelete(id);
        if (!modele) return res.status(404).json({ message: "Modèle non trouvé" });

        res.status(200).json({ message: "Modèle supprimé avec succès" });
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};
exports.updateConsommation = async (req, res) => {
    try {
        const { id } = req.params; // ID du modèle
        const { taille, quantite } = req.body; // Taille et nouvelle quantité

        const modele = await Modele.findById(id);
        if (!modele) return res.status(404).json({ message: "Modèle non trouvé" });
        if (!modele.consommation || modele.consommation.length === 0) {
            modele.consommation = modele.tailles.map(taille => ({
                taille: taille,
                quantite: 0
            }));
        }
        const consommationItem = modele.consommation.find(c => c.taille === taille);
        if (!consommationItem) {
            return res.status(404).json({ message: "Taille non trouvée dans la consommation" });
        }
        consommationItem.quantite = quantite;
        await modele.save();

        res.status(200).json({ message: "Quantité mise à jour avec succès", modele });
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};

