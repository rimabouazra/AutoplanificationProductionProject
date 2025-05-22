const Planification = require("../models/Planification");
const Commande = require("../models/Commande");
const Salle = require("../models/Salle");
const Machine = require("../models/Machine");
const moment = require('moment-timezone');
const Matiere = require("../models/matiere");
const mongoose = require('mongoose');

// 7 AM to 5 PM, Tunisia timezone
let workHoursConfig = {
  startHour: 7, // 7 AM
  endHour: 17, // 5 PM
  timezone: "CET"
};

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

const calculatePlanificationDates = (startDate, hoursRequired, workHours = workHoursConfig) => {
  let currentDate = moment(startDate).tz(workHours.timezone);
  let remainingHours = hoursRequired;
  let workDayHours = workHours.endHour - workHours.startHour;

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
    const { commandeId, preview, partial } = req.body;

    if (!commandeId) {
      return res.status(400).json({ message: "CommandeId is missing" });
    }

    const commande = await Commande.findById(commandeId)
      .populate({
        path: "modeles.modele",
      })
      .populate("client");

    if (!commande) {
      return res.status(404).json({ message: "Commande non trouvée", id: commandeId });
    }

    const matieres = await Matiere.find();
    const salles = await Salle.find();
    const machines = await Machine.find().populate("modele").populate("salle");
    const planifications = [];
    const allMachinesAssignees = [];
    const allSallesUtilisees = new Set();
    let hasInsufficientStock = false;
    const partialPlanifications = [];

    for (const modele of commande.modeles) {
      const estFoncee = ["noir", "bleu marine", "bleu", "vert"].includes(modele.couleur.toLowerCase());
      const salleCible = salles.find((s) => estFoncee ? s.type === "noir" : s.type === "blanc");

      if (!salleCible) {
        return res.status(400).json({
          message: `Salle de type ${estFoncee ? "noir" : "blanc"} introuvable`,
        });
      }

      const matiere = matieres.find((m) => m.couleur.toLowerCase() === modele.couleur.toLowerCase());
      const consommation = modele.modele.consommation.find((c) => c.taille === modele.taille);
      const quantiteNecessaire = (consommation?.quantity || 0.5) * modele.quantite;

      let quantitePlanifiee = modele.quantite;
      let quantiteEnAttente = 0;

      if (matiere && matiere.quantite < quantiteNecessaire) {
        hasInsufficientStock = true;
        if (partial) {
          const quantiteRealisable = Math.floor(matiere.quantite / (consommation?.quantity || 0.5));
          quantitePlanifiee = Math.min(quantiteRealisable, modele.quantite);
          quantiteEnAttente = modele.quantite - quantitePlanifiee;
        } else {
          quantitePlanifiee = 0;
          quantiteEnAttente = modele.quantite;
        }
      }

      if (quantitePlanifiee > 0) {
        const machinesSalle = machines.filter((m) => m.salle._id.equals(salleCible._id));
        let machine = machinesSalle.find(
          (m) =>
            m.modele &&
            m.modele._id.equals(modele.modele._id) &&
            m.taille === modele.taille &&
            m.etat === "disponible"
        );

        if (!machine) {
          machine = machinesSalle.find((m) => m.etat === "disponible");
        }

        if (!machine) {
          quantiteEnAttente += quantitePlanifiee;
          quantitePlanifiee = 0;
        } else {
          const heures = (quantitePlanifiee / 35) + 2;
          const now = moment().tz("CET").toDate();
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
            quantite: quantitePlanifiee,
            taille: modele.taille,
            couleur: modele.couleur,
            statut: "en attente"
          };

          if (preview) {
            const populatedCommande = await Commande.findById(commande._id)
              .populate("client")
              .populate("modeles.modele");
            const populatedMachine = await Machine.findById(machine._id)
              .populate({ path: "salle", select: "nom type" })
              .populate("modele");
            const salleLight = await Salle.findById(salleCible._id).select("_id nom type");
            planifications.push({
              ...planification,
              commandes: [populatedCommande],
              machines: [populatedMachine],
              salle: salleLight
                ? { _id: salleLight._id, nom: salleLight.nom, type: salleLight.type }
                : null,
            });
          } else {
            const nouvellePlanification = new Planification(planification);
            await nouvellePlanification.save();
            const populatedPlanification = await Planification.findById(nouvellePlanification._id)
              .populate({
                path: "commandes",
                populate: { path: "client" },
              })
              .populate({
                path: "machines",
                populate: ["salle", "modele"],
              });
            if (nouvellePlanification.salle) {
              const salleLight = await Salle.findById(nouvellePlanification.salle).select("_id nom type");
              populatedPlanification.salle = salleLight
                ? { _id: salleLight._id, nom: salleLight.nom, type: salleLight.type }
                : null;
            }
            planifications.push(populatedPlanification);
          }
        }
      }

      if (quantiteEnAttente > 0) {
        const waitingPlan = {
          commandes: [commande._id],
          machines: [],
          salle: salleCible._id,
          quantite: quantiteEnAttente,
          taille: modele.taille,
          couleur: modele.couleur,
          statut: "waiting_resources",
          createdAt: moment().tz("CET").toDate(),
        };

        if (!preview) {
          const newWaitingPlan = new Planification(waitingPlan);
          await newWaitingPlan.save();
          const populatedWaitingPlan = await Planification.findById(newWaitingPlan._id)
            .populate({
              path: "commandes",
              populate: { path: "client" },
            });
          if (newWaitingPlan.salle) {
            const salleLight = await Salle.findById(newWaitingPlan.salle).select("_id nom type");
            populatedWaitingPlan.salle = salleLight
              ? { _id: salleLight._id, nom: salleLight.nom, type: salleLight.type }
              : null;
          }
          partialPlanifications.push(populatedWaitingPlan);
        } else {
          const populatedCommande = await Commande.findById(commande._id)
            .populate("client")
            .populate("modeles.modele");
          waitingPlan.commandes = [populatedCommande];
          waitingPlan.salle = {
            _id: salleCible._id,
            nom: salleCible.nom,
            type: salleCible.type,
          };
          partialPlanifications.push(waitingPlan);
        }
      }
    }

    if (!preview && (planifications.length > 0 || partialPlanifications.length > 0)) {
      commande.machinesAffectees = allMachinesAssignees;
      commande.salleAffectee = [...allSallesUtilisees][0];
      commande.etat = (hasInsufficientStock || partialPlanifications.length > 0) ? "en attente" : "en attente";
      await commande.save();
    }

    const response = {
      planifications: [...planifications, ...partialPlanifications],
      statut: hasInsufficientStock ? "en attente" : "planifiée",
      hasInsufficientStock,
      partialAvailable: hasInsufficientStock
    };

    return res.status(preview ? 200 : 201).json(response);
  } catch (err) {
    console.error(err);
    res.status(500).json({
      message: "Erreur lors de la planification automatique",
      error: err.message,
    });
  }
};

exports.processWaitingList = async () => {
  const session = await mongoose.startSession();
  try {
    session.startTransaction();

    const waitingPlans = await Planification.find({ statut: "waiting_resources" })
      .sort({ order: 1, createdAt: 1 })
      .populate('commandes')
      .populate('salle')
      .session(session);

    const salles = await Salle.find().session(session);
    const machines = await Machine.find().populate("modele").populate("salle").session(session);
    const activePlanifications = await Planification.find({
      statut: { $ne: "terminée" }
    }).session(session);
    const matieres = await Matiere.find().session(session);

    for (const plan of waitingPlans) {
      // Skip if already has machines assigned
      if (plan.machines.length > 0) {
        console.log(`Planification ${plan._id} already has machines assigned`);
        continue;
      }

      const commande = await Commande.findById(plan.commandes[0])
        .populate('modeles.modele')
        .session(session);

      if (!commande || commande.modeles.length === 0) {
        console.log(`Commande ou modèles non trouvés pour planification ${plan._id}`);
        continue;
      }

      // Find the specific modele for this planification
      const modeleCommande = commande.modeles.find(
        (m) => m.taille === plan.taille && m.couleur.toLowerCase() === plan.couleur.toLowerCase()
      );

      if (!modeleCommande) {
        console.log(`Modèle non trouvé pour planification ${plan._id}`);
        continue;
      }

      // Check stock availability
      const matiere = matieres.find(
        (m) => m.couleur.toLowerCase() === modeleCommande.couleur.toLowerCase()
      );

      const consommation = modeleCommande.modele.consommation?.find(
        (c) => c.taille === modeleCommande.taille
      );

      const quantiteNecessaire = (consommation?.quantity || 0.5) * modeleCommande.quantite;

      if (!matiere || matiere.quantite < quantiteNecessaire) {
        console.log(`Insufficient stock for planification ${plan._id}: ${quantiteNecessaire} needed, ${matiere?.quantite || 0} available`);
        continue;
      }

      const estFoncee = ["noir", "bleu marine", "bleu", "vert"].includes(modeleCommande.couleur.toLowerCase());
      const salleCible = salles.find(s => estFoncee ? s.type === "noir" : s.type === "blanc");

      if (!salleCible) {
        console.log(`Salle de type ${estFoncee ? 'noir' : 'blanc'} introuvable pour planification ${plan._id}`);
        continue;
      }

      const machinesSalle = machines.filter(m => m.salle._id.equals(salleCible._id));

      // Find available machine that matches the model and size
      let machine = machinesSalle.find(m =>
        m.etat === "disponible" &&
        m.modele?._id.equals(modeleCommande.modele._id) &&
        m.taille === modeleCommande.taille
      );

      let debutPrevue = new Date();

      // If no exact match, find an available machine and configure it
      if (!machine) {
        machine = machinesSalle.find(m => m.etat === "disponible");

        if (!machine) {
          // Check for soon-to-be-available machines
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
            debutPrevue = new Date(earliestFinPrevue.getTime() + 15 * 60 * 1000); // 15-minute buffer
          } else {
            console.log(`No available machine in salle ${salleCible.nom} for planification ${plan._id}`);
            continue;
          }
        }

        // Configure machine to match planification requirements
        machine.modele = modeleCommande.modele._id;
        machine.taille = modeleCommande.taille;
      }

      // Check for scheduling conflicts
      const conflictingPlan = activePlanifications.find(p =>
        p.machines.includes(machine._id) &&
        p.statut !== "terminée" &&
        (
          (debutPrevue >= p.debutPrevue && debutPrevue <= p.finPrevue) ||
          (p.debutPrevue >= debutPrevue && p.debutPrevue <= finPrevue)
        )
      );

      if (conflictingPlan) {
        console.log(`Scheduling conflict for machine ${machine._id} in planification ${plan._id}`);
        continue;
      }

      // Calculate planification dates
      const heures = (modeleCommande.quantite / 35) + 2;
      const { debutPrevue: calculatedDebut, finPrevue } = calculatePlanificationDates(debutPrevue, heures);

      // Update machine state
      machine.etat = "occupee";
      await machine.save({ session });

      // Update planification
      plan.machines = [machine._id];
      plan.salle = salleCible._id;
      plan.debutPrevue = calculatedDebut;
      plan.finPrevue = finPrevue;
      plan.statut = "en attente";
      await plan.save({ session });

      // Update commande
      commande.machinesAffectees = [machine._id];
      commande.salleAffectee = salleCible._id;
      commande.etat = "en attente";
      await commande.save({ session });

      // Update material stock
      matiere.quantite -= quantiteNecessaire;
      matiere.historique.push({
        action: "consommation",
        quantite: quantiteNecessaire,
        date: new Date()
      });
      await matiere.save({ session });
    }

    await session.commitTransaction();
  } catch (err) {
    await session.abortTransaction();
    console.error("Erreur lors du traitement de la file d'attente :", err);
  } finally {
    session.endSession();
  }
};
exports.confirmPlanification = async (req, res) => {
  try {
    const { planifications } = req.body;

    // Vérifier le stock avant confirmation
    const matieres = await Matiere.find();
    let hasInsufficientStock = false;

    for (const plan of planifications) {
      for (const commande of plan.commandes) {
        const cmd = await Commande.findById(commande._id || commande).populate(
          "modeles.modele"
        );

        for (const modele of cmd.modeles) {
          const matiere = matieres.find(
            (m) => m.couleur.toLowerCase() === modele.couleur.toLowerCase()
          );

          if (matiere) {
            const consommation = modele.modele.consommation.find(
              (c) => c.taille === modele.taille
            );
            const quantiteNecessaire =
              (consommation?.quantity || 0.5) * modele.quantite;

            if (matiere.quantite < quantiteNecessaire) {
              hasInsufficientStock = true;
              break;
            }
          }
        }
        if (hasInsufficientStock) break;
      }
      if (hasInsufficientStock) break;
    }

    if (!planifications || !Array.isArray(planifications)) {
      return res.status(400).json({
        message: "Les planifications sont requises sous forme de tableau",
      });
    }

    const confirmedPlanifications = [];
    const waitingPlanifications = [];

    for (const plan of planifications) {
      let planification;

      // Check for existing planification to prevent duplication
      const existingPlanification = await Planification.findOne({
        commandes: { $all: plan.commandes.map((c) => c._id || c) },
        salle: plan.salle._id || plan.salle,
        taille: plan.taille || "",
        couleur: plan.couleur || "",
        quantite: plan.quantite || 0,
        statut: { $in: ["en attente", "waiting_resources"] }, // Only match non-completed planifications
      });

      if (existingPlanification) {
        console.log(`Found existing planification for command: ${existingPlanification._id}`);
        planification = existingPlanification;
        // Update fields if necessary
        planification.machines = plan.machines.map((m) => m._id || m);
        if (plan.debutPrevue && !isNaN(new Date(plan.debutPrevue))) {
          planification.debutPrevue = new Date(plan.debutPrevue);
        }
        if (plan.finPrevue && !isNaN(new Date(plan.finPrevue))) {
          planification.finPrevue = new Date(plan.finPrevue);
        }
        planification.statut = plan.statut || "en attente";
      } else if (plan._id && plan._id !== "null" && plan._id !== null) {
        planification = await Planification.findById(plan._id);
        if (!planification) {
          console.warn(`Planification with ID ${plan._id} not found, creating new`);
          planification = new Planification({
            commandes: plan.commandes.map((c) => c._id || c),
            machines: plan.machines.map((m) => m._id || m),
            salle: plan.salle._id || plan.salle,
            debutPrevue: plan.debutPrevue ? new Date(plan.debutPrevue) : new Date(),
            finPrevue: plan.finPrevue ? new Date(plan.finPrevue) : new Date(),
            statut: plan.statut || "en attente",
            quantite: plan.quantite || 0,
            taille: plan.taille || "",
            couleur: plan.couleur || "",
            createdAt: plan.createdAt ? new Date(plan.createdAt) : new Date(),
          });
        } else {
          // Update existing planification
          planification.machines = plan.machines.map((m) => m._id || m);
          planification.salle = plan.salle._id || plan.salle;
          if (plan.debutPrevue && !isNaN(new Date(plan.debutPrevue))) {
            planification.debutPrevue = new Date(plan.debutPrevue);
          }
          if (plan.finPrevue && !isNaN(new Date(plan.finPrevue))) {
            planification.finPrevue = new Date(plan.finPrevue);
          }
          planification.statut = plan.statut || "en attente";
        }
      } else {
        // Create new planification for null ID
        console.log(`Creating new planification for null ID: ${JSON.stringify(plan)}`);
        planification = new Planification({
          commandes: plan.commandes.map((c) => c._id || c),
          machines: plan.machines.map((m) => m._id || m),
          salle: plan.salle._id || plan.salle,
          debutPrevue: plan.debutPrevue ? new Date(plan.debutPrevue) : new Date(),
          finPrevue: plan.finPrevue ? new Date(plan.finPrevue) : new Date(),
          statut: plan.statut || "en attente",
          quantite: plan.quantite || 0,
          taille: plan.taille || "",
          couleur: plan.couleur || "",
          createdAt: plan.createdAt ? new Date(plan.createdAt) : new Date(),
        });
      }

      let salleLight = null;
      if (planification.salle) {
        salleLight = await Salle.findById(planification.salle).select(
          "_id nom type"
        );
      } else {
        console.warn(`No salle assigned to planification ${planification._id || 'new'}`);
      }

      if (planification.statut === "waiting_resources") {
        await planification.save();
        const populatedPlan = await Planification.findById(planification._id)
          .populate({
            path: "commandes",
            populate: { path: "client" },
          })
          .populate({
            path: "machines",
            populate: ["salle", "modele"],
          });
        populatedPlan.salle = salleLight
          ? { _id: salleLight._id, nom: salleLight.nom, type: salleLight.type }
          : null;
        waitingPlanifications.push(populatedPlan);
      } else {
        planification.statut = "en attente";
        await planification.save();

        for (const machineId of planification.machines) {
          const machine = await Machine.findById(machineId);
          if (machine) {
            machine.etat = "occupee";
            await machine.save();
          }
        }
        const populatedPlan = await Planification.findById(planification._id)
          .populate({
            path: "commandes",
            populate: { path: "client" },
          })
          .populate({
            path: "machines",
            populate: ["salle", "modele"],
          });
        populatedPlan.salle = salleLight
          ? { _id: salleLight._id, nom: salleLight.nom, type: salleLight.type }
          : null;
        confirmedPlanifications.push(populatedPlan);
      }
    }

    // Only process waiting list for non-waiting planifications
    if (confirmedPlanifications.length > 0) {
      await exports.processWaitingList();
    }

    res.status(200).json({
      message: "Planifications confirmées",
      confirmedPlanifications,
      waitingPlanifications,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      message: "Erreur lors de la confirmation",
      error: err.message,
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
        path: "commandes",
        populate: { path: "client" },
      })
      .populate({
        path: "machines",
        populate: ["salle", "modele"],
      });

    res.status(200).json(planifications);
  } catch (error) {
    res.status(500).json({ message: "Erreur serveur", error: error.message });
  }
};

exports.getWaitingPlanifications = async (req, res) => {
  try {
    const { commandeId } = req.query;
    const query = {
      statut: { $in: ["en attente", "waiting_resources"] },
    };
    if (commandeId) {
      query.commandes = commandeId;
    }
    const waitingPlans = await Planification.find(query)
      .sort({ order: 1, createdAt: 1 })
      .populate({
        path: "commandes",
        populate: { path: "client" },
      })
      .populate({
        path: "machines",
        populate: ["salle", "modele"],
      });
    for (const plan of waitingPlans) {
      if (plan.salle) {
        const salleLight = await Salle.findById(plan.salle).select("_id nom type");
        plan.salle = salleLight
          ? { _id: salleLight._id, nom: salleLight.nom, type: salleLight.type }
          : null;
      }
    }
    res.status(200).json(waitingPlans);
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
        populate: { path: "client" },
      })
      .populate({
        path: "machines",
        populate: ["salle", "modele"],
      });
    if (!planification) {
      return res.status(404).json({ message: "Planification non trouvée" });
    }
    if (planification.salle) {
      const salleLight = await Salle.findById(planification.salle).select(
        "_id nom type"
      );
      planification.salle = salleLight
        ? { _id: salleLight._id, nom: salleLight.nom, type: salleLight.type }
        : null;
    }
    res.status(200).json(planification);
  } catch (error) {
    console.error("Erreur lors de la récupération de la planification :", error);
    res.status(500).json({ message: "Erreur serveur", error: error.message });
  }
};
exports.deletePlanification = async (req, res) => {
  try {
    const { id } = req.params;
    const deletedPlanification = await Planification.findByIdAndDelete(id);

    if (!deletedPlanification) {
      return res.status(404).json({ message: "Planification non trouvée" });
    }
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



exports.reorderWaitingPlanifications = async (req, res) => {
  try {
    const { orderedIds } = req.body;

    if (!orderedIds || !Array.isArray(orderedIds)) {
      return res.status(400).json({ message: "orderedIds must be an array" });
    }

    // Update order for each Planification (changed from WaitingPlanification)
    const updates = orderedIds.map((id, index) =>
      Planification.updateOne(
        { _id: id, statut: { $in: ["en attente", "waiting_resources"] } },
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