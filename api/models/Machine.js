const mongoose = require("mongoose");

const MachineSchema = new mongoose.Schema({
    nom: { type: String, required: true },
    etat: { type: String, enum: ["Disponible", "Occupée", "En maintenance"], default: "Disponible" },
    salle: { type: mongoose.Schema.Types.ObjectId, ref: "Salle" },
    modelesCompatibles: [{ type: String }]
});

module.exports = mongoose.model("Machine", MachineSchema);
