const bcrypt = require("bcryptjs");
const User = require("../models/User");
const { generateToken } = require('../middlewares/auth');
const jwt = require("jsonwebtoken");
// Ajouter un utilisateur
exports.ajouterUtilisateur = async (req, res) => {
    try {
        console.log('Requête reçue:', req.body); // DEBUG
        const { nom, email, motDePasse, role } = req.body;
        if (!nom || !email || !motDePasse) {
            console.log('Champs manquants:', { nom, email, motDePasse, role });
            return res.status(400).json({ message: "Tous les champs sont requis" });
        }
        // Vérifier si l'utilisateur existe déjà
        const utilisateurExistant = await User.findOne({ email });
        if (utilisateurExistant) {
            return res.status(400).json({ message: "Cet utilisateur existe déjà." });
        }

        const hashedPassword = await bcrypt.hash(motDePasse, 10);// Hacher le mot de passe
        const nouvelUtilisateur = new User({
            nom, email, motDePasse: hashedPassword, role: null,
            status: 'pending'
        });
        await nouvelUtilisateur.save();

        res.status(201).json(nouvelUtilisateur);
    } catch (error) {
        console.error('Erreur lors de l\'ajout:', error); // DEBUG
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
exports.login = async (req, res) => {
    try {
        const { email, motDePasse } = req.body;

        const utilisateur = await User.findOne({ email });
        if (!utilisateur|| utilisateur.status !== 'approved') {
            return res.status(400).json({ message: "Identifiants invalides ou compte non approuvé." });
        }

        const passwordMatch = await bcrypt.compare(motDePasse, utilisateur.motDePasse);
        if (!passwordMatch) {
            return res.status(401).json({ message: "Mot de passe incorrect." });
        }

        const token = jwt.sign(
            { id: utilisateur._id, role: utilisateur.role },
            process.env.JWT_SECRET,
            { expiresIn: "24h" }
        );

        res.status(200).json({
            token,
            utilisateur: {
                _id: utilisateur._id,
                nom: utilisateur.nom,
                email: utilisateur.email,
                role: utilisateur.role,
            }
        });
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la connexion", error });
    }
};
exports.getPendingUsers = async (req, res) => {
    const users = await User.find({ status: 'pending' });
    res.json(users);
};

exports.approveUser = async (req, res) => {
    const { role } = req.body;
    await User.findByIdAndUpdate(req.params.id, { status: 'approved', role });
    res.json({ success: true });
};

exports.rejectUser = async (req, res) => {
    await User.findByIdAndDelete(req.params.id);
    res.json({ success: true });
};
