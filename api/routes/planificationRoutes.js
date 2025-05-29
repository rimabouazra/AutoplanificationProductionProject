const express = require("express");
const router = express.Router();
const planificationController = require("../controllers/PlanificationController");
const authMiddleware = require('../middlewares/auth');
const { authenticateToken, authorizeRoles } = require('../middlewares/auth');

const restrictToAdminOrManager = (req, res, next) => {
  if (req.user && ['admin', 'manager'].includes(req.user.role)) {
    next();
  } else {
    res.status(403).json({ message: 'Accès interdit : rôle admin ou manager requis' });
  }
};

router.get("/get/waiting", planificationController.getWaitingPlanifications);
router.post("/add", planificationController.addPlanification);
router.get("/", planificationController.getAllPlanifications);
router.put("/update/:id", planificationController.updatePlanification);
router.delete("/delete/:id", planificationController.deletePlanification);
router.post('/auto', planificationController.autoPlanifierCommande);
router.post('/mettre-a-jour-commandes', planificationController.mettreAJourCommandesEnCours);
router.post('/mettre-a-jour-machines', planificationController.mettreAJourMachinesDisponibles);
router.post('/confirm', planificationController.confirmPlanification);

router.get("/:id", planificationController.getPlanificationById);
router.get('/active/:machineId', planificationController.checkActivePlanification);
router.put("/waiting/order", planificationController.reorderWaitingPlanifications);
router.post('/terminate/:id', authenticateToken, authorizeRoles('admin', 'manager'), planificationController.terminerPlanification);module.exports = router;
router.put('/work-hours', authenticateToken, restrictToAdminOrManager, planificationController.updateWorkHours);