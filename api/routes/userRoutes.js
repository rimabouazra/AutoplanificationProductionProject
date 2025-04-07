const express = require("express");
const router = express.Router();
const userController = require("../controllers/userController");

router.post("/add", userController.ajouterUtilisateur);
router.post("/login", userController.login);
router.get("/", userController.getUtilisateurs);
router.get("/:id", userController.getUtilisateurById);
router.put("/:id", userController.updateUtilisateur);
router.delete("/:id", userController.deleteUtilisateur);

module.exports = router;
