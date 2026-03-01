const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Assessment = sequelize.define('Assessment', {
  userId: { type: DataTypes.UUID, allowNull: false },
  date: { type: DataTypes.DATEONLY, defaultValue: DataTypes.NOW },
  mood: { type: DataTypes.STRING }, // Happy, Moody, Tired, etc.
  symptoms: { type: DataTypes.JSONB }, // Stores as { "cramps": "mild", "acne": true }
  waterIntake: { type: DataTypes.INTEGER, defaultValue: 0 },
  sleepHours: { type: DataTypes.FLOAT, defaultValue: 0 },
  steps: { type: DataTypes.INTEGER, defaultValue: 0 }
});

module.exports = Assessment;