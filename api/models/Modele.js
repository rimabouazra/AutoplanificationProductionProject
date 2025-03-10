const mongoose = require("mongoose");

const ModeleSchema = new mongoose.Schema({
    nom: { type: String, required: true, unique: true },
    matiere: { type: mongoose.Schema.Types.ObjectId, ref: "Matiere", required: false },
    tailles: [{ type: String, required: true }],
    bases: [{ type: mongoose.Schema.Types.ObjectId, ref: "Modele" }],
    taillesBases: [{
        baseId: { type: mongoose.Schema.Types.ObjectId, ref: "Modele" },
        tailles: [{ type: String }]
    }]
});

const Modele = mongoose.models.Modele || mongoose.model("Modele", ModeleSchema);
module.exports = Modele;
