const User = require('./User');
const Cycle = require('./Cycle');
const Assessment = require('./Assessment');
const Insight = require('./Insight');

// Define Relationships (Associations)
User.hasMany(Cycle, { foreignKey: 'userId', as: 'cycles' });
Cycle.belongsTo(User, { foreignKey: 'userId' });

User.hasMany(Insight, { foreignKey: 'userId', as: 'insights' });
Insight.belongsTo(User, { foreignKey: 'userId' });

User.hasMany(Assessment, { foreignKey: 'userId', as: 'assessments' });
Assessment.belongsTo(User, { foreignKey: 'userId' });

module.exports = { User, Cycle, Assessment, Insight };