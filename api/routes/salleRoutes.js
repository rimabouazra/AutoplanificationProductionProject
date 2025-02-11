const express = require("express");
const router = express.Router();
const salleController = require("../controllers/salleController");

router.post("/", salleController.creerSalle);
router.put("/:id", salleController.modifierSalle);
router.delete("/:id", salleController.supprimerSalle);

router.post("/:salleId/machine", salleController.ajouterMachine);
router.put("/machine/:id", salleController.modifierMachine);
router.delete("/:salleId/machine/:machineId", salleController.supprimerMachine);
router.get("/:salleId/machines", salleController.listerMachinesSalle);

module.exports = router;
