const Machine = require("../models/Machine");
const Modele = require("../models/Modele");
const Salle = require("../models/Salle");
const moment = require('moment-timezone');
// Middleware de vérification de rôle
const checkRole = (requiredRoles) => {
    return (req, res, next) => {
      console.log('Vérification des rôles - User:', req.user);//DEBUG
      console.log('Rôles requis:', requiredRoles);//DEBUG
      
      if (!req.user) {
        console.log('Aucun utilisateur dans la requête');//DEBUG
        return res.status(403).json({ message: "Accès refusé - Non authentifié" });
      }
      
      if (!requiredRoles.includes(req.user.role)) {
        console.log(`Rôle insuffisant - Rôle actuel: ${req.user.role}, Rôles requis: ${requiredRoles}`);//DEBUG
        return res.status(403).json({ 
          message: `Accès refusé - Rôle ${req.user.role} non autorisé`,
          requiredRoles
        });
      }
      
      console.log('Accès autorisé pour le rôle:', req.user.role);//DEBUG
      next();
    };
  };
exports.ajouterMachine = [
    checkRole(['admin', 'manager']), async (req, res) => {
        try {
            console.log("Requête reçue pour ajouter une machine :", req.body);
            const { nom, etat, salle, modele, taille } = req.body;
            // Vérifier que la salle existe
            const salleExistante = await Salle.findById(salle);
            if (!salleExistante) {
                console.log("Salle non trouvée !");
                return res.status(404).json({ message: "Salle non trouvée" });
            }
            // Créer la machine
            const nouvelleMachine = new Machine({ nom, etat, salle, modele, taille });
            await nouvelleMachine.save();

            // Ajouter la machine à la salle
            salleExistante.machines.push(nouvelleMachine._id);
            await salleExistante.save();

            res.status(201).json(nouvelleMachine);
        } catch (error) {
            res.status(500).json({ message: "Erreur lors de l'ajout de la machine", error });
        }
    }];


exports.getMachines = async (req, res) => {
    try {
        const machines = await Machine.find().populate("modele").populate("salle");
        res.status(200).json(machines);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la récupération des machines", error });
    }
};

exports.getMachineById = async (req, res) => {
    try {
        const machine = await Machine.findById(req.params.id).populate("modele").populate("salle");
        if (!machine) {
            return res.status(404).json({ message: "Machine non trouvée" });
        }
        res.status(200).json(machine);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la récupération de la machine", error });
    }
};

exports.getMachinesBySalle = async (req, res) => {
    try {
        const { salleId } = req.params;

        // Trouver la salle avec ses machines
        const salle = await Salle.findById(salleId).populate({
            path: "machines",
            populate: [{ path: "modele" }, { path: "salle" }] // Charger aussi la salle et le modéle de chaque machine
        });

        if (!salle) {
            return res.status(404).json({ message: "Salle non trouvée" });
        }

        res.status(200).json(salle.machines); // Renvoyer uniquement les machines
    } catch (error) {
        console.error("Erreur lors de la récupération des machines :", error);
        res.status(500).json({ message: "Erreur serveur" });
    }
};




exports.updateMachine = [
  checkRole(['admin', 'manager', 'responsable_modele']), async (req, res) => {
      try {
          const { nom, etat, salle, modele, taille } = req.body;

          const machine = await Machine.findById(req.params.id);
          if (!machine) {
              return res.status(404).json({ message: "Machine non trouvée" });
          }


          // Mise à jour des champs si fournis
          if (nom) machine.nom = nom;
          if (etat) machine.etat = etat;
          if (salle) machine.salle = salle;
          if (modele) {
              const modeleExistant = await Modele.findById(modele);
              if (!modeleExistant) {
                  return res.status(404).json({ message: "Modèle non trouvé" });
              }
              machine.modele = modele;
          }
          if (taille) machine.taille = taille;

          await machine.save();
          res.status(200).json(machine);
      } catch (error) {
          res.status(500).json({ message: "Erreur lors de la mise à jour de la machine", error });
      }
  }];

exports.deleteMachine = [
  checkRole(['admin', 'manager']),
  async (req, res) => {
    try {
      const machine = await Machine.findById(req.params.id);
      if (!machine) {
        return res.status(404).json({ message: "Machine non trouvée" });
      }

      // Vérifier si la machine est utilisée dans une planification active
      const now = moment().tz('Africa/Tunis').toDate();
      const activePlanification = await Planification.findOne({
        machines: req.params.id,
        statut: { $ne: "terminée" },
        debutPrevue: { $lte: now },
        finPrevue: { $gt: now },
      });
      if (activePlanification) {
        return res.status(400).json({
          message: "Impossible de supprimer la machine : elle est utilisée dans une planification active",
        });
      }

      // Retirer la machine de la salle associée
      if (machine.salle) {
        await Salle.findByIdAndUpdate(machine.salle, {
          $pull: { machines: machine._id }
        });
      }

      // Supprimer la machine
      await Machine.findByIdAndDelete(req.params.id);
      res.status(200).json({ message: "Machine supprimée avec succès" });
    } catch (error) {
      console.error("Erreur lors de la suppression de la machine :", error);
      res.status(500).json({ message: "Erreur lors de la suppression de la machine", error: error.message });
    }
  }
];