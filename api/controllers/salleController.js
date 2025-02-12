const Salle = require("../models/Salle");
const Machine = require("../models/Machine");

//Créer une nouvelle salle
exports.creerSalle = async (req, res) => {
    try {
        const { nom, type } = req.body;
        const nouvelleSalle = new Salle({ nom, type });
        await nouvelleSalle.save();
        res.status(201).json(nouvelleSalle);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la création de la salle", error });
    }
};

//Modifier le nom d'une salle
exports.modifierSalle = async (req, res) => {
    try {
        const { id } = req.params;
        const { nom } = req.body;
        const salle = await Salle.findByIdAndUpdate(id, { nom }, { new: true });
        if (!salle) return res.status(404).json({ message: "Salle non trouvée" });
        res.json(salle);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la modification de la salle", error });
    }
};

// Supprimer une salle
exports.supprimerSalle = async (req, res) => {
    try {
        const { id } = req.params;
        await Salle.findByIdAndDelete(id);
        res.json({ message: "Salle supprimée avec succès" });
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la suppression de la salle", error });
    }
};

//Ajouter une machine à une salle
exports.ajouterMachine = async (req, res) => {
    try {
        const { salleId } = req.params;
        const { nom, modelesCompatibles } = req.body;

        const salle = await Salle.findById(salleId);
        if (!salle) return res.status(404).json({ message: "Salle non trouvée" });

        const nouvelleMachine = new Machine({ nom, salle: salleId, modelesCompatibles });
        await nouvelleMachine.save();

        salle.machines.push(nouvelleMachine._id);
        await salle.save();

        res.status(201).json(nouvelleMachine);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de l'ajout de la machine", error });
    }
};

// Modifier une machine
exports.modifierMachine = async (req, res) => {
    try {
        const { id } = req.params;
        const { nom, etat, modelesCompatibles } = req.body;

        const machine = await Machine.findByIdAndUpdate(id, { nom, etat, modelesCompatibles }, { new: true });
        if (!machine) return res.status(404).json({ message: "Machine non trouvée" });

        res.json(machine);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la modification de la machine", error });
    }
};

//Supprimer une machine d'une salle
exports.supprimerMachine = async (req, res) => {
    try {
        const { salleId, machineId } = req.params;

        const salle = await Salle.findById(salleId);
        if (!salle) return res.status(404).json({ message: "Salle non trouvée" });

        salle.machines = salle.machines.filter(id => id.toString() !== machineId);
        await salle.save();

        await Machine.findByIdAndDelete(machineId);
        res.json({ message: "Machine supprimée avec succès" });
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la suppression de la machine", error });
    }
};

//Lister toutes les machines d'une salle
exports.listerMachinesSalle = async (req, res) => {
    try {
        const { salleId } = req.params;
        const salle = await Salle.findById(salleId).populate("machines");
        if (!salle) return res.status(404).json({ message: "Salle non trouvée" });

        res.json(salle.machines);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la récupération des machines", error });
    }
};
