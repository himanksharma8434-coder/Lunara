const { Cycle } = require('../models');

exports.calculateCycleMetrics = async (userId) => {
  // 1. Get the last 6 completed cycles
  const history = await Cycle.findAll({
    where: { userId, isPredicted: false, status: 'completed' },
    limit: 6,
    order: [['startDate', 'DESC']]
  });

  if (history.length === 0) return { avgLength: 28, avgDuration: 5 };

  // 2. Calculate average cycle length (days between start dates)
  // 3. Calculate average period duration (days between start and end)
  let totalLength = 0;
  let totalDuration = 0;

  for (let i = 0; i < history.length; i++) {
    // Logic for duration
    const start = new Date(history[i].startDate);
    const end = new Date(history[i].endDate);
    totalDuration += (end - start) / (1000 * 60 * 60 * 24);

    // Logic for cycle length (between this start and the next)
    if (i < history.length - 1) {
      const nextStart = new Date(history[i + 1].startDate);
      totalLength += (start - nextStart) / (1000 * 60 * 60 * 24);
    }
  }

  return {
    avgLength: history.length > 1 ? Math.round(totalLength / (history.length - 1)) : 28,
    avgDuration: Math.round(totalDuration / history.length)
  };
};