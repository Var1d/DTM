require('dotenv').config();
const express = require('express');
const cors    = require('cors');

const authRoutes     = require('./routes/authRoutes');
const taskRoutes     = require('./routes/taskRoutes');
const courseRoutes   = require('./routes/courseRoutes');
const userRoutes     = require('./routes/userRoutes');
const errorMiddleware = require('./middlewares/errorMiddleware');

const app  = express();
const PORT = process.env.PORT || 3000;

// Middleware global
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth',       authRoutes);
app.use('/api/tasks',      taskRoutes);
app.use('/api/courses',    courseRoutes);
app.use('/api/user',       userRoutes);

// Health check
app.get('/', (req, res) => {
  res.json({ message: 'Academic Task Manager API is running!' });
});

// Error handler (harus paling bawah)
app.use(errorMiddleware);

app.listen(PORT, () => {
  console.log(`Server berjalan di http://localhost:${PORT}`);
});
