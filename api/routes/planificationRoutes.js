const express = require("express");
const router = express.Router();
const planificationController = require("../controllers/PlanificationController");

router.post("/add", planificationController.addPlanification);
router.get("/", planificationController.getAllPlanifications);
router.get("/:id", planificationController.getPlanificationById);
router.put("/update/:id", planificationController.updatePlanification);
router.delete("/delete/:id", planificationController.deletePlanification);
router.post('/auto', planificationController.autoPlanifierCommande);
router.post('/maj-machines', planificationController.mettreAJourMachinesDisponibles);
router.post('/mettre-a-jour-commandes', planificationController.mettreAJourCommandesEnCours);
router.post('/mettre-a-jour-machines', planificationController.mettreAJourMachinesDisponibles);
router.post('/confirm', planificationController.mettreAJourMachinesDisponibles);


module.exports = router;
