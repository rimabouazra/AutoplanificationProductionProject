const mongoose = require("mongoose");

const ModeleSchema = new mongoose.Schema({
    nom: { type: String, required: true, unique: true },
    tailles: [{ type: String, required: true }],
    derives: [{ type: mongoose.Schema.Types.ObjectId, ref: "Modele" }] // Référence aux dérivés futurs
});

module.exports = mongoose.model("Modele", ModeleSchema);
