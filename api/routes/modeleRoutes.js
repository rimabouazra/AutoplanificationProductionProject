const express = require("express");
const router = express.Router();
const modelController = require("../controllers/modelController");

router.post("/add", modelController.addModele);
router.get("/:id", modelController.getModeleById);
router.get("/findByName/:nomModele", modelController.getModeleByName);
router.get("/", modelController.getAllModeles);
router.put("/update/:id", modelController.updateModele);
router.delete("/delete/:id", modelController.deleteModele);

module.exports = router;
