const Commande = require("../models/Commande");
const Salle = require("../models/Salle");
const Machine = require("../models/Machine");
const Modele = require("../models/modele");


exports.ajouterCommande = async (req, res) => {
    try {
        console.log("Données reçues :", JSON.stringify(req.body, null, 2)); //Vérifier les données reçues

        const { client, conditionnement, delais, etat, salleAffectee, machinesAffectees, modeles } = req.body;

        // Vérifier si une salle affectée est valide
        if (salleAffectee) {
            console.log("Vérification de la salle :", salleAffectee);
            const salleExistante = await Salle.findById(salleAffectee);
            if (!salleExistante) {
                return res.status(404).json({ message: "Salle non trouvée" });
            }
        }

        // Vérifier si les machines affectées existent
        if (machinesAffectees && machinesAffectees.length > 0) {
            console.log("Vérification des machines :", machinesAffectees);
            for (const machineId of machinesAffectees) {
                const machineExistante = await Machine.findById(machineId);
                if (!machineExistante) {
                    return res.status(404).json({ message: `Machine non trouvée : ${machineId}` });
                }
            }
        }

        // Vérifier que modeles est bien un tableau non vide
        if (!Array.isArray(modeles) || modeles.length === 0) {
            return res.status(400).json({ message: "Veuillez ajouter au moins un modèle" });
        }

        // Vérifier que chaque modèle existe avant de l'ajouter
         for (let item of modeles) {
                    const modeleExist = await Modele.findOne({ nom: item.modele }); // Trouver par nom
                    if (!modeleExist) {
                        return res.status(400).json({ message: `Modèle non trouvé: ${item.modele}` });
                    }
                    item.modele = modeleExist._id; // Remplacer le nom par l'ID
                }

        // Création de la commande avec les modèles et leurs propriétés spécifiques
        const nouvelleCommande = new Commande({
            client,
            modeles, //  Contient {modele, taille, couleur, quantite}
            conditionnement,
            delais,
            etat,
            salleAffectee,
            machinesAffectees
        });

        // Sauvegarde dans MongoDB
        await nouvelleCommande.save();

        console.log("Commande enregistrée :", nouvelleCommande); // Debug
        res.status(201).json(nouvelleCommande);
    } catch (error) {
        console.error("Erreur lors de l'ajout de la commande :", error); // Debug
        res.status(500).json({ message: "Erreur lors de l'ajout de la commande", error: error.message });
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
        const { client, quantite, couleur, taille, conditionnement, delais, etat, salleAffectee, machineAffectee, modeles } = req.body;
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
        if (salleAffectee) commande.salleAffectee = salleAffectee;
        if (machineAffectee) commande.machineAffectee = machineAffectee;
        if (modeles) commande.modeles = modeles;  // Assurez-vous que les modèles sont bien mis à jour.

        console.log("Commande après mise à jour:", commande);

        await commande.save();

        res.status(200).json(commande);
    } catch (error) {
        console.error("Erreur lors de la mise à jour de la commande:", error);
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
