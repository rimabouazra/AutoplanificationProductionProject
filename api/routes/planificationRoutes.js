const express = require("express");
const router = express.Router();
const planificationController = require("../controllers/PlanificationController");

router.get("/waiting", planificationController.getWaitingPlanifications);
router.post("/add", planificationController.addPlanification);
router.get("/", planificationController.getAllPlanifications);
router.put("/update/:id", planificationController.updatePlanification);
router.delete("/delete/:id", planificationController.deletePlanification);
router.post('/auto', planificationController.autoPlanifierCommande);
router.post('/mettre-a-jour-commandes', planificationController.mettreAJourCommandesEnCours);
router.post('/mettre-a-jour-machines', planificationController.mettreAJourMachinesDisponibles);
router.post('/confirm', planificationController.confirmPlanification);

router.get("/:id", planificationController.getPlanificationById);


module.exports = router;
