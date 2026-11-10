-- Lume Recife - MySQL 8.0.16+ | Modelo v1.0
-- Executar em uma instancia local de desenvolvimento.
CREATE DATABASE IF NOT EXISTS lume_recife CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE lume_recife;

CREATE TABLE IF NOT EXISTS usuarios (
 id_usuario BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 nome VARCHAR(120) NOT NULL,
 email VARCHAR(180) NOT NULL,
 senha_hash VARCHAR(255) NOT NULL,
 ativo BOOLEAN NOT NULL DEFAULT TRUE,
 criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT uq_usuarios_email UNIQUE (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sessoes (
 id_sessao BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 id_usuario BIGINT UNSIGNED NOT NULL,
 token_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 expira_em DATETIME NOT NULL,
 revogada_em DATETIME NULL,
 criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT uq_sessoes_token UNIQUE (token_hash),
 CONSTRAINT fk_sessoes_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
 INDEX idx_sessoes_usuario_expira (id_usuario, expira_em)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS postes (
 id_poste BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 codigo VARCHAR(20) NOT NULL,
 endereco VARCHAR(255) NOT NULL,
 latitude DECIMAL(10,7) NULL,
 longitude DECIMAL(10,7) NULL,
 status ENUM('operacional','alerta','offline') NOT NULL DEFAULT 'operacional',
 criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT uq_postes_codigo UNIQUE (codigo),
 CONSTRAINT chk_postes_lat CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
 CONSTRAINT chk_postes_lon CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sensores (
 id_sensor BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 id_poste BIGINT UNSIGNED NOT NULL,
 tipo VARCHAR(50) NOT NULL,
 ativo BOOLEAN NOT NULL DEFAULT TRUE,
 criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_sensores_poste FOREIGN KEY (id_poste) REFERENCES postes(id_poste) ON DELETE RESTRICT,
 CONSTRAINT uq_sensores_poste_tipo UNIQUE (id_poste, tipo)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS leituras (
 id_leitura BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 id_poste BIGINT UNSIGNED NOT NULL,
 tensao DECIMAL(8,2) NOT NULL,
 corrente DECIMAL(10,3) NOT NULL,
 potencia DECIMAL(10,2) NOT NULL,
 brilho_percentual TINYINT UNSIGNED NOT NULL,
 movimento_detectado BOOLEAN NOT NULL,
 medido_em DATETIME(3) NOT NULL,
 recebido_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 CONSTRAINT fk_leituras_poste FOREIGN KEY (id_poste) REFERENCES postes(id_poste) ON DELETE RESTRICT,
 CONSTRAINT chk_leituras_tensao CHECK (tensao >= 0),
 CONSTRAINT chk_leituras_corrente CHECK (corrente >= 0),
 CONSTRAINT chk_leituras_potencia CHECK (potencia >= 0),
 CONSTRAINT chk_leituras_brilho CHECK (brilho_percentual BETWEEN 0 AND 100),
 INDEX idx_leituras_poste_data (id_poste, medido_em)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS regras_monitoramento (
 id_regra BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 nome VARCHAR(100) NOT NULL,
 tensao_minima DECIMAL(8,2) NOT NULL,
 tensao_maxima DECIMAL(8,2) NOT NULL,
 corrente_minima DECIMAL(10,3) NOT NULL,
 corrente_maxima DECIMAL(10,3) NOT NULL,
 potencia_minima DECIMAL(10,2) NOT NULL,
 potencia_maxima DECIMAL(10,2) NOT NULL,
 leituras_consecutivas INT UNSIGNED NOT NULL DEFAULT 3,
 tolerancia_sem_comunicacao_seg INT UNSIGNED NOT NULL DEFAULT 60,
 ativa BOOLEAN NOT NULL DEFAULT TRUE,
 -- Garante no maximo uma configuracao global ativa.
 unica_ativa TINYINT GENERATED ALWAYS AS (CASE WHEN ativa = 1 THEN 1 ELSE NULL END) STORED,
 atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT uq_regras_nome UNIQUE (nome),
 CONSTRAINT uq_regras_ativa UNIQUE (unica_ativa),
 CONSTRAINT chk_regras_tensao CHECK (tensao_minima >= 0 AND tensao_maxima >= tensao_minima),
 CONSTRAINT chk_regras_corrente CHECK (corrente_minima >= 0 AND corrente_maxima >= corrente_minima),
 CONSTRAINT chk_regras_potencia CHECK (potencia_minima >= 0 AND potencia_maxima >= potencia_minima),
 CONSTRAINT chk_regras_consecutivas CHECK (leituras_consecutivas >= 1),
 CONSTRAINT chk_regras_tolerancia CHECK (tolerancia_sem_comunicacao_seg >= 1)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS alertas (
 id_alerta BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 id_poste BIGINT UNSIGNED NOT NULL,
 tipo ENUM('eletrica','comunicacao') NOT NULL,
 severidade ENUM('baixa','media','alta') NOT NULL DEFAULT 'media',
 descricao VARCHAR(500) NOT NULL,
 status ENUM('ativo','resolvido') NOT NULL DEFAULT 'ativo',
 criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 resolvido_em DATETIME NULL,
 -- UNIQUE permite multiplos NULL: somente alertas ativos entram na restricao.
 tipo_ativo VARCHAR(20) GENERATED ALWAYS AS (CASE WHEN status = 'ativo' THEN tipo ELSE NULL END) STORED,
 CONSTRAINT fk_alertas_poste FOREIGN KEY (id_poste) REFERENCES postes(id_poste) ON DELETE RESTRICT,
 CONSTRAINT uq_alertas_ativo UNIQUE (id_poste, tipo_ativo),
 CONSTRAINT chk_alertas_resolucao CHECK ((status = 'ativo' AND resolvido_em IS NULL) OR (status = 'resolvido' AND resolvido_em IS NOT NULL)),
 INDEX idx_alertas_status_data (status, criado_em)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ordens_manutencao (
 id_ordem BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 id_alerta BIGINT UNSIGNED NOT NULL,
 id_usuario_responsavel BIGINT UNSIGNED NULL,
 descricao TEXT NOT NULL,
 status ENUM('aberta','em_andamento','concluida') NOT NULL DEFAULT 'aberta',
 criada_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 atualizada_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 concluida_em DATETIME NULL,
 CONSTRAINT uq_ordens_alerta UNIQUE (id_alerta),
 CONSTRAINT fk_ordens_alerta FOREIGN KEY (id_alerta) REFERENCES alertas(id_alerta) ON DELETE RESTRICT,
 CONSTRAINT fk_ordens_usuario FOREIGN KEY (id_usuario_responsavel) REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
 CONSTRAINT chk_ordens_conclusao CHECK ((status = 'concluida' AND concluida_em IS NOT NULL) OR (status <> 'concluida' AND concluida_em IS NULL)),
 INDEX idx_ordens_status_data (status, criada_em),
 INDEX idx_ordens_responsavel (id_usuario_responsavel)
) ENGINE=InnoDB;

-- Sem usuarios, senhas, postes ou regras de exemplo inseridos automaticamente.
-- O seed dos seis postes e os limites ficticios serao definidos separadamente.
