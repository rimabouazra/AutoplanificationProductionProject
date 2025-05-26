const express = require("express");
const router = express.Router();
const produitsController = require("../controllers/ProduitsController");

router.post("/add", produitsController.addProduit);
router.get("/:id", produitsController.getProduitById);
router.get("/", produitsController.getAllProduits);
router.put("/update/:id", produitsController.updateProduit);
router.delete("/delete/:id", produitsController.deleteProduit);
router.post("/:id/addTaille", produitsController.addTailleToProduit);
router.delete("/:id/deleteTaille/:tailleIndex", produitsController.deleteTailleFromProduit);

module.exports = router;