# Lume Recife — Sistema Inteligente de Iluminação Pública	

Projeto acadêmico desenvolvido para a disciplina de Desenvolvimento de Aplicações para Internet — UNINASSAU, semestre 2026.2.

## Objetivo

Desenvolver um sistema de monitoramento inteligente de iluminação pública, utilizando postes e sensores simulados, permitindo o acompanhamento de informações elétricas, a identificação de anomalias e o gerenciamento de manutenção.

## Tecnologias utilizadas

- Node.js 24
- Express.js
- MySQL 8.4
- JavaScript
- Argon2id para proteção de senhas
- API REST

## Checkpoint 2 — Back-end e banco de dados

Nesta etapa foram implementados e testados:

- Servidor HTTP utilizando Express.
- Conexão com banco de dados MySQL.
- Estrutura inicial com oito tabelas.
- Cadastro do primeiro gestor.
- Login e autenticação por sessão.
- Consulta do gestor autenticado.
- Logout e invalidação da sessão.

### Endpoints implementados

| Método | Endpoint | Descrição |
|---|---|---|
| GET | `/api/health` | Verifica o funcionamento da API |
| POST | `/api/auth/register` | Cadastra o gestor inicial |
| POST | `/api/auth/login` | Autentica o gestor |
| GET | `/api/auth/me` | Consulta o gestor autenticado |
| POST | `/api/auth/logout` | Encerra a sessão |

### Banco de dados

O banco `lume_recife` possui oito tabelas: `usuarios`, `sessoes`, `postes`, `sensores`, `leituras`, `regras_monitoramento`, `alertas` e `ordens_manutencao`.

O script de criação está em `database/schema.sql`.

## Como executar

É necessário possuir Node.js 20 ou superior e MySQL 8 instalado.

1. Criar o banco de dados utilizando o script `database/schema.sql`.
2. Entrar na pasta `backend`.
3. Copiar `.env.example` para `.env` e configurar as credenciais do MySQL.
4. Executar `npm install`.
5. Executar `npm run dev`.

A API estará disponível em `http://localhost:3000`, utilizando a configuração padrão.

## Próximas etapas

Implementar os endpoints de postes, recebimento de telemetria, regras de monitoramento, alertas e integração com o front-end.

**Status:** módulo inicial de autenticação e conexão com o banco testados localmente. Os módulos de monitoramento ainda estão em desenvolvimento.
