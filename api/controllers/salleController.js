const Salle = require("../models/Salle");
const Machine = require("../models/Machine");
const { authenticateToken, authorizeRoles } = require('../middlewares/auth'); 
// Middleware de vérification de rôle
const checkRole = (requiredRoles) => {
    return [
        authenticateToken, // Ajoutez d'abord l'authentification
        authorizeRoles(...requiredRoles) // Puis vérifiez le rôle
      ]
  };
//Créer une nouvelle salle
exports.creerSalle =[
    checkRole(['admin', 'manager']),async (req, res) => {
    try {
        const { nom, type } = req.body;
        const nouvelleSalle = new Salle({ nom, type });
        await nouvelleSalle.save();
        res.status(201).json(nouvelleSalle);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la création de la salle", error });
    }
}];

//Modifier le nom d'une salle
exports.modifierSalle = [
    checkRole(['admin', 'manager']), async (req, res) => {
    try {
        const { id } = req.params;
        const { nom, type } = req.body;
        const salle = await Salle.findByIdAndUpdate(id, { nom, type }, { new: true });
        if (!salle) return res.status(404).json({ message: "Salle non trouvée" });
        res.json(salle);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la modification de la salle", error });
    }
}];

// Supprimer une salle
exports.supprimerSalle = [
    checkRole(['admin', 'manager']),async (req, res) => {
    try {
        const { id } = req.params;
        await Salle.findByIdAndDelete(id);
        res.json({ message: "Salle supprimée avec succès" });
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la suppression de la salle", error });
    }
}];

// Récupérer toutes les salles
exports.listerToutesLesSalles = async (req, res) => {
    try {
        // Peupler les machines associées à chaque salle
        const salles = await Salle.find().populate("machines");
        res.json(salles);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la récupération des salles", error });
    }
};

exports.getAllSalles = async (req, res) => {
    try {
        const salles = await Salle.find().populate("machines");
       // console.log("Salles trouvées:", JSON.stringify(salles, null, 2)); // 🔍 Debug: Vérifier les salles et leurs machines

        // Vérifier le vrai nombre de machines dans la base
        for (const salle of salles) {
            const nombreMachinesBDD = await Machine.countDocuments({ salle: salle._id });
            console.log(`Salle: ${salle.nom}, Machines dans la salle:`, salle.machines.length);
            console.log(`Salle: ${salle.nom}, NombreMachines BDD:`, nombreMachinesBDD);
        }

        // Calcul du nombre de machines
        const sallesAvecNombreMachines = salles.map(salle => ({
            ...salle.toObject(),
            nombreMachines: salle.machines.length, 
        }));

        console.log("Salles avec nombreMachines correct:", JSON.stringify(sallesAvecNombreMachines, null, 2));
        res.status(200).json(sallesAvecNombreMachines);
    } catch (error) {
        console.error("Erreur lors de la récupération des salles:", error);
        res.status(500).json({ message: "Erreur lors de la récupération des salles", error });
    }
};


//Ajouter une machine à une salle
exports.ajouterMachine = [
    checkRole(['admin', 'manager']), async (req, res) => {
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
}];

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
