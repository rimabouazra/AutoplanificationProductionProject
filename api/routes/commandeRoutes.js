const express = require("express");
const router = express.Router();
const CommandeController = require("../controllers/commandeController");

router.post("/add", CommandeController.ajouterCommande);
router.get("/", CommandeController.getCommandes);
router.get("/:id", CommandeController.getCommandeById);
router.get("/parSalle/:salleId", CommandeController.getCommandesBySalle);
router.put("/:id", CommandeController.updateCommande);
router.delete("/:id", CommandeController.deleteCommande);
router.put('/:id/etat', CommandeController.updateCommandeEtat);
router.patch('/:commandeId/modele/:modeleId', CommandeController.updateQuantiteReelle);


module.exports = router;
