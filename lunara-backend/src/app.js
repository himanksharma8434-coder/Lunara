const express = require('express');
const cors = require('cors');
const sequelize = require('./config/database');
const models = require('./models');
const authRoutes = require('./routes/authRoutes');
const cycleRoutes = require('./routes/cycleRoutes');
const assessmentRoutes = require('./routes/assessmentRoutes');


const app = express();

app.use(cors());
app.use(express.json());
app.use('/api/auth', authRoutes);
app.use('/api/cycles', cycleRoutes);
app.use('/api/assessments', assessmentRoutes);
app.use('/api/insights', require('./routes/insightRoutes'));

// Test Route
app.get('/health', (req, res) => res.send('Backend is running!'));

// Sync Database and Start Server
const PORT = process.env.PORT || 3000;

sequelize.sync({ alter: true }) // 'alter' updates tables if you change the models
  .then(() => {
    console.log('✅ Database synchronized perfectly.');
    app.listen(PORT, () => console.log(`🚀 Server ready at http://localhost:${PORT}`));
  })
  .catch(err => console.error('❌ Database sync failed:', err));