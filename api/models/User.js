const mongoose = require("mongoose");

const UserSchema = new mongoose.Schema({
    nom: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    motDePasse: { type: String, required: true },
    role: { 
        type: String, 
        enum: ["admin", "manager", "responsable_modele", "responsable_matiere", "ouvrier"],
        default: null
    },
    status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
}, { timestamps: true });

module.exports = mongoose.model("User", UserSchema);
