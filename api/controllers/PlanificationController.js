const Planification = require("../models/Planification");
const Commande = require("../models/Commande");
const Salle = require("../models/Salle");
const Machine = require("../models/Machine");
const Matiere = require("../models/matiere");


exports.addPlanification = async (req, res) => {
    try {
        const { commandes, machinesIds, debutPrevue, finPrevue } = req.body;

        // Fetch machines
        const machines = await Machine.find({ _id: { $in: machinesIds } });
        if (machines.length === 0) return res.status(404).json({ message: "Machines non trouvées" });

        const newPlanification = new Planification({
            commandes,
            machines: machines.map(m => m._id),
            debutPrevue,
            finPrevue,
            statut: "en attente",
        });

        await newPlanification.save();
        res.status(201).json(newPlanification);
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};

exports.getAllPlanifications = async (req, res) => {
    try {
        const planifications = await Planification.find()
            .populate("commandes")

            .populate({
                path: "machines",
                model: "Machine",
                populate: { path: "salle" }

            });


        console.log("Planifications envoyées:", JSON.stringify(planifications, null, 2)); //  Log détaillé

        res.status(200).json(planifications);
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};


// Récupérer une planification par ID
exports.getPlanificationById = async (req, res) => {
    try {
        const { id } = req.params;
        const planification = await Planification.findById(id)
            .populate("commandes")
            .populate({
                path: "machines",
                model: "Machine"
            });

        if (!planification) return res.status(404).json({ message: "Planification non trouvée" });

        res.status(200).json(planification);
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};

// Mettre à jour une planification
exports.updatePlanification = async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;

        const updatedPlanification = await Planification.findByIdAndUpdate(id, updateData, { new: true })
            .populate("commandes")
            .populate("machines");

        if (!updatedPlanification) return res.status(404).json({ message: "Planification non trouvée" });

        res.status(200).json(updatedPlanification);
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};

// Supprimer une planification
exports.deletePlanification = async (req, res) => {
    try {
        const { id } = req.params;
        const deletedPlanification = await Planification.findByIdAndDelete(id);

        if (!deletedPlanification) return res.status(404).json({ message: "Planification non trouvée" });

        res.status(200).json({ message: "Planification supprimée avec succès" });
    } catch (error) {
        res.status(500).json({ message: "Erreur serveur", error: error.message });
    }
};
