const { Cycle, User } = require('../models');
const cycleService = require('../services/cycleService');

exports.logPeriodStart = async (req, res) => {
  try {
    const { startDate } = req.body;
    const userId = req.userData.userId;

    // 1. Create the new cycle
    const newCycle = await Cycle.create({ userId, startDate, status: 'active' });

    // 2. "Learn": Trigger a background update of the user's averages
    const metrics = await cycleService.calculateCycleMetrics(userId);
    await User.update(
      { cycleLength: metrics.avgLength, periodDuration: metrics.avgDuration },
      { where: { id: userId } }
    );

    res.status(201).json({ message: 'Period logged. Metrics updated!', cycle: newCycle });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};