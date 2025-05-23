const mongoose = require("mongoose");

const SalleSchema = new mongoose.Schema({
    nom: { type: String, required: true },
    type: { type: String, required: true, enum: ["noir", "blanc"] },
    machines: [{ type: mongoose.Schema.Types.ObjectId, ref: "Machine" }]
});

module.exports = mongoose.model("Salle", SalleSchema);
