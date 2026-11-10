import express from 'express';
import cookieParser from 'cookie-parser';
import authRoutes from './routes/authRoutes.js';
import { verificarOrigem } from './middlewares/authMiddleware.js';

const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '32kb' }));
app.use(cookieParser());
app.use(verificarOrigem);
app.get('/api/health', (_req, res) => res.json({ status: 'ok' }));
app.use('/api/auth', authRoutes);
app.use((_req, res) => res.status(404).json({ erro: 'Rota não encontrada.' }));
app.use((err, _req, res, _next) => {
  console.error('Erro interno:', err);
  res.status(500).json({ erro: 'Erro interno do servidor.' });
});
export default app;
