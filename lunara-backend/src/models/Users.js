const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const User = sequelize.define('User', {
  id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey : true },
  name: { type: DataTypes.STRING, allowNull: false },
  email: { type: DataTypes.STRING, unique: true, allowNull: false, validate: { isEmail: true } },
  passwordHash: { type: DataTypes.STRING, allowNull: false },
  isOnboarded: { type: DataTypes.BOOLEAN, defaultValue: false },
  cycleLength: { type: DataTypes.INTEGER, defaultValue: 28 }, // Learns over time
  periodDuration: { type: DataTypes.INTEGER, defaultValue: 5 }
});

module.exports = User;