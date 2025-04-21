const express = require("express");
const router = express.Router();
const MachineController = require("../controllers/machineController");
const auth = require("../middlewares/auth");

router.post("/add", auth.authenticateToken,MachineController.ajouterMachine);

router.get("/", MachineController.getMachines);
router.get("/:id", MachineController.getMachineById);
router.get("/parSalle/:salleId", MachineController.getMachinesBySalle);
router.put("/:id", auth.authenticateToken,MachineController.updateMachine);
router.delete("/:id",auth.authenticateToken, MachineController.deleteMachine);

module.exports = router;
