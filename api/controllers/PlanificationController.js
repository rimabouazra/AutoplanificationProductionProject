const Planification = require("../models/Planification");
const Commande = require("../models/Commande");
const Salle = require("../models/Salle");
const Machine = require("../models/Machine");
const Matiere = require("../models/matiere");

const Modele = require("../models/Modele");

exports.autoPlanifierCommande = async (req, res) => {
  try {
    console.log('Request body:', req.body);
    const { commandeId } = req.body;

    if (!commandeId) {
      return res.status(400).json({ message: "CommandeId is missing" });
    }

    const commande = await Commande.findById(commandeId).populate("modeles");
    if (!commande) {
      return res.status(404).json({ message: "Commande non trouvée", id: commandeId });
    }

    const salles = await Salle.find();
    const machines = await Machine.find().populate("modele").populate("salle");

    const machinesAssignees = [];
    let totalHeures = 0;

    for (const modele of commande.modeles) {
      const estFoncee = ["noir", "bleu marine"].includes(modele.couleur.toLowerCase());

      const salleCible = salles.find(s => estFoncee ? s.type === "noir" : s.type === "blanc");
      if (!salleCible) {
        return res.status(400).json({ message: `Salle de type ${estFoncee ? 'noir' : 'blanc'} introuvable` });
      }

      // Chercher machine avec même modele + taille + disponible dans salle
      let machine = machines.find(m =>
        m.salle._id.equals(salleCible._id) &&
        m.modele && m.modele._id.equals(modele.modele) &&
        m.taille === modele.taille &&
        m.etat === "disponible"
      );

      // Sinon chercher une machine libre dans la salle, et lui assigner les valeurs
      if (!machine) {
        machine = machines.find(m =>
          m.salle._id.equals(salleCible._id) &&
          m.etat === "disponible"
        );

        if (machine) {
          machine.modele = modele.modele;
          machine.taille = modele.taille;
        }
      }

      if (machine) {
        machine.etat = "occupee";
        await machine.save();
        machinesAssignees.push(machine._id);

        const heures = (modele.quantite / 35) + 2;
        totalHeures += heures;
      } else {
        return res.status(400).json({
          message: `Aucune machine disponible trouvée pour le modèle ${modele.nomModele}`
        });
      }
    }

    const debut = new Date();
    const fin = new Date(debut.getTime() + totalHeures * 60 * 60 * 1000);

    const nouvellePlanification = new Planification({
      commandes: [commande._id],
      machines: machinesAssignees,
      debutPrevue: debut,
      finPrevue: fin,
      statut: "en attente"
    });

    await nouvellePlanification.save();
    res.status(201).json(nouvellePlanification);

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur lors de la planification automatique", error: err.message });
  }
};


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
