import 'dotenv/config';
import app from './app.js';
import { pool, testarConexao } from './config/database.js';

const port = Number(process.env.PORT || 3000);
try {
  await testarConexao();
  const server = app.listen(port, '127.0.0.1', () => {
    console.log(`Lume Recife API em http://127.0.0.1:${port}`);
  });
  const encerrar = () => server.close(async () => { await pool.end(); process.exit(0); });
  process.on('SIGINT', encerrar);
  process.on('SIGTERM', encerrar);
} catch (error) {
  console.error('Falha ao iniciar API ou conectar MySQL:', error.message);
  process.exit(1);
}
