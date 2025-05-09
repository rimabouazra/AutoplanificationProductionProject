const mongoose = require("mongoose");


const PlanificationSchema = new mongoose.Schema({
  commandes: [{ type: mongoose.Schema.Types.ObjectId, ref: "Commande" }],
  machines: [{ type: mongoose.Schema.Types.ObjectId, ref: "Machine" }],
  salle: { type: mongoose.Schema.Types.ObjectId, ref: "Salle" },
  debutPrevue: { type: Date },
  finPrevue: { type: Date },
  statut: { type: String, default: "en attente", enum: ["en attente", "waiting_resources", "en cours", "terminée"] },
  taille: { type: String },
  couleur: { type: String },
  quantite: { type: Number },
  createdAt: { type: Date, default: Date.now },
  order: { type: Number, default: 0 } // For ordering waiting planifications
});

module.exports = mongoose.model("Planification", PlanificationSchema);