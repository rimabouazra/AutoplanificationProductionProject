const express = require("express");
const router = express.Router();
const planificationController = require("../controllers/PlanificationController");

router.post("/add", planificationController.addPlanification);
router.get("/", planificationController.getAllPlanifications);
router.get("/:id", planificationController.getPlanificationById);
router.put("/update/:id", planificationController.updatePlanification);
router.delete("/delete/:id", planificationController.deletePlanification);

module.exports = router;
