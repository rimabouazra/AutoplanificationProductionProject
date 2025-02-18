const Commande = require("../models/Commande");
const Salle = require("../models/Salle");
const Machine = require("../models/Machine");

exports.ajouterCommande = async (req, res) => {
    try {
        const { client, quantite, couleur, taille, conditionnement, delais, etat, salleAffectee, machineAffectee } = req.body;

        // Vérifier si la salle existe
        if (salleAffectee) {
            const salleExistante = await Salle.findById(salleAffectee);
            if (!salleExistante) {
                return res.status(404).json({ message: "Salle non trouvée" });
            }
        }

        // Vérifier si la machine existe
        if (machineAffectee) {
            const machineExistante = await Machine.findById(machineAffectee);
            if (!machineExistante) {
                return res.status(404).json({ message: "Machine non trouvée" });
            }
        }

        // Création de la commande
        const nouvelleCommande = new Commande({
            client,
            quantite,
            couleur,
            taille,
            conditionnement,
            delais,
            etat,
            salleAffectee,
            machineAffectee
        });

        await nouvelleCommande.save();
        res.status(201).json(nouvelleCommande);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de l'ajout de la commande", error });
    }
};

exports.getCommandes = async (req, res) => {
    try {
        const commandes = await Commande.find()
            .populate("salleAffectee")
            .populate("machinesAffectees");

        console.log("Commandes fetched:", commandes); // Debugging statement

        res.status(200).json(commandes);
    } catch (error) {
        console.error("Error fetching commandes:", error); // Debugging statement
        res.status(500).json({ message: "Erreur lors de la récupération des commandes", error });
    }
};
exports.getCommandeById = async (req, res) => {
    try {
        const commande = await Commande.findById(req.params.id)
            .populate("salleAffectee")
            .populate("machineAffectee");
        if (!commande) {
            return res.status(404).json({ message: "Commande non trouvée" });
        }
        res.status(200).json(commande);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la récupération de la commande", error });
    }
};

exports.getCommandesBySalle = async (req, res) => {
    try {
        const commandes = await Commande.find({ salleAffectee: req.params.salleId })
            .populate("salleAffectee")
            .populate("machineAffectee");

        res.status(200).json(commandes);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la récupération des commandes par salle", error });
    }
};

exports.updateCommande = async (req, res) => {
    try {
        const { client, quantite, couleur, taille, conditionnement, delais, etat, salleAffectee, machineAffectee } = req.body;
        const commande = await Commande.findById(req.params.id);

        if (!commande) {
            return res.status(404).json({ message: "Commande non trouvée" });
        }

        // Mise à jour des champs si fournis
        if (client) commande.client = client;
        if (quantite) commande.quantite = quantite;
        if (couleur) commande.couleur = couleur;
        if (taille) commande.taille = taille;
        if (conditionnement) commande.conditionnement = conditionnement;
        if (delais) commande.delais = delais;
        if (etat) commande.etat = etat;
        if (salleAffectee) {
            const salleExistante = await Salle.findById(salleAffectee);
            if (!salleExistante) {
                return res.status(404).json({ message: "Salle non trouvée" });
            }
            commande.salleAffectee = salleAffectee;
        }
        if (machineAffectee) {
            const machineExistante = await Machine.findById(machineAffectee);
            if (!machineExistante) {
                return res.status(404).json({ message: "Machine non trouvée" });
            }
            commande.machineAffectee = machineAffectee;
        }

        await commande.save();
        res.status(200).json(commande);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la mise à jour de la commande", error });
    }
};

exports.deleteCommande = async (req, res) => {
    try {
        const commande = await Commande.findByIdAndDelete(req.params.id);
        if (!commande) {
            return res.status(404).json({ message: "Commande non trouvée" });
        }
        res.status(200).json({ message: "Commande supprimée avec succès" });
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la suppression de la commande", error });
    }
};
