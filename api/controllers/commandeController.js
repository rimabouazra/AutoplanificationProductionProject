const Commande = require("../models/Commande");
const Salle = require("../models/Salle");
const Machine = require("../models/Machine");
const Modele = require("../models/Modele");


exports.ajouterCommande = async (req, res) => {
    try {

        console.log("Données reçues :", JSON.stringify(req.body, null, 2)); //Vérifier les données reçues

        const { client, conditionnement, delais, etat, salleAffectee, machinesAffectees, modeles } = req.body;

        if (salleAffectee) {
            console.log("Vérification de la salle :", salleAffectee);
            const salleExistante = await Salle.findById(salleAffectee);
            if (!salleExistante) {
                return res.status(404).json({ message: "Salle non trouvée" });
            }
        }

        if (machinesAffectees && machinesAffectees.length > 0) {
            console.log("Vérification des machines :", machinesAffectees);
            for (const machineId of machinesAffectees) {
                const machineExistante = await Machine.findById(machineId);
                if (!machineExistante) {
                    return res.status(404).json({ message: `Machine non trouvée : ${machineId}` });
                }
            }
        }

        if (!Array.isArray(modeles) || modeles.length === 0) {
            return res.status(400).json({ message: "Veuillez ajouter au moins un modèle" });
        }

         for (let item of modeles) {
             const modeleExist = await Modele.findById(item.modele); // Recherche par ID
             if (!modeleExist) {
                 return res.status(400).json({ message: `Modèle non trouvé: ${item.modele}` });
             }
         }
        const nouvelleCommande = new Commande({
            client,
            modeles, //  Contient {modele, taille, couleur, quantite}
            conditionnement,
            delais,
            etat,
            salleAffectee,
            machinesAffectees
        });

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
        console.log("🔄 Requête de mise à jour reçue :", JSON.stringify(req.body, null, 2));

        const { client, conditionnement, delais, etat, salleAffectee, machinesAffectees, modeles } = req.body;
        const commandeId = req.params.id;

        // Vérifier si la commande existe
        let commande = await Commande.findById(commandeId);
        if (!commande) {
            return res.status(404).json({ message: "Commande non trouvée" });
        }

        console.log(" Avant mise à jour : ", JSON.stringify(commande, null, 2));

        if (!Array.isArray(modeles) || modeles.length === 0) {
            return res.status(400).json({ message: "La commande doit contenir au moins un modèle." });
        }

        // Vérifier que chaque modèle a un ID valide
        for (let item of modeles) {
            if (!item.modele) {
                return res.status(400).json({ message: "Un modèle dans la commande n'a pas d'ID valide."});
            }

            const modeleExist = await Modele.findById(item.modele);
            if (!modeleExist) {
                return res.status(400).json({ message: `Modèle non trouvé: ${item.modele}` });
            }
        }

        // Mise à jour des champs de la commande
        commande.client = client || commande.client;
        commande.conditionnement = conditionnement || commande.conditionnement;
        commande.delais = delais || commande.delais;
        commande.etat = etat || commande.etat;
        commande.salleAffectee = salleAffectee || commande.salleAffectee;
        commande.machinesAffectees = machinesAffectees || commande.machinesAffectees;
        commande.modeles = modeles;

        commande = await Commande.findByIdAndUpdate(commandeId, { $set: commande }, { new: true });

        console.log(" Après mise à jour : ", JSON.stringify(commande, null, 2));

        res.status(200).json(commande);
    } catch (error) {
        console.error(" Erreur lors de la mise à jour de la commande :", error);
        res.status(500).json({ message: "Erreur serveur", error: error.message });
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
