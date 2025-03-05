const express = require("express");
const router = express.Router();
const matiereController = require("../controllers/matiereController");

router.post("/add", matiereController.addMatiere);
router.get("/", matiereController.getMatieres);
router.get("/:id/historique", matiereController.getHistoriqueMatiere);
router.put('/update/:id', matiereController.updateMatiere);
router.patch("/:id/rename", matiereController.renameMatiere);
router.delete("/:id", matiereController.deleteMatiere);

module.exports = router;
