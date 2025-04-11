const Client = require('../models/Client');

exports.addClient = async (req, res) => {
  try {
    const { name } = req.body;

    const existingClient = await Client.findOne({ name: name.trim() });
    if (existingClient) {
      return res.status(200).json(existingClient);
    }

    const newClient = new Client({ name: name.trim() });
    await newClient.save();
    res.status(201).json(newClient);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getClients = async (req, res) => {
  try {
    const clients = await Client.find().sort({ name: 1 });
    res.json(clients);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
