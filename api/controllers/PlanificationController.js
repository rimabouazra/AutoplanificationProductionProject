const Planification = require("../models/Planification");
const Commande = require("../models/Commande");
const Salle = require("../models/Salle");
const Machine = require("../models/Machine");
const Modele = require("../models/Modele");
const moment = require('moment-timezone');
const Matiere = require("../models/Matiere");
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
      console.log("cron job : update planification statut en cours")
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
//we need to populate the base in the modele
exports.autoPlanifierCommande = async (req, res) => {
  try {
    const { commandeId, preview } = req.body;

    if (!commandeId) {
      return res.status(400).json({ message: "CommandeId is missing" });
    }

    const commande = await Commande.findById(commandeId)
      .populate({
        path: "modeles.modele",
        populate: { path: "bases" },
      })
      .populate("client");

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
            continue; // Skip to original model if base model is not found
          }
          targetModele = baseModele;

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
        const quantiteNecessaire =
          (consommation?.quantity || 0.5) * modele.quantite;

        if (matiere.quantite < quantiteNecessaire) {
          hasInsufficientStock = true;
          break;
        }
      }
    }

    if (hasInsufficientStock && !preview) {
      const waitingPlan = new Planification({
        commandes: [commande._id],
        machines: [],
        statut: "waiting_resources",
        createdAt: new Date(),
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

    if (!commande) {
      return res.status(404).json({
        message: "Commande non trouvée",
        id: commandeId,
      });
    }

    const salles = await Salle.find();
    const machines = await Machine.find()
      .populate("modele")
      .populate("salle");
    const planifications = [];
    const allMachinesAssignees = [];
    const allSallesUtilisees = new Set();

    for (const modele of commande.modeles) {
      const estFoncee = ["noir", "bleu marine", "bleu", "vert"].includes(
        modele.couleur.toLowerCase()
      );
      const salleCible = salles.find((s) =>
        estFoncee ? s.type === "noir" : s.type === "blanc"
      );

      if (!salleCible) {
        return res.status(400).json({
          message: `Salle de type ${estFoncee ? "noir" : "blanc"} introuvable`,
        });
      }

      const machinesSalle = machines.filter((m) =>
        m.salle._id.equals(salleCible._id)
      );
       //the planification is done withe the base
      // Determine which model and size to use for machine selection
      let targetModele = modele.modele;
      let targetTaille = modele.taille;

      if (modele.modele.bases && modele.modele.bases.length > 0) {
        const baseModele = await Modele.findById(modele.modele.bases[0]);
        if (!baseModele) {
          console.warn(`Base model with ID ${modele.modele.bases[0]} not found, using original model`);
        } else {
          targetModele = baseModele;

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
      }

      let machine = machinesSalle.find(
        (m) =>
          m.modele &&
          m.modele._id.equals(targetModele._id) &&
          m.taille === targetTaille &&
          m.etat === "disponible"
      );

      if (!machine) {
        machine = machinesSalle.find((m) => m.etat === "disponible");
      }

      if (!machine) {
        const planification = {
          commandes: [commande._id],
          machines: [],
          taille: modele.taille,
          couleur: modele.couleur,
          quantite: modele.quantite,
          salle: salleCible._id,
          statut: "waiting_resources",
          createdAt: moment().tz("CET").toDate(),
        };

        if (!preview) {
          const newPlanification = new Planification(planification);
          await newPlanification.save();
          const populatedPlanification = await Planification.findById(
            newPlanification._id
          ).populate({
            path: "commandes",
            populate: { path: "client" },
          });
          if (newPlanification.salle) {
            const salleLight = await Salle.findById(newPlanification.salle).select(
              "_id nom type"
            );
            populatedPlanification.salle = salleLight
              ? { _id: salleLight._id, nom: salleLight.nom, type: salleLight.type }
              : null;
          }
          planifications.push(populatedPlanification);
        } else {
          const populatedCommande = await Commande.findById(commande._id)
            .populate("client")
            .populate("modeles.modele");
          planification.commandes = [populatedCommande];
          planification.salle = {
            _id: salleCible._id,
            nom: salleCible.nom,
            type: salleCible.type,
          };
          planifications.push(planification);
        }
        continue;
      }

      const heures = modele.quantite / 35 + 2;
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
        statut: "en attente",
        // Store the original model details for reference
        taille: modele.taille,
        couleur: modele.couleur,
        quantite: modele.quantite,
      };

      if (preview) {
        const populatedCommande = await Commande.findById(commande._id)
          .populate("client")
          .populate("modeles.modele");
        const populatedMachine = await Machine.findById(machine._id)
          .populate({ path: "salle", select: "nom type" })
          .populate("modele");
        const salleLight = await Salle.findById(salleCible._id).select(
          "_id nom type"
        );
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
        const populatedPlanification = await Planification.findById(
          nouvellePlanification._id
        )
          .populate({
            path: "commandes",
            populate: { path: "client" },
          })
          .populate({
            path: "machines",
            populate: ["salle", "modele"],
          });
        if (nouvellePlanification.salle) {
          const salleLight = await Salle.findById(nouvellePlanification.salle).select(
            "_id nom type"
          );
          populatedPlanification.salle = salleLight
            ? { _id: salleLight._id, nom: salleLight.nom, type: salleLight.type }
            : null;
        }
        planifications.push(populatedPlanification);
      }
    }

    if (!preview && planifications.length > 0) {
      commande.machinesAffectees = allMachinesAssignees;
      commande.salleAffectee = [...allSallesUtilisees][0];
      commande.etat = planifications.some((p) => p.statut === "waiting_resources")
        ? "en attente"
        : "en attente";
      await commande.save();
    }

    const response = {
      planifications,
      statut: planifications.some((p) => p.statut === "waiting_resources")
        ? "en attente"
        : "planifiée",
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
  try {
    const waitingPlans = await Planification.find({ statut: "waiting_resources" })
      .sort({ order: 1, createdAt: 1 })
      .populate('commandes');

    const salles = await Salle.find();
    const machines = await Machine.find().populate("modele").populate("salle");
    const activePlanifications = await Planification.find({
      statut: { $ne: "terminée" }
    });

    for (const plan of waitingPlans) {
      const commande = await Commande.findById(plan.commandes[0])
        .populate({
          path: 'modeles.modele',
          populate: { path: 'bases' },
        });

      if (!commande || commande.modeles.length === 0) {
        console.log("Commande ou modèles non trouvés");
        continue;
      }

      const modeleCommande = commande.modeles[0].modele;
      const tailleCommande = commande.modeles[0].taille;
      const couleurCommande = commande.modeles[0].couleur;
      const quantiteCommande = commande.modeles[0].quantite;

      // Determine which model and size to use
      let targetModele = modeleCommande;
      let targetTaille = tailleCommande;

      if (modeleCommande.bases && modeleCommande.bases.length > 0) {
        targetModele = await Modele.findById(modeleCommande.bases[0]);
        const tailleBaseEntry = modeleCommande.taillesBases.find(
          (tb) => tb.baseId.equals(targetModele._id)
        );
        targetTaille = tailleBaseEntry ? tailleBaseEntry.tailles[modeleCommande.tailles.indexOf(tailleCommande)] : tailleCommande;
      }

      const estFoncee = ["noir", "bleu marine", "bleu", "vert"].includes(couleurCommande.toLowerCase());
      const salleCible = salles.find(s => estFoncee ? s.type === "noir" : s.type === "blanc");

      if (!salleCible) {
        console.log(`Salle de type ${estFoncee ? 'noir' : 'blanc'} introuvable`);
        continue;
      }

      const machinesSalle = machines.filter(m => m.salle._id.equals(salleCible._id));
      let machine = machinesSalle.find(m =>
        m.modele && m.modele._id.equals(targetModele._id) &&
        m.taille === targetTaille &&
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

        machine.modele = targetModele._id;
        machine.taille = targetTaille;
        machine.etat = "occupee";
        await machine.save();
      } else {
        machine.etat = "occupee";
        await machine.save();
      }

      const heures = (quantiteCommande / 35) + 2;
      const { debutPrevue: calculatedDebut, finPrevue: calculatedFin } = calculatePlanificationDates(debutPrevue, heures);
      debutPrevue = calculatedDebut;
      finPrevue = calculatedFin;

      plan.machines = [machine._id];
      plan.salle = salleCible._id;
      plan.debutPrevue = debutPrevue;
      plan.finPrevue = finPrevue;
      plan.statut = "en attente";
      await plan.save();

      commande.machinesAffectees = [machine._id];
      commande.salleAffectee = salleCible._id;
      commande.etat = "en attente";
      await commande.save();
    }
  } catch (err) {
    console.error("Erreur lors du traitement de la file d'attente :", err);
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
              (c) => c.taille === targetTaille
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

    // Si stock insuffisant, mettre en attente
    if (hasInsufficientStock) {
      const waitingPlans = [];
      for (const plan of planifications) {
        const waitingPlan = await Planification.findByIdAndUpdate(
          plan._id,
          { statut: "waiting_resources", createdAt: new Date() },
          { new: true }
        )
          .populate({
            path: "commandes",
            populate: { path: "client" },
          })
          .populate({
            path: "machines",
            populate: ["salle", "modele"],
          });
        if (waitingPlan.salle) {
          const salleLight = await Salle.findById(waitingPlan.salle).select(
            "_id nom type"
          );
          waitingPlan.salle = salleLight
            ? { _id: salleLight._id, nom: salleLight.nom, type: salleLight.type }
            : null;
        }
        waitingPlans.push(waitingPlan);
      }

      return res.status(200).json({
        message: "Planifications mises en attente - stock insuffisant",
        planifications: waitingPlans,
      });
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
      if (plan._id) {
        planification = await Planification.findById(plan._id);
        if (!planification) continue;

        planification.machines = plan.machines.map((m) => m._id || m);
        planification.salle = plan.salle._id || plan.salle;
        if (plan.debutPrevue && !isNaN(new Date(plan.debutPrevue))) {
          planification.debutPrevue = new Date(plan.debutPrevue);
        }
        if (plan.finPrevue && !isNaN(new Date(plan.finPrevue))) {
          planification.finPrevue = new Date(plan.finPrevue);
        }

        planification.statut = "en attente";

        await planification.save();
      } else {
        planification = new Planification({
          commandes: plan.commandes.map((c) => c._id || c),
          machines: plan.machines.map((m) => m._id || m),
          salle: plan.salle._id || plan.salle,
          debutPrevue: new Date(plan.debutPrevue),
          finPrevue: new Date(plan.finPrevue),
          statut: plan.statut || "en attente",
        });
      }

      let salleLight = null;
      if (planification.salle) {
        salleLight = await Salle.findById(planification.salle).select(
          "_id nom type"
        );
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

    await exports.processWaitingList();

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