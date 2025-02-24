const mongoose = require("mongoose");

const CommandeModeleSchema = new mongoose.Schema({
  modele: { type: mongoose.Schema.Types.ObjectId, ref: "Modele", required: true }, //  Référence au modèle
  taille: { type: String, required: true },
  couleur: { type: String, required: true },
  quantite: { type: Number, required: true }
});

const CommandeSchema = new mongoose.Schema(
  {
    client: { type: String, required: true },
    etat: {
      type: String,
      enum: ["en attente", "en coupe", "en moulage", "en presse", "en contrôle", "emballage", "terminé"],
      default: "en attente"
    },
    modeles: { type: [CommandeModeleSchema], required: true },
    conditionnement: { type: String, required: true },
    delais: { type: Date, required: true },
    salleAffectee: { type: mongoose.Schema.Types.ObjectId, ref: "Salle" },
    machinesAffectees: [{ type: mongoose.Schema.Types.ObjectId, ref: "Machine" }]
  },
  { timestamps: true }
);

module.exports = mongoose.model("Commande", CommandeSchema);
