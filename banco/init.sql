-- =============================================================================
-- BANCO DE DADOS RELACIONAL — TECHSTORE (DATASET COMPLETO)
-- Disciplina: Banco de Dados Relacional (TSI33D-TSI3)
-- UTFPR Campus Guarapuava — Prof. Marcelo Vichar
-- =============================================================================

CREATE DATABASE IF NOT EXISTS techstore
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE techstore;

-- -----------------------------------------------------------------------------
-- 1. ESTRUTURA DAS TABELAS
-- -----------------------------------------------------------------------------

-- Tabela: categorias
CREATE TABLE IF NOT EXISTS categorias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- Tabela: clientes
CREATE TABLE IF NOT EXISTS clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    cidade VARCHAR(50) NOT NULL,
    data_cadastro DATE NOT NULL
) ENGINE=InnoDB;

-- Tabela: produtos
CREATE TABLE IF NOT EXISTS produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    preco DECIMAL(10,2) NOT NULL,
    estoque INT NOT NULL DEFAULT 0,
    categoria_id INT NOT NULL,
    CONSTRAINT fk_produtos_categoria
        FOREIGN KEY (categoria_id) REFERENCES categorias(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Tabela: pedidos
CREATE TABLE IF NOT EXISTS pedidos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    data_pedido DATE NOT NULL,
    status ENUM('pendente', 'pago', 'enviado', 'entregue', 'cancelado') NOT NULL DEFAULT 'pendente',
    CONSTRAINT fk_pedidos_cliente
        FOREIGN KEY (cliente_id) REFERENCES clientes(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Tabela: itens_pedido (Entidade Associativa N:N entre Pedidos e Produtos)
CREATE TABLE IF NOT EXISTS itens_pedido (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL,
    produto_id INT NOT NULL,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_itens_pedido
        FOREIGN KEY (pedido_id) REFERENCES pedidos(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_itens_produto
        FOREIGN KEY (produto_id) REFERENCES produtos(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 2. CARGA DE DADOS (DATASET REALISTA E RECHEADO)
-- -----------------------------------------------------------------------------

-- Categorias (9 categorias, cobrindo eletrônicos, móveis, livros e serviços)
INSERT INTO categorias (id, nome) VALUES
(1, 'Informática & Computadores'),
(2, 'Smartphones & Tablets'),
(3, 'Áudio & Vídeo'),
(4, 'Games & Consoles'),
(5, 'Periféricos & Acessórios'),
(6, 'Hardware & Componentes'),
(7, 'Livros Técnicos'),
(8, 'Móveis & Ergonomia'),
(9, 'Softwares & Licenças');

-- Clientes (25 clientes distribuídos pelo Paraná e outros estados)
-- Obs: Alguns clientes têm muitas compras, outros poucas e alguns NUNCA compraram (ótimo para LEFT JOIN e NOT IN)
INSERT INTO clientes (id, nome, email, cidade, data_cadastro) VALUES
(1,  'Ana Silva',            'ana.silva@email.com',          'Guarapuava',    '2025-01-15'),
(2,  'Bruno Costa',          'bruno.costa@email.com',        'Curitiba',      '2025-01-20'),
(3,  'Carla Oliveira',       'carla.oliveira@email.com',     'Londrina',      '2025-02-01'),
(4,  'Daniel Santos',        'daniel.santos@email.com',      'Guarapuava',    '2025-02-10'),
(5,  'Elena Ferreira',       'elena.ferreira@email.com',     'Maringá',       '2025-02-15'),
(6,  'Felipe Lima',          'felipe.lima@email.com',        'Ponta Grossa',  '2025-03-01'),
(7,  'Gabriela Rocha',       'gabriela.rocha@email.com',     'Cascavel',      '2025-03-05'),
(8,  'Henrique Alves',       'henrique.alves@email.com',     'Guarapuava',    '2025-03-10'),
(9,  'Isabela Souza',        'isabela.souza@email.com',      'Pato Branco',   '2025-03-15'),
(10, 'João Pedro Mendes',    'joao.mendes@email.com',        'Toledo',        '2025-03-20'),
(11, 'Larissa Martins',      'larissa.martins@email.com',    'Curitiba',      '2025-04-05'),
(12, 'Marcos Vinicius Dias', 'marcos.dias@email.com',       'Guarapuava',    '2025-04-12'),
(13, 'Natália Cardoso',      'natalia.cardoso@email.com',    'Foz do Iguaçu', '2025-04-20'),
(14, 'Otávio Guimarães',     'otavio.guimaraes@email.com',   'Londrina',      '2025-05-02'),
(15, 'Patrícia Ribeiro',     'patricia.ribeiro@email.com',   'Ponta Grossa',  '2025-05-18'),
(16, 'Rafael Nogueira',      'rafael.nogueira@email.com',    'Curitiba',      '2025-06-01'),
(17, 'Sabrina Barbosa',      'sabrina.barbosa@email.com',    'Maringá',       '2025-06-15'),
(18, 'Thiago Castilho',      'thiago.castilho@email.com',    'Guarapuava',    '2025-07-01'),
(19, 'Ursula Fontes',        'ursula.fontes@email.com',      'Cascavel',      '2025-07-20'),
(20, 'Victor Hugo Prado',    'victor.prado@email.com',       'Pato Branco',   '2025-08-10'),
(21, 'Wagner Siqueira',      'wagner.siqueira@email.com',    'Curitiba',      '2025-09-05'),
(22, 'Xênia Medeiros',       'xenia.medeiros@email.com',     'Londrina',      '2025-10-12'),
(23, 'Yuri Bittencourt',     'yuri.bittencourt@email.com',   'Guarapuava',    '2025-11-01'),
(24, 'Zuleica Antunes',      'zuleica.antunes@email.com',    'Maringá',       '2025-12-05'),
(25, 'Marcelo Augusto',      'marcelo.augusto@email.com',    'Curitiba',      '2026-01-10');

-- Produtos (30 produtos com preços de R$ 24,90 a R$ 8.499,00 e estoques diversos)
-- Obs: Alguns produtos estão com estoque 0 e alguns NUNCA foram vendidos (ótimo para exercícios de estoque e LEFT JOIN)
INSERT INTO produtos (id, nome, preco, estoque, categoria_id) VALUES
-- Informática & Computadores (Cat 1)
(1,  'Notebook Lenovo ThinkPad E14 (16GB, SSD 512GB)',     4299.90, 15, 1),
(2,  'Notebook Dell Inspiron 15 (8GB, SSD 256GB)',         2999.00,  8, 1),
(3,  'MacBook Air M2 13" (8GB, SSD 256GB)',                7499.00,  5, 1),
(4,  'PC Gamer Intel i7, RTX 4060, 32GB RAM, SSD 1TB',     6899.90,  4, 1),

-- Smartphones & Tablets (Cat 2)
(5,  'Smartphone Samsung Galaxy S24 (256GB)',              4199.00, 12, 2),
(6,  'iPhone 15 128GB - Preto',                            5299.00,  7, 2),
(7,  'Tablet iPad 10ª Geração 64GB Wi-Fi',                 3199.00, 10, 2),
(8,  'Smartphone Xiaomi Redmi Note 13 (128GB)',            1299.00, 25, 2),

-- Áudio & Vídeo (Cat 3)
(9,  'Monitor Dell 27" 4K IPS UHD',                        1899.00, 20, 3),
(10, 'Monitor Gamer LG UltraGear 24" 144Hz 1ms',           949.00, 18, 3),
(11, 'Headphone Bluetooth Sony Noise Cancelling WH-1000XM5', 2199.00,  6, 3),
(12, 'Caixa de Som Portátil JBL Flip 6 Bluetooth',           599.00, 30, 3),

-- Games & Consoles (Cat 4)
(13, 'Console PlayStation 5 Slim 1TB',                     3699.90,  9, 4),
(14, 'Console Xbox Series X 1TB',                          4199.00,  5, 4),
(15, 'Console Nintendo Switch OLED 64GB',                  2199.00, 14, 4),
(16, 'Controle Sem Fio DualSense PS5 - Branco',             389.00, 35, 4),
(17, 'Controle Xbox Sem Fio - Carbon Black',                379.00, 28, 4),

-- Periféricos & Acessórios (Cat 5)
(18, 'Teclado Mecânico RGB Switch Red ABNT2',               349.90, 45, 5),
(19, 'Mouse Gamer Sem Fio 16000 DPI Ultra Leve',            229.90, 60, 5),
(20, 'Webcam Full HD 1080p 60fps com Microfone',            289.00, 22, 5),
(21, 'Hub USB-C 7 em 1 com HDMI 4K e Leitor de Cartão',     179.90, 40, 5),
(22, 'Mousepad Gamer Extra Grande 90x40cm',                  79.90, 80, 5),

-- Hardware & Componentes (Cat 6)
(23, 'SSD NVMe M.2 1TB Leitura 3500MB/s',                   399.00, 50, 6),
(24, 'Memória RAM DDR4 16GB 3200MHz',                       249.90, 40, 6),
(25, 'Placa de Vídeo RTX 4070 12GB GDDR6X',                4399.00,  0, 6), -- Estoque zero

-- Livros Técnicos (Cat 7)
(26, 'Clean Code: Habilidades Práticas do Agile Software',    89.90, 35, 7),
(27, 'O Programador Pragmático: De Aprendiz a Mestre',        94.50, 25, 7),
(28, 'Designing Data-Intensive Applications (Kleppmann)',    189.00, 15, 7),

-- Móveis & Ergonomia (Cat 8)
(29, 'Cadeira Ergonômica Presidente com Apoio de Cabeça',    989.00, 10, 8),
(30, 'Mesa com Regulagem Elétrica de Altura (Standing Desk)', 2199.00,  3, 8);

-- Pedidos (35 pedidos distribuídos ao longo de 2025 e 2026 com vários status)
INSERT INTO pedidos (id, cliente_id, data_pedido, status) VALUES
-- Pedidos de 2025
(1,   1, '2025-03-01', 'entregue'),
(2,   2, '2025-03-15', 'entregue'),
(3,   3, '2025-04-02', 'entregue'),
(4,   4, '2025-04-20', 'entregue'),
(5,   1, '2025-05-10', 'entregue'),
(6,   5, '2025-05-25', 'entregue'),
(7,   6, '2025-06-12', 'entregue'),
(8,   7, '2025-06-28', 'cancelado'),
(9,   8, '2025-07-05', 'entregue'),
(10,  2, '2025-07-19', 'entregue'),
(11,  9, '2025-08-01', 'entregue'),
(12, 10, '2025-08-15', 'entregue'),
(13, 11, '2025-09-02', 'entregue'),
(14, 12, '2025-09-20', 'entregue'),
(15,  3, '2025-10-05', 'entregue'),
(16, 13, '2025-10-18', 'cancelado'),
(17, 14, '2025-11-01', 'entregue'),
(18,  1, '2025-11-15', 'entregue'),
(19, 15, '2025-11-28', 'entregue'),
(20, 16, '2025-12-10', 'entregue'),
(21,  4, '2025-12-20', 'entregue'),
(22,  2, '2025-12-28', 'entregue'),

-- Pedidos de 2026
(23,  5, '2026-01-08', 'entregue'),
(24, 17, '2026-01-20', 'entregue'),
(25, 18, '2026-02-01', 'entregue'),
(26,  6, '2026-02-14', 'entregue'),
(27,  1, '2026-02-28', 'entregue'),
(28, 19, '2026-03-05', 'enviado'),
(29, 20, '2026-03-10', 'enviado'),
(30,  3, '2026-03-12', 'enviado'),
(31,  7, '2026-03-15', 'pago'),
(32,  8, '2026-03-18', 'pago'),
(33, 11, '2026-03-20', 'pago'),
(34, 12, '2026-03-22', 'pendente'),
(35,  2, '2026-03-25', 'pendente');

-- Itens de Pedido (80+ itens associados aos pedidos)
INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario) VALUES
-- Pedido 1 (Ana Silva - Setups de Trabalho)
(1,  1, 1, 4299.90),
(1,  9, 1, 1899.00),
(1, 18, 1,  349.90),
(1, 19, 1,  229.90),

-- Pedido 2 (Bruno Costa - Games)
(2, 13, 1, 3699.90),
(2, 16, 2,  389.00),
(2, 22, 1,   79.90),

-- Pedido 3 (Carla Oliveira - Mobile)
(3,  5, 1, 4199.00),
(3, 12, 1,  599.00),

-- Pedido 4 (Daniel Santos - Livros & Upgrade)
(4, 23, 2,  399.00),
(4, 24, 2,  249.90),
(4, 26, 1,   89.90),
(4, 27, 1,   94.50),

-- Pedido 5 (Ana Silva - Livros Técnicos)
(5, 26, 1,   89.90),
(5, 27, 1,   94.50),
(5, 28, 1,  189.00),

-- Pedido 6 (Elena Ferreira - Home Office)
(6,  2, 1, 2999.00),
(6, 10, 1,  949.00),
(6, 20, 1,  289.00),
(6, 29, 1,  989.00),

-- Pedido 7 (Felipe Lima - Periféricos)
(7, 18, 1,  349.90),
(7, 19, 1,  229.90),
(7, 21, 1,  179.90),

-- Pedido 8 (Gabriela Rocha - Cancelado)
(8,  6, 1, 5299.00),

-- Pedido 9 (Henrique Alves - Áudio)
(9, 11, 1, 2199.00),
(9, 21, 1,  179.90),

-- Pedido 10 (Bruno Costa - Nintendo)
(10, 15, 1, 2199.00),
(10, 22, 1,   79.90),

-- Pedido 11 (Isabela Souza - Tablet)
(11,  7, 1, 3199.00),
(11, 12, 1,  599.00),

-- Pedido 12 (João Pedro Mendes - Xiaomi & Periféricos)
(12,  8, 1, 1299.00),
(12, 19, 1,  229.90),
(12, 22, 1,   79.90),

-- Pedido 13 (Larissa Martins - MacBook)
(13,  3, 1, 7499.00),
(13, 21, 2,  179.90),

-- Pedido 14 (Marcos Vinicius Dias - Games)
(14, 14, 1, 4199.00),
(14, 17, 1,  379.00),

-- Pedido 15 (Carla Oliveira - Ergo)
(15, 29, 1,  989.00),
(15, 30, 1, 2199.00),

-- Pedido 16 (Natália Cardoso - Cancelado)
(16,  4, 1, 6899.90),

-- Pedido 17 (Otávio Guimarães - Upgrade PC)
(17, 23, 1,  399.00),
(17, 24, 2,  249.90),

-- Pedido 18 (Ana Silva - Presente Nintendo)
(18, 15, 1, 2199.00),

-- Pedido 19 (Patrícia Ribeiro - Monitor & Áudio)
(19, 10, 1,  949.00),
(19, 12, 1,  599.00),

-- Pedido 20 (Rafael Nogueira - PC Gamer Top)
(20,  4, 1, 6899.90),
(20,  9, 1, 1899.00),
(20, 18, 1,  349.90),
(20, 19, 1,  229.90),

-- Pedido 21 (Daniel Santos - Acessórios)
(21, 20, 1,  289.00),
(21, 21, 1,  179.90),
(21, 22, 2,   79.90),

-- Pedido 22 (Bruno Costa - Headphones)
(22, 11, 1, 2199.00),

-- Pedido 23 (Elena Ferreira - Livros & SSD)
(23, 23, 1,  399.00),
(23, 26, 1,   89.90),
(23, 27, 1,   94.50),

-- Pedido 24 (Sabrina Barbosa - iPhone)
(24,  6, 1, 5299.00),
(24, 11, 1, 2199.00),

-- Pedido 25 (Thiago Castilho - Setup Dev)
(25,  1, 1, 4299.90),
(25,  9, 2, 1899.00),
(25, 18, 1,  349.90),
(25, 30, 1, 2199.00),

-- Pedido 26 (Felipe Lima - Games)
(26, 13, 1, 3699.90),
(26, 16, 1,  389.00),

-- Pedido 27 (Ana Silva - Cadeira)
(27, 29, 1,  989.00),

-- Pedido 28 (Ursula Fontes - Xiaomi)
(28,  8, 1, 1299.00),
(28, 12, 1,  599.00),

-- Pedido 29 (Victor Hugo Prado - Monitor Gamer)
(29, 10, 1,  949.00),
(29, 18, 1,  349.90),
(29, 19, 1,  229.90),

-- Pedido 30 (Carla Oliveira - Acessórios)
(30, 20, 1,  289.00),
(30, 21, 1,  179.90),

-- Pedido 31 (Gabriela Rocha - Galaxy S24)
(31,  5, 1, 4199.00),

-- Pedido 32 (Henrique Alves - Teclado & Mouse)
(32, 18, 1,  349.90),
(32, 19, 1,  229.90),

-- Pedido 33 (Larissa Martins - Livros)
(33, 26, 1,   89.90),
(33, 27, 1,   94.50),
(33, 28, 1,  189.00),

-- Pedido 34 (Marcos Vinicius Dias - Switch OLED)
(34, 15, 1, 2199.00),

-- Pedido 35 (Bruno Costa - Upgrade RAM & SSD)
(35, 23, 2,  399.00),
(35, 24, 2,  249.90);
