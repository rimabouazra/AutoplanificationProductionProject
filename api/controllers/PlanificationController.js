const Planification = require("../models/Planification");
const Commande = require("../models/Commande");
const Salle = require("../models/Salle");
const Machine = require("../models/Machine");
const Modele = require("../models/Modele");
const moment = require('moment-timezone');
const Matiere = require("../models/matiere");
const mongoose = require('mongoose');

// 7 AM to 5 PM, Tunisia timezone
let workHoursConfig = {
  startHour: 7, // 7 AM
  endHour: 17, // 5 PM
  timezone: "Africa/Tunis"
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
  let currentDate = moment(startDate).tz(workHours.timezone).startOf('minute');
  let remainingHours = hoursRequired;
  let workDayHours = workHours.endHour - workHours.startHour;

  if (currentDate.isBefore(moment().tz(workHours.timezone))) {
    currentDate = moment().tz(workHours.timezone).startOf('minute');
  }

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
    let hoursUntilEndOfDay = workHours.endHour - currentDate.hour();
    if (hoursUntilEndOfDay <= 0) {
      currentDate.add(1, 'day').set({ hour: workHours.startHour, minute: 0, second: 0 });
      hoursUntilEndOfDay = workDayHours;
    }
    let hoursToUse = Math.min(remainingHours, hoursUntilEndOfDay);
    remainingHours -= hoursToUse;

    if (remainingHours <= 0) {
      currentDate.add(hoursToUse, 'hours');
      finPrevue = currentDate.toDate();
    } else {
      currentDate.add(1, 'day').set({ hour: workHours.startHour, minute: 0, second: 0 });
    }
  }

  return { debutPrevue, finPrevue };
};
exports.checkActivePlanification = async (req, res) => {
  try {
    const { machineId } = req.params;

    const now = moment().tz("Africa/Tunis").toDate();
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
const now = moment().tz("Africa/Tunis").toDate();
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
    const now = moment().tz("Africa/Tunis").toDate();
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
      console.log("cron job: update planification statut en cours");
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
        populate: { path: "bases" },
      })
      .populate("client");

    if (!commande) {
      return res.status(404).json({ message: "Commande non trouvée", id: commandeId });
    }

    // Vérifier le stock
    const matieres = await Matiere.find();
    let hasInsufficientStock = false;

    for (const modele of commande.modeles) {
      const matiere = matieres.find(
        (m) => m.couleur.toLowerCase() === modele.couleur.toLowerCase()
      );
      if (matiere) {
        let targetModele = modele.modele;
        let targetTaille = modele.taille;

        if (modele.modele.bases && modele.modele.bases.length > 0) {
          const baseModele = await Modele.findById(modele.modele.bases[0]);
          if (!baseModele) {
            console.warn(`Base model with ID ${modele.modele.bases[0]} not found, using original model`);
          } else {
            targetModele = baseModele;
          }

          // Find the tailleBase entry, ensuring baseId exists
          const tailleBaseEntry = modele.modele.taillesBases.find(
            (tb) => tb.baseId && tb.baseId.equals(targetModele._id)
          );
          if (!tailleBaseEntry) {
            console.warn(
              `No valid tailleBase entry found for base model ${targetModele._id}, falling back to original taille`
            );
            targetTaille = modele.taille;
          } else {
            const tailleIndex = modele.modele.tailles.indexOf(modele.taille);
            targetTaille =
              tailleIndex >= 0 && tailleBaseEntry.tailles[tailleIndex]
                ? tailleBaseEntry.tailles[tailleIndex]
                : modele.taille;
          }
        }

       const consommation = targetModele.consommation.find(
         (c) => c.taille === targetTaille
       );
       const quantiteNecessaire = ((consommation?.quantity ?? 0.5) * modele.quantite); // Use nullish coalescing operator
       if (!consommation) {
         console.warn(`No consommation found for modele ${targetModele._id} with taille ${targetTaille}, using default 0.5`);
       }

        if (matiere.quantite < quantiteNecessaire) {
          hasInsufficientStock = true;
          break;
        }
      } else {
        console.warn(`No matiere found for couleur ${modele.couleur}`);
        hasInsufficientStock = true;
        break;
      }
    }

    if (hasInsufficientStock && !preview) {
      const waitingPlan = new Planification({
        commandes: [commande._id],
        machines: [],
        statut: "waiting_resources",
        createdAt: moment().tz("Africa/Tunis").toDate(),
      });
      await waitingPlan.save();

      const populatedWaitingPlan = await Planification.findById(waitingPlan._id)
        .populate({
          path: "commandes",
          populate: { path: "client" },
        });
      if (waitingPlan.salle) {
        const salleLight = await Salle.findById(waitingPlan.salle).select(
          "_id nom type"
        );
        populatedWaitingPlan.salle = salleLight
          ? { _id: salleLight._id, nom: salleLight.nom, type: salleLight.type }
          : null;
      }
      return res.status(201).json({
        planifications: [populatedWaitingPlan],
        statut: "en attente",
      });
    }

    const salles = await Salle.find();
    const machines = await Machine.find().populate("modele").populate("salle");
    const planifications = [];
    const allMachinesAssignees = [];
    const allSallesUtilisees = new Set();
    const partialPlanifications = [];

    for (const modele of commande.modeles) {
      const estFoncee = ["noir", "bleu marine", "bleu", "vert"].includes(modele.couleur.toLowerCase());
      const salleCible = salles.find((s) => (estFoncee ? s.type === "noir" : s.type === "blanc"));

      if (!salleCible) {
        return res.status(400).json({
          message: `Salle de type ${estFoncee ? "noir" : "blanc"} introuvable`,
        });
      }

      const machinesSalle = machines.filter((m) => m.salle._id.equals(salleCible._id));

      // Determine which model and size to use for machine selection
      let targetModele = modele.modele;
      let targetTaille = modele.taille;

      if (modele.modele.bases && modele.modele.bases.length > 0) {
        const baseModele = await Modele.findById(modele.modele.bases[0]);
        if (!baseModele) {
          console.warn(`Base model with ID ${modele.modele.bases[0]} not found, using original model`);
        } else {
          targetModele = baseModele;

          const tailleBaseEntry = modele.modele.taillesBases.find(
            (tb) => tb.baseId && tb.baseId.equals(targetModele._id)
          );
          if (!tailleBaseEntry) {
            console.warn(
              `No valid tailleBase entry found for base model ${targetModele._id}, falling back to original taille`
            );
            targetTaille = modele.taille;
          } else {
            const tailleIndex = modele.modele.tailles.indexOf(modele.taille);
            targetTaille =
              tailleIndex >= 0 && tailleBaseEntry.tailles[tailleIndex]
                ? tailleBaseEntry.tailles[tailleIndex]
                : modele.taille;
          }
        }
      }

      let machine = machinesSalle.find(
        (m) =>
          m.modele &&
          m.modele._id.equals(targetModele._id) &&
          m.taille === targetTaille &&
          m.etat === "disponible"
      );

      const matiere = matieres.find((m) => m.couleur.toLowerCase() === modele.couleur.toLowerCase());
      const consommation = modele.modele.consommation.find((c) => c.taille === modele.taille);
      const quantiteNecessaire = (consommation?.quantity || 0.5) * modele.quantite; // Define quantiteNecessaire here

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
        if (!machine) {
          machine = machinesSalle.find((m) => m.etat === "disponible");
        }

        if (!machine) {
          quantiteEnAttente += quantitePlanifiee;
          quantitePlanifiee = 0;
        } else {
          const heures = quantitePlanifiee / 35 + 2;
          const now = moment().tz("Africa/Tunis").toDate();
          console.log("Current time in Africa/Tunis:", moment().tz("Africa/Tunis").format());
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
            statut: "en attente",
            taille: modele.taille,
            couleur: modele.couleur,
            quantite: quantitePlanifiee,
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
          createdAt: moment().tz("Africa/Tunis").toDate(),
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
      commande.etat = hasInsufficientStock || partialPlanifications.length > 0 ? "en attente" : "en moulage";
      await commande.save();
    }

    const response = {
      planifications: [...planifications, ...partialPlanifications],
      statut: hasInsufficientStock || partialPlanifications.length > 0 ? "en attente" : "planifiée",
      hasInsufficientStock,
      partialAvailable: hasInsufficientStock || partialPlanifications.length > 0,
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
    const matieres = await Matiere.find().session(session);
    const activePlanifications = await Planification.find({
      statut: { $ne: "terminée" }
    }).session(session);

    for (const plan of waitingPlans) {
      if (plan.machines.length > 0) {
        console.log(`Planification ${plan._id} already has machines assigned`);
        continue;
      }
    if (!plan.taille || !plan.couleur) {
            console.error(`Invalid planification ${plan._id}: taille=${plan.taille}, couleur=${plan.couleur}`);
            continue;
        }
      const commande = await Commande.findById(plan.commandes[0])
        .populate({
          path: 'modeles.modele',
          populate: { path: 'bases' },
        })
        .session(session);

      if (!commande || commande.modeles.length === 0) {
        console.log(`Commande or models not found for planification ${plan._id}`);
        continue;
      }

      // Find the specific modele for this planification
      const modeleCommande = commande.modeles.find(
        (m) => m.taille === plan.taille && m.couleur.toLowerCase() === plan.couleur.toLowerCase()
      );

      if (!modeleCommande) {
        console.log(`Model not found for planification ${plan._id} with taille ${plan.taille} and couleur ${plan.couleur}`);
        continue;
      }

      // Determine target model and size
      let targetModele = modeleCommande.modele;
      let targetTaille = modeleCommande.taille;

      if (modeleCommande.modele.bases && modeleCommande.modele.bases.length > 0) {
        const baseModele = await Modele.findById(modeleCommande.modele.bases[0]).session(session);
        if (!baseModele) {
          console.warn(`Base model with ID ${modeleCommande.modele.bases[0]} not found for planification ${plan._id}`);
          continue;
        }
        targetModele = baseModele;

        const tailleBaseEntry = modeleCommande.modele.taillesBases.find(
          (tb) => tb.baseId && tb.baseId.equals(targetModele._id)
        );
        if (tailleBaseEntry) {
          const tailleIndex = modeleCommande.modele.tailles.indexOf(modeleCommande.taille);
          targetTaille = tailleIndex >= 0 && tailleBaseEntry.tailles[tailleIndex]
            ? tailleBaseEntry.tailles[tailleIndex]
            : modeleCommande.taille;
        } else {
          console.warn(`No valid tailleBase entry found for base model ${targetModele._id} in planification ${plan._id}`);
        }
      }

      // Check stock availability
      const matiere = matieres.find(
        (m) => m.couleur.toLowerCase() === modeleCommande.couleur.toLowerCase()
      );

      if (!matiere) {
        console.log(`No matiere found for couleur ${modeleCommande.couleur} in planification ${plan._id}`);
        continue;
      }

      // Define consommation before using it
      const consommation = targetModele.consommation.find(
        (c) => c.taille === targetTaille
      );
      const quantiteNecessaire = (consommation?.quantity ?? 0.5) * modeleCommande.quantite;

      if (matiere.quantite < quantiteNecessaire) {
        console.log(`Insufficient stock for planification ${plan._id}: ${quantiteNecessaire} needed, ${matiere.quantite} available`);
        continue;
      }

      // Rest of the function (machine selection, scheduling, etc.) remains unchanged
      const estFoncee = ["noir", "bleu marine", "bleu", "vert"].includes(modeleCommande.couleur.toLowerCase());
      const salleCible = salles.find(s => estFoncee ? s.type === "noir" : s.type === "blanc");

      if (!salleCible) {
        console.log(`Salle de type ${estFoncee ? 'noir' : 'blanc'} not found for planification ${plan._id}`);
        continue;
      }

      const machinesSalle = machines.filter(m => m.salle._id.equals(salleCible._id));
      let machine = machinesSalle.find(m =>
        m.modele && m.modele._id.equals(targetModele._id) &&
        m.taille === targetTaille &&
        m.etat === "disponible"
      );

      let debutPrevue =moment().tz("Africa/Tunis").toDate();
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
            console.log(`No available machine in salle ${salleCible.nom} for planification ${plan._id}`);
            continue;
          }
        }

        // Configure machine to match planification requirements
        machine.modele = targetModele._id;
        machine.taille = targetTaille;
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

      machine.etat = "occupee";
      await machine.save({ session });

      const heures = (modeleCommande.quantite / 35) + 2;
      const { debutPrevue: calculatedDebut, finPrevue: calculatedFin } = calculatePlanificationDates(debutPrevue, heures);
      debutPrevue = calculatedDebut;
      finPrevue = calculatedFin;

      plan.machines = [machine._id];
      plan.salle = salleCible._id;
      plan.debutPrevue = calculatedDebut;
      plan.finPrevue = calculatedFin;
      plan.statut = "en attente";
      await plan.save({ session });

      commande.machinesAffectees = [machine._id];
      commande.salleAffectee = salleCible._id;
      commande.etat = "en attente";
      await commande.save({ session });

      // Update material stock
      matiere.quantite -= quantiteNecessaire;
      matiere.historique.push({
        action: "consommation",
        quantite: quantiteNecessaire,
        date: moment().tz("Africa/Tunis").toDate()
      });
      await matiere.save({ session });
    }

    await session.commitTransaction();
  } catch (err) {
    await session.abortTransaction();
    console.error(`Erreur lors du traitement de la file d attente: ${err.message}`, err);
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
      if (!plan.taille || !plan.couleur) {
        console.error(`Invalid planification ${plan._id}: taille (${plan.taille}) or couleur (${plan.couleur}) is missing or undefined`);
        continue;
      }

      if (plan.machines.length > 0) {
        console.log(`Planification ${plan._id} already has machines assigned`);
        continue;
      }
      for (const commande of plan.commandes) {
        const cmd = await Commande.findById(commande._id || commande).populate({
          path: "modeles.modele",
          populate: { path: "bases" },
        });

        for (const modele of cmd.modeles) {
          const matiere = matieres.find(
            (m) => m.couleur.toLowerCase() === modele.couleur.toLowerCase()
          );

          if (matiere) {
            let targetModele = modele.modele;
            let targetTaille = modele.taille;

            if (modele.modele.bases && modele.modele.bases.length > 0) {
              targetModele = await Modele.findById(modele.modele.bases[0]);
              const tailleBaseEntry = modele.modele.taillesBases.find(
                (tb) => tb.baseId.equals(targetModele._id)
              );
              targetTaille = tailleBaseEntry ? tailleBaseEntry.tailles[modele.modele.tailles.indexOf(modele.taille)] : modele.taille;
            }

            const consommation = targetModele.consommation.find(
              (c) => c.taille === targetTaille);

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

      // Check for existing planification by command, taille, couleur, and quantite
      const existingPlanification = await Planification.findOne({
        commandes: { $all: plan.commandes.map((c) => c._id || c) },
        salle: plan.salle._id || plan.salle,
        taille: plan.taille || "",
        couleur: plan.couleur || "",
        quantite: plan.quantite || 0,
        statut: { $in: ["en attente", "waiting_resources"] },
      });

      if (existingPlanification) {
        console.log(`Found existing planification: ${existingPlanification._id}`);
        planification = existingPlanification;
        // Update fields
        planification.machines = plan.machines.map((m) => m._id || m);
        planification.debutPrevue = plan.debutPrevue ? new Date(plan.debutPrevue) : planification.debutPrevue;
        planification.finPrevue = plan.finPrevue ? new Date(plan.finPrevue) : planification.finPrevue;
        planification.statut = plan.statut || "en attente";
      } else if (plan._id && plan._id !== "null" && plan._id !== null) {
        planification = await Planification.findById(plan._id);
        if (!planification) {
          console.warn(`Planification with ID ${plan._id} not found, creating new`);
          planification = new Planification({
            commandes: plan.commandes.map((c) => c._id || c),
            machines: plan.machines.map((m) => m._id || m),
            salle: plan.salle._id || plan.salle,
            debutPrevue: plan.debutPrevue ? new Date(plan.debutPrevue) : moment().tz("Africa/Tunis").toDate(),
            finPrevue: plan.finPrevue ? new Date(plan.finPrevue) : moment().tz("Africa/Tunis").toDate(),
            statut: plan.statut || "en attente",
            quantite: plan.quantite || 0,
            taille: plan.taille || "",
            couleur: plan.couleur || "",
            createdAt: plan.createdAt ? new Date(plan.createdAt) : moment().tz("Africa/Tunis").toDate(),
          });
        } else {
          // Update existing planification
          planification.machines = plan.machines.map((m) => m._id || m);
          planification.salle = plan.salle._id || plan.salle;
          planification.debutPrevue = plan.debutPrevue ? new Date(plan.debutPrevue) : planification.debutPrevue;
          planification.finPrevue = plan.finPrevue ? new Date(plan.finPrevue) : planification.finPrevue;
          planification.statut = plan.statut || "en attente";
        }
      } else {
        // Avoid creating new planification if it matches an existing one
        console.log(`No existing planification found, checking for duplicates before creating: ${JSON.stringify(plan)}`);
        const duplicateCheck = await Planification.findOne({
          commandes: { $all: plan.commandes.map((c) => c._id || c) },
          salle: plan.salle._id || plan.salle,
          taille: plan.taille || "",
          couleur: plan.couleur || "",
          quantite: plan.quantite || 0,
          statut: { $in: ["en attente", "waiting_resources"] },
        });
        if (duplicateCheck) {
          console.log(`Duplicate planification found: ${duplicateCheck._id}, updating instead`);
          planification = duplicateCheck;
          planification.machines = plan.machines.map((m) => m._id || m);
          planification.debutPrevue = plan.debutPrevue ? new Date(plan.debutPrevue) : planification.debutPrevue;
          planification.finPrevue = plan.finPrevue ? new Date(plan.finPrevue) : planification.finPrevue;
          planification.statut = plan.statut || "en attente";
        } else {
          planification = new Planification({
            commandes: plan.commandes.map((c) => c._id || c),
            machines: plan.machines.map((m) => m._id || m),
            salle: plan.salle._id || plan.salle,
            debutPrevue: plan.debutPrevue ? new Date(plan.debutPrevue) : moment().tz("Africa/Tunis").toDate(),
            finPrevue: plan.finPrevue ? new Date(plan.finPrevue) : moment().tz("Africa/Tunis").toDate(),
            statut: plan.statut || "en attente",
            quantite: plan.quantite || 0,
            taille: plan.taille || "",
            couleur: plan.couleur || "",
            createdAt: plan.createdAt ? new Date(plan.createdAt) : moment().tz("Africa/Tunis").toDate(),
          });
        }
      }

      let salleLight = null;
      if (planification.salle) {
        salleLight = await Salle.findById(planification.salle).select(
          "_id nom type"
        );
      } else {
        console.warn(`No salle assigned to planification ${planification._id || 'new'}`);
      }

      if (hasInsufficientStock || planification.statut === "waiting_resources") {
        planification.statut = "waiting_resources";
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

    // Mettre à jour les machines associées à "disponible"
    for (const machineId of deletedPlanification.machines) {
      const machine = await Machine.findById(machineId);
      if (machine && machine.etat !== "disponible") {
        machine.etat = "disponible";
        await machine.save();
      }
    }

    // Traiter la liste d'attente pour réassigner les machines disponibles
    await exports.processWaitingList();

    res.status(200).json({ message: "Planification supprimée avec succès, machines libérées" });
  } catch (error) {
    console.error("Erreur lors de la suppression de la planification :", error);
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
      console.log('Invalid orderedIds:', orderedIds);
      return res.status(400).json({ message: "orderedIds must be an array" });
    }

    const BATCH_SIZE = 10; // Process in batches
    for (let i = 0; i < orderedIds.length; i += BATCH_SIZE) {
      const batch = orderedIds.slice(i, i + BATCH_SIZE);
      const updates = batch.map((id, index) =>
        Planification.updateOne(
          { _id: id, statut: { $in: ["en attente", "waiting_resources"] } },
          { $set: { order: i + index } }
        )
      );
      await Promise.all(updates);
    }

    res.status(200).json({ message: "Waiting planifications reordered successfully" });
  } catch (error) {
    console.error("Error in reorderWaitingPlanifications:", error);
    res.status(500).json({ message: "Erreur serveur", error: error.message });
  }
};
exports.terminerPlanification = async (req, res) => {
  try {
    const { id } = req.params;

    // Find the planification
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

    if (planification.statut === "terminée") {
      return res.status(400).json({ message: "Planification déjà terminée" });
    }

    // Update planification status
    planification.statut = "terminée";
    await planification.save();

    // Update associated machines to disponible
    for (const machineId of planification.machines) {
      const machine = await Machine.findById(machineId);
      if (machine) {
        machine.etat = "disponible";
        await machine.save();
      }
    }

    // Update associated commandes to "en presse"
    for (const commandeId of planification.commandes) {
      const commande = await Commande.findById(commandeId);
      if (commande) {
        commande.etat = "en presse";
        await commande.save();
      }
    }

    // Process waiting list to assign machines to pending planifications
    await exports.processWaitingList();

    // Populate salle for response
    let salleLight = null;
    if (planification.salle) {
      salleLight = await Salle.findById(planification.salle).select("_id nom type");
      planification.salle = salleLight
        ? { _id: salleLight._id, nom: salleLight.nom, type: salleLight.type }
        : null;
    }

    res.status(200).json({
      message: "Planification terminée avec succès",
      planification,
    });
  } catch (error) {
    console.error("Erreur lors de la terminaison de la planification :", error);
    res.status(500).json({
      message: "Erreur serveur",
      error: error.message,
    });
  }
};