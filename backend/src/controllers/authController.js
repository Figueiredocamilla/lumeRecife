import crypto from 'node:crypto';
import argon2 from 'argon2';
import { pool } from '../config/database.js';
import { COOKIE_NAME, SESSION_MS, cookieOptions, hashToken } from '../middlewares/authMiddleware.js';

const emailValido = (v) => typeof v === 'string' && v.length <= 180 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
const respostaUsuario = (u) => ({ id: String(u.id_usuario), nome: u.nome, email: u.email });

export async function registrar(req, res, next) {
  const { nome, email, senha } = req.body || {};
  if (typeof nome !== 'string' || !nome.trim() || nome.trim().length > 120 ||
      !emailValido(email) || typeof senha !== 'string' || senha.length < 12 || senha.length > 128) {
    return res.status(400).json({ erro: 'Informe nome, e-mail válido e senha de 12 a 128 caracteres.' });
  }
  let conn;
  try {
    // Evita corrida entre dois cadastros simultâneos do primeiro gestor.
    conn = await pool.getConnection();
    await conn.beginTransaction();
    const [lock] = await conn.query("SELECT GET_LOCK('lume_primeiro_gestor', 5) AS adquirido");
    if (lock[0].adquirido !== 1) {
      await conn.rollback();
      return res.status(503).json({ erro: 'Cadastro temporariamente indisponível.' });
    }
    try {
      const [existentes] = await conn.query('SELECT id_usuario FROM usuarios LIMIT 1');
      if (existentes.length) {
        await conn.rollback();
        return res.status(403).json({ erro: 'Cadastro inicial encerrado.' });
      }
      const hash = await argon2.hash(senha, { type: argon2.argon2id });
      const [result] = await conn.execute(
        'INSERT INTO usuarios (nome, email, senha_hash) VALUES (?, ?, ?)',
        [nome.trim(), email.trim().toLowerCase(), hash]
      );
      await conn.commit();
      return res.status(201).json({ mensagem: 'Gestor cadastrado.', usuario: { id: String(result.insertId), nome: nome.trim(), email: email.trim().toLowerCase() } });
    } finally {
      await conn.query("SELECT RELEASE_LOCK('lume_primeiro_gestor')");
    }
  } catch (error) {
    if (conn) await conn.rollback().catch(() => {});
    if (error.code === 'ER_DUP_ENTRY') return res.status(409).json({ erro: 'E-mail já cadastrado.' });
    next(error);
  } finally { if (conn) conn.release(); }
}

export async function login(req, res, next) {
  const { email, senha } = req.body || {};
  if (!emailValido(email) || typeof senha !== 'string') {
    return res.status(400).json({ erro: 'Informe e-mail e senha válidos.' });
  }
  try {
    const [rows] = await pool.execute(
      'SELECT id_usuario, nome, email, senha_hash FROM usuarios WHERE email = ? AND ativo = 1 LIMIT 1',
      [email.trim().toLowerCase()]
    );
    const usuario = rows[0];
    if (!usuario || !(await argon2.verify(usuario.senha_hash, senha))) {
      return res.status(401).json({ erro: 'Credenciais inválidas.' });
    }
    const token = crypto.randomBytes(32).toString('hex');
    const expiraEm = new Date(Date.now() + SESSION_MS);
    const dataMysql = expiraEm.toISOString().slice(0, 19).replace('T', ' ');
    await pool.execute(
      'INSERT INTO sessoes (id_usuario, token_hash, expira_em) VALUES (?, ?, ?)',
      [usuario.id_usuario, hashToken(token), dataMysql]
    );
    res.cookie(COOKIE_NAME, token, cookieOptions);
    return res.json({ mensagem: 'Login realizado.', usuario: respostaUsuario(usuario) });
  } catch (error) { next(error); }
}

export function me(req, res) {
  res.json({ usuario: respostaUsuario(req.gestor) });
}

export async function logout(req, res, next) {
  try {
    await pool.execute('UPDATE sessoes SET revogada_em = UTC_TIMESTAMP() WHERE id_sessao = ?', [req.gestor.id_sessao]);
    res.clearCookie(COOKIE_NAME, { path: '/', sameSite: 'strict', secure: process.env.NODE_ENV === 'production', httpOnly: true });
    res.json({ mensagem: 'Sessão encerrada.' });
  } catch (error) { next(error); }
}
