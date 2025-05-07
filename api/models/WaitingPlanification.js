const mongoose = require('mongoose');

const waitingPlanificationSchema = new mongoose.Schema({
  commande: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Commande',
    required: true
  },
  modele: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Modele',
    required: true
  },
  taille: {
    type: String,
    required: true
  },
  couleur: {
    type: String,
    required: true
  },
  quantite: {
    type: Number,
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('WaitingPlanification', waitingPlanificationSchema);