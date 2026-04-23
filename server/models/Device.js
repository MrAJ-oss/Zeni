const mongoose = require("mongoose");

const DeviceSchema = new mongoose.Schema({
  deviceId: String,
  name: String,

  approved: {
    type: Boolean,
    default: false
  },

  owner: {
    type: String,
    default: "zeni_owner"
  },

  lastSeen: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model("Device", DeviceSchema);