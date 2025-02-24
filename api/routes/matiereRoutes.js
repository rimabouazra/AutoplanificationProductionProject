const express = require("express");
const router = express.Router();
const matiereController = require("../controllers/matiereController");

// Route pour ajouter une matière
router.post("/add", matiereController.addMatiere);

// Route pour récupérer toutes les matières
router.get("/", matiereController.getMatieres);

router.put('/update/:id', matiereController.updateMatiere);

// Route pour supprimer une matière
router.delete("/:id", matiereController.deleteMatiere);

module.exports = router;
