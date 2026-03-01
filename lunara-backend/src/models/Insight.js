const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Insight = sequelize.define('Insight', {
  userId: { type: DataTypes.UUID, allowNull: false },
  title: { type: DataTypes.STRING, allowNull: false }, // e.g., "Pattern Detected"
  message: { type: DataTypes.TEXT, allowNull: false }, // e.g., "You often feel tired 2 days before your period."
  type: { type: DataTypes.ENUM('prediction', 'wellness', 'alert'), defaultValue: 'wellness' },
  isRead: { type: DataTypes.BOOLEAN, defaultValue: false }
});

module.exports = Insight;