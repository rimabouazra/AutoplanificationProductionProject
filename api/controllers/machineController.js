const Machine = require("../models/Machine");
const Modele = require("../models/Modele");

exports.ajouterMachine = async (req, res) => {
    try {
        const { nom, etat, salle, modele, taille } = req.body;

        // Vérifier si le modèle existe
        const modeleExistant = await Modele.findById(modele);
        if (!modeleExistant) {
            return res.status(404).json({ message: "Modèle non trouvé" });
        }

        // Vérifier si la taille existe dans le modèle
        if (!modeleExistant.tailles.includes(taille)) {
            return res.status(400).json({ message: "Taille non compatible avec le modèle" });
        }

        const nouvelleMachine = new Machine({
            nom,
            etat,
            salle,
            modele,
            taille
        });

        await nouvelleMachine.save();
        res.status(201).json(nouvelleMachine);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de l'ajout de la machine", error });
    }
};

exports.getMachines = async (req, res) => {
    try {
        const machines = await Machine.find().populate("modele").populate("salle");
        res.status(200).json(machines);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la récupération des machines", error });
    }
};

exports.getMachineById = async (req, res) => {
    try {
        const machine = await Machine.findById(req.params.id).populate("modele").populate("salle");
        if (!machine) {
            return res.status(404).json({ message: "Machine non trouvée" });
        }
        res.status(200).json(machine);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la récupération de la machine", error });
    }
};

exports.updateMachine = async (req, res) => {
    try {
        const { nom, etat, salle, modele, taille } = req.body;

        const machine = await Machine.findById(req.params.id);
        if (!machine) {
            return res.status(404).json({ message: "Machine non trouvée" });
        }

        // Mise à jour des champs si fournis
        if (nom) machine.nom = nom;
        if (etat) machine.etat = etat;
        if (salle) machine.salle = salle;
        if (modele) {
            const modeleExistant = await Modele.findById(modele);
            if (!modeleExistant) {
                return res.status(404).json({ message: "Modèle non trouvé" });
            }
            machine.modele = modele;
        }
        if (taille) machine.taille = taille;

        await machine.save();
        res.status(200).json(machine);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la mise à jour de la machine", error });
    }
};

exports.deleteMachine = async (req, res) => {
    try {
        const machine = await Machine.findByIdAndDelete(req.params.id);
        if (!machine) {
            return res.status(404).json({ message: "Machine non trouvée" });
        }
        res.status(200).json({ message: "Machine supprimée avec succès" });
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la suppression de la machine", error });
    }
};
