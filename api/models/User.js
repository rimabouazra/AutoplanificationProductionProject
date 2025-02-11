const mongoose = require("mongoose");

const UserSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    nom: { type: String, required: true },
    prenom: { type: String, required: true },
    role: { type: String, enum: ["Admin", "ResponsableMatière", "ResponsableModèle", "Ouvrier"], default: "Ouvrier" }
}, { timestamps: true });

module.exports = mongoose.model("User", UserSchema);
