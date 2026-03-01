const { Insight } = require('../models');
const insightService = require('../services/insightService');

exports.getMyInsights = async (req, res) => {
  try {
    const userId = req.userData.userId;
    
    // Optional: Trigger a refresh of insights
    await insightService.generateUserInsights(userId);

    const insights = await Insight.findAll({
      where: { userId },
      order: [['createdAt', 'DESC']]
    });

    res.status(200).json(insights);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};