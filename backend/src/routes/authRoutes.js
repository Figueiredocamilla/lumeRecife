import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { registrar, login, me, logout } from '../controllers/authController.js';
import { exigirAutenticacao } from '../middlewares/authMiddleware.js';

const router = Router();
const limiter = rateLimit({ windowMs: 15 * 60 * 1000, limit: 10, standardHeaders: 'draft-7', legacyHeaders: false,
  message: { erro: 'Muitas tentativas. Tente novamente mais tarde.' } });

router.post('/register', limiter, registrar);
router.post('/login', limiter, login);
router.get('/me', exigirAutenticacao, me);
router.post('/logout', exigirAutenticacao, logout);
export default router;
