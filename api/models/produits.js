const mongoose = require("mongoose");

const ProduitsSchema = new mongoose.Schema({
    modele: { type: mongoose.Schema.Types.ObjectId, ref: "Modele", required: true },
    tailles: [
        {
            taille: { type: String, required: true },
            couleur: { type: String, required: true },
            etat: { type: String, enum: ['coupé', 'moulé'], required: true },
            matiere: { type: mongoose.Schema.Types.ObjectId, ref: "Matiere", required: false },
            quantite: { type: Number, required: true, min: 0 }
        }
    ]
});

const Produits = mongoose.models.Produits || mongoose.model("Produits", ProduitsSchema);
module.exports = Produits;
