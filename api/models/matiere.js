const mongoose = require("mongoose");

const historiqueSchema = new mongoose.Schema({
    action: { type: String, required: true }, // "ajout" ou "consommation"
    quantite: { type: Number, required: true },
    date: { type: Date, default: Date.now }
  });

const matiereSchema = new mongoose.Schema({
  reference: { type: String, required: true, unique: true },
  couleur: { type: String, required: true },
  quantite: { type: Number, required: true, min: 0 },
  dateAjout: { type: Date, default: Date.now }, 
  historique: [historiqueSchema] 
});

const Matiere = mongoose.model("Matiere", matiereSchema);

module.exports = Matiere;
