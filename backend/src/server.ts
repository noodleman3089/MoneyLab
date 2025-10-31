import express from 'express';
import  recommendationRoutes  from './routes/recommendation.routes';

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Routes
app.use('/api/recommendations', recommendationRoutes);

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});