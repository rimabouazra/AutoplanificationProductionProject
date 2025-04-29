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

    const machinesAssignees = [];
    let totalHeures = 0;

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

      if (machine) {
        machine.etat = "occupee";
        await machine.save();
        machinesAssignees.push(machine._id);

        const heures = (modele.quantite / 35) + 2;
        totalHeures += heures;
      } else {
        return res.status(200).json({
          message: `Aucune machine disponible pour le modèle ${modele.modele.nom}. La commande est mise en attente.`,
          statut: "en attente",
          commandeId: commande._id
        });
      }
    }

    const debut = new Date();
    const fin = new Date(debut.getTime() + totalHeures * 60 * 60 * 1000);

    const planificationProposee = {
      commandes: [commande._id],
      machines: machinesAssignees,
      salle: machinesAssignees.length > 0 ? machines.find(m => m._id.equals(machinesAssignees[0])).salle._id : "machine non disponibles",
      debutPrevue: debut,
      finPrevue: fin,
      statut: "en attente"
    };

    if (preview) {
      const populatedCommandes = await Commande.find({ _id: { $in: [commande._id] } })
        .populate('client')
        .populate('modeles.modele');

      const populatedMachines = await Machine.find({ _id: { $in: machinesAssignees } })
        .populate('salle')
        .populate('modele');

      return res.status(200).json({
        ...planificationProposee,
        commandes: populatedCommandes,
        machines: populatedMachines
      });
    } else {
      const nouvellePlanification = new Planification(planificationProposee);
      await nouvellePlanification.save();

      commande.salleAffectee = planificationProposee.salle;
      commande.machinesAffectees = machinesAssignees;
      await commande.save();

      return res.status(201).json(nouvellePlanification);
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur lors de la planification automatique", error: err.message });
  }
};


exports.confirmerPlanification = async (req, res) => {
  try {
    const { planification } = req.body;

    // Find and update the existing planification
    const updatedPlanif = await Planification.findByIdAndUpdate(
      planification._id,
      {
        statut: "confirmée",
        debutPrevue: planification.debutPrevue,
        finPrevue: planification.finPrevue
      },
      { new: true }
    )
    .populate({
      path: 'commandes',
      populate: { path: 'client' }
    })
    .populate({
      path: "machines",
      populate: ["salle", "modele"]
    });

    if (!updatedPlanif) {
      return res.status(404).json({ message: "Planification non trouvée" });
    }

    // Update commande status
    await Commande.updateMany(
      { _id: { $in: planification.commandes } },
      { $set: { etat: "En moulage" } }
    );

    res.status(200).json({
      message: "Planification confirmée avec succès",
      planification: updatedPlanif
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({
      message: "Erreur lors de la confirmation",
      error: err.message
    });
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
