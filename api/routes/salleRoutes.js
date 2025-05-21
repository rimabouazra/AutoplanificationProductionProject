const express = require("express");
const router = express.Router();
const salleController = require("../controllers/salleController");
const { authenticateToken } = require("../middlewares/auth");

router.get("/", salleController.getAllSalles);
router.post("/",  authenticateToken,salleController.creerSalle);
router.put("/:id", salleController.modifierSalle);
router.delete("/:id",  authenticateToken,salleController.supprimerSalle);
router.post("/:salleId/machine",  authenticateToken,salleController.ajouterMachine);
router.put("/machine/:id", salleController.modifierMachine);
router.delete("/:salleId/machine/:machineId", authenticateToken,salleController.supprimerMachine);
router.get("/:salleId/machines", salleController.listerMachinesSalle);
router.get('/:id', salleController.getSalleById);

module.exports = router;
