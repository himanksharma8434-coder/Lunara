const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Cycle = sequelize.define('Cycle', {
  userId: { type: DataTypes.UUID, allowNull: false },
  startDate: { type: DataTypes.DATEONLY, allowNull: false },
  endDate: { type: DataTypes.DATEONLY },
  isPredicted: { type: DataTypes.BOOLEAN, defaultValue: false }, // Crucial for AI training
  status: { type: DataTypes.ENUM('active', 'completed'), defaultValue: 'active' }
});

module.exports = Cycle;