const { Assessment, Cycle, Insight } = require('../models');
const { Op } = require('sequelize');

exports.generateUserInsights = async (userId) => {
  // 1. Get the last 3 cycles to find the "Pattern Window"
  const cycles = await Cycle.findAll({
    where: { userId, status: 'completed' },
    limit: 3,
    order: [['startDate', 'DESC']]
  });

  if (cycles.length < 2) return; // Need at least 2 months of data to "learn"

  // 2. Logic: Look for "Cramps" or "Mood Swings" in the 3 days before each cycle started
  const symptomsToTrack = ['cramps', 'headache', 'low_energy'];
  
  for (const symptom of symptomsToTrack) {
    let occurrences = 0;

    for (const cycle of cycles) {
      const periodStart = new Date(cycle.startDate);
      const windowStart = new Date(periodStart);
      windowStart.setDate(periodStart.getDate() - 3); // 3 days before

      const found = await Assessment.findOne({
        where: {
          userId,
          date: { [Op.between]: [windowStart, periodStart] },
          symptoms: { [Op.contains]: { [symptom]: true } }
        }
      });

      if (found) occurrences++;
    }

    // 3. If the symptom happened in 100% of tracked cycles, create an Insight
    if (occurrences >= cycles.length) {
      await Insight.findOrCreate({
        where: { userId, title: `Pattern: ${symptom}` },
        defaults: {
          message: `We've noticed you consistently experience ${symptom.replace('_', ' ')} a few days before your period starts. Staying hydrated might help!`,
          type: 'wellness'
        }
      });
    }
  }
};