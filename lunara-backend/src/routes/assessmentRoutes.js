const express = require('express');
const router = express.Router();
const assessmentController = require('../controllers/assessmentController');
const auth = require('../middleware/authMiddleware');

router.post('/', auth, assessmentController.logDailyAssessment);
router.get('/history', auth, assessmentController.getAssessmentHistory);

module.exports = router;