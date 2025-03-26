const Modele = require("../models/Modele");
const Matiere = require("../models/matiere");

exports.addModele = async (req, res) => {
    try {
        const { nom, matiereId, tailles, bases, taillesBases, consommation } = req.body;

        let matiere = null;
        if (matiereId) {
            matiere = await Matiere.findById(matiereId);
            if (!matiere) {
                return res.status(404).json({ message: "Matière non trouvée" });
            }
        }
        // Vérifier si des bases sont spécifiées
        let baseReferences = [];
        let taillesBasesFormatted = [];

        if (bases && bases.length > 0) {
            baseReferences = await Modele.find({ _id: { $in: bases } });
            if (baseReferences.length !== bases.length) {
                return res.status(404).json({ message: "Une ou plusieurs bases n'existent pas" });
            }

            // Correspondance automatique entre les tailles du modèle et les tailles des bases
            taillesBasesFormatted = bases.map((baseId, index) => ({
                baseId: baseId,
                tailles: tailles.map((_, i) => bases[index] ? baseReferences[index].tailles[i] || "?" : "?")
            }));
        }
        const newModele = new Modele({
            nom,
            matiere: matiereId || null,  // Accepte un modèle sans matière
            tailles,
            bases,
            taillesBases: taillesBasesFormatted,
            consommation: consommation || [] 
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

        modeles.forEach(modele => {
            if (!modele.consommation || modele.consommation.length === 0) {
                modele.consommation = modele.tailles.map(taille => ({
                    taille: taille,
                    quantite: 0
                }));
            }
        });

        res.status(200).json(modeles);
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};

exports.updateModele = async (req, res) => {
    try {
        const { id } = req.params;
        const { consommation, ...updateData } = req.body;

        const modele = await Modele.findByIdAndUpdate(id, updateData, { new: true }).populate("matiere").populate("bases");
        if (!modele) return res.status(404).json({ message: "Modèle non trouvé" });
        if (consommation) {
            modele.consommation = consommation;
        }
        Object.assign(modele, updateData);

        await modele.save();
        res.status(200).json(modele);
    } catch (error) {
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

