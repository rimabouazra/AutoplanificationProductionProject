const mongoose = require("mongoose");

const ModeleSchema = new mongoose.Schema({
    nom: { type: String, required: true, unique: true },
    matiere: { type: mongoose.Schema.Types.ObjectId, ref: "Matiere", required: false },
    tailles: [{ type: String, required: true }],
    bases: [{ type: mongoose.Schema.Types.ObjectId, ref: "Modele" }], // Liste des modèles de base
    taillesBases: [{
        baseId: { type: mongoose.Schema.Types.ObjectId, ref: "Modele",required: false }, // Référence à la base
        tailles: [{ type: String }] // Correspondance des tailles
    }],
    consommation: [{
        taille: { type: String, required: true },
        quantite: { 
            type: Number, 
            required: true, 
            default: 0,
            validate: {
                validator: function(v) {
                    return /^(\d+(\.\d{1,4})?)$/.test(v.toFixed(4));
                },
                message: props => `${props.value} doit avoir au maximum 4 chiffres après la virgule !`
            }
        } 
    }]
});

const Modele = mongoose.models.Modele || mongoose.model("Modele", ModeleSchema);
module.exports = Modele;
