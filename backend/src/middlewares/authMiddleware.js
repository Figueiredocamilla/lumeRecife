import crypto from 'node:crypto';
import { pool } from '../config/database.js';

export const COOKIE_NAME = 'lume_session';
export const SESSION_MS = 8 * 60 * 60 * 1000;
export const cookieOptions = {
  httpOnly: true,
  sameSite: 'strict',
  secure: process.env.NODE_ENV === 'production',
  path: '/',
  maxAge: SESSION_MS
};
export const hashToken = (token) => crypto.createHash('sha256').update(token).digest('hex');

export async function exigirAutenticacao(req, res, next) {
  try {
    const token = req.cookies?.[COOKIE_NAME];
    if (!token || !/^[a-f0-9]{64}$/.test(token)) {
      return res.status(401).json({ erro: 'Autenticação necessária.' });
    }
    const [rows] = await pool.execute(
      `SELECT s.id_sessao, u.id_usuario, u.nome, u.email
       FROM sessoes s JOIN usuarios u ON u.id_usuario = s.id_usuario
       WHERE s.token_hash = ? AND s.revogada_em IS NULL
         AND s.expira_em > UTC_TIMESTAMP() AND u.ativo = 1 LIMIT 1`,
      [hashToken(token)]
    );
    if (!rows.length) return res.status(401).json({ erro: 'Sessão inválida ou expirada.' });
    req.gestor = rows[0];
    next();
  } catch (error) { next(error); }
}

// Para chamadas autenticadas por cookie: bloquear requisições de alteração
// com origem externa. O front-end deve usar a mesma origem da API ou proxy.
export function verificarOrigem(req, res, next) {
  if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) return next();
  const origin = req.get('origin');
  const allowed = process.env.FRONTEND_ORIGIN;
  if (origin && allowed && origin !== allowed) {
    return res.status(403).json({ erro: 'Origem não autorizada.' });
  }
  next();
}
