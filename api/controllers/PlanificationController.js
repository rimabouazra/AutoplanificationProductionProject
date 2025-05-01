const Planification = require("../models/Planification");
const Commande = require("../models/Commande");
const Salle = require("../models/Salle");
const Machine = require("../models/Machine");

exports.mettreAJourCommandesEnCours = async (req, res) => {
  try {
    const now = new Date();

    const planifs = await Planification.find({
      debutPrevue: { $lte: now },
      finPrevue: { $gt: now },
      statut: { $ne: "terminée" }
    }).populate({
      path: 'commandes',
      populate: { path: 'client' }
    });

    let commandesMiseAJour = [];

    for (const planif of planifs) {
      for (const commande of planif.commandes) {
        if (commande.etat !== "en moulage") {
          commande.etat = "en moulage";
          await commande.save();
          commandesMiseAJour.push(commande._id);
        }
      }
    }

    res.status(200).json({
      message: "Commandes en cours mises à jour en 'en moulage'",
      commandesMiseAJour
    });

  } catch (error) {
    console.error("Erreur mise à jour commandes en cours :", error);
    res.status(500).json({ message: "Erreur", error: error.message });
  }
};

exports.mettreAJourMachinesDisponibles = async (req, res) => {
  try {
    const now = new Date();

    const planifs = await Planification.find({
      finPrevue: { $lte: now },
      statut: { $ne: "terminée" }
    }).populate({
      path: 'machines'
    }).populate({
      path: 'commandes',
      populate: { path: 'client' }
    });

    let updatedMachinesCount = 0;
    let commandesTerminees = [];

    for (const planif of planifs) {
      for (const machine of planif.machines) {
        machine.etat = "disponible";
        await machine.save();
        updatedMachinesCount++;
      }

      for (const commande of planif.commandes) {
        commande.etat = "en presse";
        await commande.save();
        commandesTerminees.push(commande._id);
      }

      planif.statut = "terminée";
      await planif.save();
    }

    res.status(200).json({
      message: `Mise à jour complétée`,
      planificationsTraitées: planifs.length,
      machinesLibérées: updatedMachinesCount,
      commandesTerminees
    });

  } catch (error) {
    console.error("Erreur mise à jour planifications :", error);
    res.status(500).json({ message: "Erreur lors de la mise à jour", error: error.message });
  }
};

exports.autoPlanifierCommande = async (req, res) => {
  try {
    const { commandeId, preview } = req.body;

    if (!commandeId) {
      return res.status(400).json({ message: "CommandeId is missing" });
    }

    const commande = await Commande.findById(commandeId).populate({
      path: 'modeles.modele'
    }).populate('client');

    if (!commande) {
      return res.status(404).json({ message: "Commande non trouvée", id: commandeId });
    }

    const salles = await Salle.find();
    const machines = await Machine.find().populate("modele").populate("salle");

    const planifications = [];
    const allMachinesAssignees = [];
    const allSallesUtilisees = new Set(); // Might be multiple salles

    for (const modele of commande.modeles) {
      const estFoncee = ["noir", "bleu marine"].includes(modele.couleur.toLowerCase());
      const salleCible = salles.find(s => estFoncee ? s.type === "noir" : s.type === "blanc");

      if (!salleCible) {
        return res.status(400).json({ message: `Salle de type ${estFoncee ? 'noir' : 'blanc'} introuvable` });
      }

      const machinesSalle = machines.filter(m => m.salle._id.equals(salleCible._id));

      let machine = machinesSalle.find(m =>
        m.modele && m.modele._id.equals(modele.modele._id) &&
        m.taille === modele.taille &&
        m.etat === "disponible"
      );

      if (!machine) {
        machine = machinesSalle.find(m => m.etat === "disponible");
        if (machine) {
          machine.modele = modele.modele;
          machine.taille = modele.taille;
          await machine.save();
        }
      }

      if (!machine) {
        return res.status(200).json({
          message: `Aucune machine disponible pour le modèle ${modele.modele.nom}. La commande est mise en attente.`,
          statut: "en attente",
          commandeId: commande._id
        });
      }

      // Calculer durée et heures nécessaires
      const heures = (modele.quantite / 35) + 2;
      const debut = new Date(); // TODO: could consider overlapping plans
      const fin = new Date(debut.getTime() + heures * 60 * 60 * 1000);

      machine.etat = "occupee";
      await machine.save();

      allMachinesAssignees.push(machine._id);
      allSallesUtilisees.add(String(salleCible._id));

      const planification = {
        commandes: [commande._id],
        machines: [machine._id],
        salle: salleCible._id,
        debutPrevue: debut,
        finPrevue: fin,
        statut: "en attente"
      };

      if (preview) {
        const populatedCommande = await Commande.findById(commande._id)
          .populate('client')
          .populate('modeles.modele');

        const populatedMachine = await Machine.findById(machine._id)
          .populate('salle')
          .populate('modele');

        planifications.push({
          ...planification,
          commandes: [populatedCommande],
          machines: [populatedMachine]
        });
      } else {
        const nouvellePlanification = new Planification(planification);
        await nouvellePlanification.save();
        planifications.push(nouvellePlanification);
      }
    }

    if (!preview) {
      // Update the commande with all assigned machines and salles
      commande.machinesAffectees = allMachinesAssignees;
      commande.salleAffectee = [...allSallesUtilisees][0]; // Optional: pick first salle
      await commande.save();
    }

    return res.status(preview ? 200 : 201).json(planifications);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur lors de la planification automatique", error: err.message });
  }
};


exports.confirmPlanification = async (req, res) => {
  try {
    const { planifications } = req.body;

    if (!planifications || !Array.isArray(planifications)) {
      return res.status(400).json({ message: "Les planifications sont requises sous forme de tableau" });
    }

    const confirmed = [];

    for (const plan of planifications) {
      // Si l'objet contient un _id, on met à jour une planification existante
      let planification;
      if (plan._id) {
        planification = await Planification.findById(plan._id);
        if (!planification) continue;

        planification.machines = plan.machines.map(m => m._id || m);
        planification.salle = plan.salle._id || plan.salle;
        planification.debutPrevue = new Date(plan.debutPrevue);
        planification.finPrevue = new Date(plan.finPrevue);
        planification.statut = "planifiée";

        await planification.save();
      } else {
        // Sinon, on crée une nouvelle planification depuis l'objet preview
        planification = new Planification({
          commandes: plan.commandes.map(c => c._id || c),
          machines: plan.machines.map(m => m._id || m),
          salle: plan.salle._id || plan.salle,
          debutPrevue: new Date(plan.debutPrevue),
          finPrevue: new Date(plan.finPrevue),
          statut: "planifiée"
        });

        await planification.save();
      }

      // Marquer les machines comme occupées
      for (const machineId of planification.machines) {
        const machine = await Machine.findById(machineId);
        if (machine) {
          machine.etat = "occupee";
          await machine.save();
        }
      }

      confirmed.push(planification);
    }

    res.status(200).json({ message: "Planifications confirmées", planifications: confirmed });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur lors de la confirmation", error: err.message });
  }
};

exports.addPlanification = async (req, res) => {
  try {
    const { commandes, machinesIds, debutPrevue, finPrevue } = req.body;

    const machines = await Machine.find({ _id: { $in: machinesIds } });
    if (machines.length === 0) return res.status(404).json({ message: "Machines non trouvées" });

    const newPlanification = new Planification({
      commandes,
      machines: machines.map(m => m._id),
      debutPrevue,
      finPrevue,
      statut: "en attente"
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
      .populate({
        path: 'commandes',
        populate: { path: 'client' }
      })
      .populate({
        path: "machines",
        populate: ["salle", "modele"]
      });

    res.status(200).json(planifications);
  } catch (error) {
    res.status(500).json({ message: "Erreur serveur", error: error.message });
  }
};

exports.getPlanificationById = async (req, res) => {
  try {
    const { id } = req.params;
    const planification = await Planification.findById(id)
      .populate({
        path: "commandes",
        populate: { path: "client" }
      })
      .populate({
        path: "machines",
        populate: ["salle", "modele"]
      });

    if (!planification) return res.status(404).json({ message: "Planification non trouvée" });

    res.status(200).json(planification);
  } catch (error) {
    res.status(500).json({ message: "Erreur serveur", error: error.message });
  }
};

exports.updatePlanification = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const updatedPlanification = await Planification.findByIdAndUpdate(id, updateData, { new: true })
      .populate({
        path: "commandes",
        populate: { path: "client" }
      })
      .populate({
        path: "machines",
        populate: ["salle", "modele"]
      });

    if (!updatedPlanification) return res.status(404).json({ message: "Planification non trouvée" });

    res.status(200).json(updatedPlanification);
  } catch (error) {
    res.status(500).json({ message: "Erreur serveur", error: error.message });
  }
};

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
