const express = require("express");
const router = express.Router();
const MachineController = require("../controllers/machineController");

// Route pour ajouter une machine
router.post("/add", MachineController.ajouterMachine);

// Route pour récupérer toutes les machines
router.get("/", MachineController.getMachines);

// Route pour récupérer une machine par ID
router.get("/:id", MachineController.getMachineById);

router.get("/parSalle/:salleId", MachineController.getMachinesBySalle);


// Route pour modifier une machine
router.put("/:id", MachineController.updateMachine);

// Route pour supprimer une machine
router.delete("/:id", MachineController.deleteMachine);

module.exports = router;
