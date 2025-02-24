const mongoose = require("mongoose");

const matiereSchema = new mongoose.Schema({
  reference: { type: String, required: true, unique: true },
  couleur: { type: String, required: true },
  quantite: { type: Number, required: true, min: 0 },
});

const Matiere = mongoose.model("Matiere", matiereSchema);

module.exports = Matiere;
