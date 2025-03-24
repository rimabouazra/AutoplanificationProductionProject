const Machine = require("../models/Machine");
const Modele = require("../models/Modele");
const Salle = require("../models/Salle");  

exports.ajouterMachine = async (req, res) => {
    try {
        console.log("Requête reçue pour ajouter une machine :", req.body);
        const { nom, etat, salle, modele, taille } = req.body;
        // Vérifier que la salle existe
        const salleExistante = await Salle.findById(salle);
        if (!salleExistante) {
            console.log("Salle non trouvée !");
            return res.status(404).json({ message: "Salle non trouvée" });
        }
        // Créer la machine
        const nouvelleMachine = new Machine({ nom, etat, salle, modele, taille });
        await nouvelleMachine.save();

        // Ajouter la machine à la salle
        salleExistante.machines.push(nouvelleMachine._id);
        await salleExistante.save();

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

exports.getMachinesBySalle = async (req, res) => {
    try {
        const { salleId } = req.params;

        // Trouver la salle avec ses machines
        const salle = await Salle.findById(salleId).populate({
            path: "machines",
            populate: [{ path: "modele" }, { path: "salle" }] // Charger aussi la salle et le modéle de chaque machine
        });

        if (!salle) {
            return res.status(404).json({ message: "Salle non trouvée" });
        }

        res.status(200).json(salle.machines); // Renvoyer uniquement les machines
    } catch (error) {
        console.error("Erreur lors de la récupération des machines :", error);
        res.status(500).json({ message: "Erreur serveur" });
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
        if (machine.salle) {
            await Salle.findByIdAndUpdate(machine.salle, {
                $pull: { machines: machine._id }
            });
        }

        await Machine.findByIdAndDelete(req.params.id);
        res.status(200).json({ message: "Machine supprimée avec succès" });
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la suppression de la machine", error });
    }
};