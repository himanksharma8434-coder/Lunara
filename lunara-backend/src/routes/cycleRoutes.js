const express = require('express');
const router = express.Router();
const cycleController = require('../controllers/cycleController');
const auth = require('../middleware/authMiddleware'); // Protect these routes

router.post('/start', auth, cycleController.logPeriodStart);

module.exports = router;