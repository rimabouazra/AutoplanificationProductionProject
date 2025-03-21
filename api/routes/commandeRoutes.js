const express = require("express");
const router = express.Router();
const CommandeController = require("../controllers/commandeController");

router.post("/add", CommandeController.ajouterCommande);

router.get("/", CommandeController.getCommandes);

// Route pour récupérer une commande par ID
router.get("/:id", CommandeController.getCommandeById);

// Route pour récupérer les commandes d'une salle spécifique
router.get("/parSalle/:salleId", CommandeController.getCommandesBySalle);

// Route pour modifier une commande
router.put("/:id", CommandeController.updateCommande);

router.delete("/:id", CommandeController.deleteCommande);

module.exports = router;
