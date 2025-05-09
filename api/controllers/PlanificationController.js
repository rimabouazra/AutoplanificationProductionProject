const Planification = require("../models/Planification");
const Commande = require("../models/Commande");
const Salle = require("../models/Salle");
const Machine = require("../models/Machine");
const WaitingPlanification = require("../models/WaitingPlanification");
const moment = require('moment-timezone');

// Default work hours configuration (7 AM to 5 PM, Tunisia timezone)
let workHoursConfig = {
  startHour: 7, // 7 AM
  endHour: 17, // 5 PM
  timezone: "Tunisia/Monastir"
};

// Helper method to update work hours (e.g., for urgent commands)
exports.updateWorkHours = async (newStartHour, newEndHour) => {
  try {
    if (newStartHour < 0 || newStartHour > 23 || newEndHour < 0 || newEndHour > 23) {
      throw new Error("Invalid hours: Must be between 0 and 23");
    }
    if (newEndHour <= newStartHour) {
      throw new Error("End hour must be after start hour");
    }
    workHoursConfig.startHour = newStartHour;
    workHoursConfig.endHour = newEndHour;
    return {
      message: `Work hours updated to ${newStartHour}:00 - ${newEndHour}:00`,
      workHoursConfig
    };
  } catch (error) {
    console.error("Error updating work hours:", error);
    throw error;
  }
};

// Helper method to calculate planification dates respecting work hours
const calculatePlanificationDates = (startDate, hoursRequired, workHours = workHoursConfig) => {
  let currentDate = moment(startDate).tz(workHours.timezone);
  let remainingHours = hoursRequired;
  let workDayHours = workHours.endHour - workHours.startHour;

  // Start at the next available work hour
  if (currentDate.hour() < workHours.startHour) {
    currentDate.set({ hour: workHours.startHour, minute: 0, second: 0 });
  } else if (currentDate.hour() >= workHours.endHour) {
    currentDate.add(1, 'day').set({ hour: workHours.startHour, minute: 0, second: 0 });
  } else if (currentDate.hour() === workHours.startHour && currentDate.minute() > 0) {
    currentDate.set({ minute: 0, second: 0 });
  }

  let debutPrevue = currentDate.toDate();
  let finPrevue;

  while (remainingHours > 0) {
    // Calculate remaining hours in the current workday
    let hoursUntilEndOfDay = workHours.endHour - currentDate.hour();
    if (hoursUntilEndOfDay <= 0) {
      currentDate.add(1, 'day').set({ hour: workHours.startHour, minute: 0, second: 0 });
      hoursUntilEndOfDay = workDayHours;
    }

    // Use the minimum of remaining hours or hours until end of day
    let hoursToUse = Math.min(remainingHours, hoursUntilEndOfDay);
    remainingHours -= hoursToUse;

    if (remainingHours <= 0) {
      // Set finPrevue to the end of this work period
      currentDate.add(hoursToUse, 'hours');
      finPrevue = currentDate.toDate();
    } else {
      // Move to the next workday
      currentDate.add(1, 'day').set({ hour: workHours.startHour, minute: 0, second: 0 });
    }
  }

  return { debutPrevue, finPrevue };
};

exports.checkActivePlanification = async (req, res) => {
  try {
    const { machineId } = req.params;

    const now = new Date();
    const activePlanification = await Planification.findOne({
      machines: machineId,
      statut: { $ne: "terminée" },
      debutPrevue: { $lte: now },
      finPrevue: { $gt: now },
    });

    res.status(200).json({
      hasActivePlanification: !!activePlanification,
    });
  } catch (error) {
    console.error("Erreur lors de la vérification de la planification :", error);
    res.status(500).json({
      message: "Erreur lors de la vérification",
      error: error.message,
    });
  }
};

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
      $or: [
        { finPrevue: { $lte: now } },
        { debutPrevue: { $lte: now }, finPrevue: { $gt: now } }
      ],
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
      console.log("update planification statut en cours")
      // Update planification status
      if (planif.debutPrevue <= now && planif.finPrevue > now && planif.statut !== "en cours") {
        planif.statut = "en cours";
        await planif.save();
      } else if (planif.finPrevue <= now && planif.statut !== "terminée") {
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
    }

    // Process the waiting list after freeing machines
    await exports.processWaitingList();

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
    const allSallesUtilisees = new Set();

    for (const modele of commande.modeles) {
      const estFoncee = ["noir", "bleu marine", "bleu", "vert"].includes(modele.couleur.toLowerCase());
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
      }

      if (!machine) {
        const planification = {
          commandes: [commande._id],
          modele: modele.modele._id,
          taille: modele.taille,
          couleur: modele.couleur,
          quantite: modele.quantite,
          salle: salleCible._id,
          statut: "waiting_resources",
          createdAt: moment().tz("Europe/Paris").toDate()
        };
        if (!preview) {
          const newPlanification = new Planification(planification);
          await newPlanification.save();
          planifications.push(newPlanification);
        } else {
          planifications.push(planification);
        }
        continue;
      }

      const heures = (modele.quantite / 35) + 2;
      const now = moment().tz("Europe/Paris").toDate();
      const { debutPrevue, finPrevue } = calculatePlanificationDates(now, heures);

      if (!preview) {
        machine.etat = "occupee";
        await machine.save();
      }

      allMachinesAssignees.push(machine._id);
      allSallesUtilisees.add(String(salleCible._id));

      const planification = {
        commandes: [commande._id],
        machines: [machine._id],
        salle: salleCible._id,
        debutPrevue,
        finPrevue,
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

    if (!preview && (planifications.length > 0)) {
      commande.machinesAffectees = allMachinesAssignees;
      commande.salleAffectee = [...allSallesUtilisees][0];
      commande.etat = planifications.some(p => p.statut === "waiting_resources") ? "en attente" : "en attente";
      await commande.save();
    }

    const response = {
      planifications,
      statut: planifications.some(p => p.statut === "waiting_resources") ? "en attente" : "planifiée"
    };

    return res.status(preview ? 200 : 201).json(response);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur lors de la planification automatique", error: err.message });
  }
};

exports.processWaitingList = async () => {
  try {
    const waitingPlans = await Planification.find({ statut: "waiting_resources" })
      .sort({ order: 1, createdAt: 1 })
      .populate('commande')
      .populate('modele');

    const salles = await Salle.find();
    const machines = await Machine.find().populate("modele").populate("salle");
    const activePlanifications = await Planification.find({
      statut: { $ne: "terminée" }
    });

    for (const plan of waitingPlans) {
      const estFoncee = ["noir", "bleu marine", "bleu", "vert"].includes(plan.couleur.toLowerCase());
      const salleCible = salles.find(s => estFoncee ? s.type === "noir" : s.type === "blanc");

      if (!salleCible) {
        console.log(`Salle de type ${estFoncee ? 'noir' : 'blanc'} introuvable`);
        continue;
      }

      const machinesSalle = machines.filter(m => m.salle._id.equals(salleCible._id));
      let machine = machinesSalle.find(m =>
        m.modele && m.modele._id.equals(plan.modele) &&
        m.taille === plan.taille &&
        m.etat === "disponible"
      );

      let debutPrevue = new Date();
      let finPrevue;

      if (!machine) {
        machine = machinesSalle.find(m => m.etat === "disponible");

        if (!machine) {
          let earliestFinPrevue = null;
          let targetMachine = null;

          for (const m of machinesSalle) {
            const planif = activePlanifications.find(p =>
              p.machines.includes(m._id) && p.statut !== "terminée"
            );
            if (planif && (!earliestFinPrevue || planif.finPrevue < earliestFinPrevue)) {
              earliestFinPrevue = planif.finPrevue;
              targetMachine = m;
            }
          }

          if (targetMachine && earliestFinPrevue) {
            machine = targetMachine;
            debutPrevue = new Date(earliestFinPrevue.getTime() + 15 * 60 * 1000);
          } else {
            continue;
          }
        }

        machine.modele = plan.modele;
        machine.taille = plan.taille;
        machine.etat = "occupee";
        await machine.save();
      } else {
        machine.etat = "occupee";
        await machine.save();
      }

      const heures = (plan.quantite / 35) + 2;
      const { debutPrevue: calculatedDebut, finPrevue: calculatedFin } = calculatePlanificationDates(debutPrevue, heures);
      debutPrevue = calculatedDebut;
      finPrevue = calculatedFin;

      plan.machines = [machine._id];
      plan.salle = salleCible._id;
      plan.debutPrevue = debutPrevue;
      plan.finPrevue = finPrevue;
      plan.statut = "en attente";
      await plan.save();

      const commande = await Commande.findById(plan.commandes[0]);
      if (commande) {
        commande.machinesAffectees = [machine._id];
        commande.salleAffectee = salleCible._id;
        commande.etat = "en attente";
        await commande.save();
      }
    }
  } catch (err) {
    console.error("Erreur lors du traitement de la file d'attente :", err);
  }
};

exports.confirmPlanification = async (req, res) => {
  try {
    const { planifications, waitingPlanifications } = req.body;

    if (!planifications || !Array.isArray(planifications)) {
      return res.status(400).json({ message: "Les planifications sont requises sous forme de tableau" });
    }

    const confirmedPlanifications = [];
    const confirmedWaitingPlanifications = [];

    // Process actual planifications
    for (const plan of planifications) {
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

      for (const machineId of planification.machines) {
        const machine = await Machine.findById(machineId);
        if (machine) {
          machine.etat = "occupee";
          await machine.save();
        }
      }

      confirmedPlanifications.push(planification);
    }

    // Process waiting planifications
    if (waitingPlanifications && Array.isArray(waitingPlanifications)) {
      for (const waitingPlan of waitingPlanifications) {
        const existingWaitingPlan = await WaitingPlanification.findOne({
          commande: waitingPlan.commande,
          modele: waitingPlan.modele,
          taille: waitingPlan.taille
        });

        if (!existingWaitingPlan) {
          const newWaitingPlan = new WaitingPlanification({
            commande: waitingPlan.commande,
            modele: waitingPlan.modele,
            taille: waitingPlan.taille,
            couleur: waitingPlan.couleur,
            quantite: waitingPlan.quantite,
            statut: "en attente"
          });

          await newWaitingPlan.save();
          confirmedWaitingPlanifications.push(newWaitingPlan);
        } else {
          confirmedWaitingPlanifications.push(existingWaitingPlan);
        }
      }
    }

    // Trigger processing of waiting list
    await exports.processWaitingList();

    res.status(200).json({
      message: "Planifications confirmées",
      planifications: confirmedPlanifications,
      waitingPlanifications: confirmedWaitingPlanifications
    });
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

exports.getWaitingPlanifications = async (req, res) => {
  try {
    const { commandeId } = req.query;
    const query = commandeId ? { commande: commandeId } : {};
    const waitingPlans = await WaitingPlanification.find(query)
      .sort({ order: 1, createdAt: 1 }) // Sort by order and createdAt
      .populate('commande')
      .populate('modele');
    res.status(200).json(waitingPlans);
  } catch (error) {
    res.status(500).json({ message: "Erreur serveur", error: error.message });
  }
};

exports.deletePlanification = async (req, res) => {
  try {
    const { id } = req.params;
    const deletedPlanification = await Planification.findByIdAndDelete(id);

    if (!deletedPlanification) return res.status(404).json Inactive response: { message: "Planification non trouvée" });

    res.status(200).json({ message: "Planification supprimée avec succès" });
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

exports.getPlanificationById = async (req, res) => {
  try {
    const { id } = req.params;

    const planification = await Planification.findById(id)
      .populate({
        path: 'commandes',
        populate: { path: 'client' }
      })
      .populate({
        path: 'machines',
        populate: ['salle', 'modele']
      });

    if (!planification) {
      return res.status(404).json({ message: "Planification non trouvée" });
    }

    res.status(200).json(planification);
  } catch (error) {
    console.error("Erreur lors de la récupération de la planification :", error);
    res.status(500).json({ message: "Erreur serveur", error: error.message });
  }
};

exports.reorderWaitingPlanifications = async (req, res) => {
  try {
    const { orderedIds } = req.body;

    if (!orderedIds || !Array.isArray(orderedIds)) {
      return res.status(400).json({ message: "orderedIds must be an array" });
    }

    // Update order for each WaitingPlanification
    const updates = orderedIds.map((id, index) =>
      WaitingPlanification.updateOne(
        { _id: id },
        { $set: { order: index } }
      )
    );

    await Promise.all(updates);

    res.status(200).json({ message: "Waiting planifications reordered successfully" });
  } catch (error) {
    console.error("Erreur lors du réordonnancement des planifications en attente :", error);
    res.status(500).json({ message: "Erreur serveur", error: error.message });
  }
};