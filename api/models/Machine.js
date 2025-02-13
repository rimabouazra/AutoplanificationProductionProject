const mongoose = require("mongoose");

const MachineSchema = new mongoose.Schema({
    nom: { type: String, required: true },
    etat: { type: String, enum: ["disponible", "occupee", "arretee"], default: "disponible" },
    salle: { type: mongoose.Schema.Types.ObjectId, ref: "Salle", required: true },
    modele: { type: mongoose.Schema.Types.ObjectId, ref: "Modele", required: true }, // Un seul modèle
    taille: { type: String, required: true } // Une seule taille
});

module.exports = mongoose.model("Machine", MachineSchema);
