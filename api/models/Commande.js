const mongoose = require("mongoose");

const CommandeSchema = new mongoose.Schema({
    client: { type: String, required: true },
    quantite: { type: Number, required: true },
    couleur: { type: String, required: true },
    taille: { type: String, required: true },
    conditionnement: { type: String, required: true },
    delais: { type: Date, required: true },
    etat: { type: String, enum: ["En attente", "En cours", "Terminée"], default: "En attente" },
    salleAffectee: { type: mongoose.Schema.Types.ObjectId, ref: "Salle" },
    machineAffectee: { type: mongoose.Schema.Types.ObjectId, ref: "Machine" }
}, { timestamps: true });

module.exports = mongoose.model("Commande", CommandeSchema);
