const mongoose = require("mongoose");

const PlanificationSchema = new mongoose.Schema({
  commandes: [{ type: mongoose.Schema.Types.ObjectId, ref: "Commande" }],
  machines: [{ type: mongoose.Schema.Types.ObjectId, ref: "Machine" }],
  salle: { type: mongoose.Schema.Types.ObjectId, ref: "Salle" }, // ✅ champ ajouté
  debutPrevue: { type: Date },
  finPrevue: { type: Date },
  statut: { type: String, default: "en attente" }
});

module.exports = mongoose.model("Planification", PlanificationSchema);
