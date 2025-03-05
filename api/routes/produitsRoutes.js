const express = require("express");
const router = express.Router();
const produitsController = require("../controllers/produitsController");

router.post("/add", produitsController.addProduit);
router.get("/:id", produitsController.getProduitById);
router.get("/", produitsController.getAllProduits);
router.put("/update/:id", produitsController.updateProduit);
router.delete("/delete/:id", produitsController.deleteProduit);

module.exports = router;