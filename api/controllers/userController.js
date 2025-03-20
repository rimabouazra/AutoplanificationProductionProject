const bcrypt = require("bcryptjs");
const User = require("../models/User");

// Ajouter un utilisateur
exports.ajouterUtilisateur = async (req, res) => {
    try {
        const { nom, email, motDePasse, role } = req.body;

        // Vérifier si l'utilisateur existe déjà
        const utilisateurExistant = await User.findOne({ email });
        if (utilisateurExistant) {
            return res.status(400).json({ message: "Cet utilisateur existe déjà." });
        }

        // Hacher le mot de passe
        const hashedPassword = await bcrypt.hash(motDePasse, 10);

        const nouvelUtilisateur = new User({ nom, email, motDePasse: hashedPassword, role });
        await nouvelUtilisateur.save();
        
        res.status(201).json(nouvelUtilisateur);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de l'ajout de l'utilisateur", error });
    }
};

// Récupérer tous les utilisateurs
exports.getUtilisateurs = async (req, res) => {
    try {
        const utilisateurs = await User.find().select("-motDePasse");
        res.status(200).json(utilisateurs);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la récupération des utilisateurs", error });
    }
};

// Récupérer un utilisateur par ID
exports.getUtilisateurById = async (req, res) => {
    try {
        const utilisateur = await User.findById(req.params.id).select("-motDePasse");
        if (!utilisateur) {
            return res.status(404).json({ message: "Utilisateur non trouvé" });
        }
        res.status(200).json(utilisateur);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la récupération de l'utilisateur", error });
    }
};

// Mettre à jour un utilisateur
exports.updateUtilisateur = async (req, res) => {
    try {
        const { nom, email, motDePasse, role } = req.body;
        let updateData = { nom, email, role };

        if (motDePasse) {
            updateData.motDePasse = await bcrypt.hash(motDePasse, 10);
        }

        const utilisateur = await User.findByIdAndUpdate(req.params.id, updateData, { new: true }).select("-motDePasse");
        if (!utilisateur) {
            return res.status(404).json({ message: "Utilisateur non trouvé" });
        }

        res.status(200).json(utilisateur);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la mise à jour de l'utilisateur", error });
    }
};

// Supprimer un utilisateur
exports.deleteUtilisateur = async (req, res) => {
    try {
        const utilisateur = await User.findByIdAndDelete(req.params.id);
        if (!utilisateur) {
            return res.status(404).json({ message: "Utilisateur non trouvé" });
        }
        res.status(200).json({ message: "Utilisateur supprimé avec succès" });
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la suppression de l'utilisateur", error });
    }
};
