const path = require('path');
// FORÇA o carregamento do arquivo .env da pasta backend, sobrescrevendo qualquer outro
require('dotenv').config({ 
  path: path.join(__dirname, '.env'),
  override: true 
});

console.log('-------------------------------------------');
console.log('DEBUG: Configurações de E-mail');
console.log('SMTP_HOST:', process.env.SMTP_HOST || 'NÃO DEFINIDO');
console.log('SMTP_USER:', process.env.SMTP_USER || 'NÃO DEFINIDO');
console.log('-------------------------------------------');

const express = require('express');
const fs = require('fs');
const nodemailer = require('nodemailer');

const cors = require('cors');
const multer = require('multer');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const pool = require('./db');

// Configuração do Transporter do Nodemailer com Fallback para Gmail
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: (process.env.SMTP_PORT == '465'),
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

const app = express();
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use(express.static(path.join(__dirname, 'public')));

const JWT_SECRET = process.env.JWT_SECRET;

// Midleware de Autenticação
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.sendStatus(401);

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

// Configuração do Multer para Uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const { folder } = req.params;
    const dest = path.join(__dirname, 'uploads', folder || 'general');
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    cb(null, dest);
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}_${file.originalname}`);
  }
});
const upload = multer({ storage });
 
// Função utilitária para excluir arquivos antigos
const deleteFile = (filename) => {
  if (!filename) return;
  // O path no banco é "folder/filename", que coincide com a estrutura em "uploads/"
  const filePath = path.join(__dirname, 'uploads', filename);
  if (fs.existsSync(filePath)) {
    try {
      fs.unlinkSync(filePath);
      console.log('Arquivo antigo excluído:', filePath);
    } catch (err) {
      console.error('Erro ao excluir arquivo:', err);
    }
  }
};

// Função para validar complexidade de senha
const validatePassword = (password) => {
  if (!password) return 'A senha é obrigatória';
  if (password.length < 8) return 'A senha deve ter ao menos 8 caracteres';
  if (!/[A-Z]/.test(password)) return 'A senha deve ter ao menos 1 letra maiúscula';
  if (!/[0-9]/.test(password)) return 'A senha deve ter ao menos 1 número';
  if (!/[^A-Za-z0-9]/.test(password)) return 'A senha deve ter ao menos 1 caractere especial';
  return null;
};

// --- PAGINAS ESTATICAS ---
app.get('/privacy-policy', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'privacy-policy.html'));
});

// --- ROTAS DE AUTENTICAÇÃO ---

app.post('/auth/register', async (req, res) => {
  const { email, password, full_name } = req.body;
  
  const passwordError = validatePassword(password);
  if (passwordError) return res.status(400).json({ error: passwordError });

  const id = uuidv4();
  const password_hash = await bcrypt.hash(password, 10);

  try {
    await pool.query(
      'INSERT INTO profiles (id, email, password_hash, full_name) VALUES (?, ?, ?, ?)',
      [id, email, password_hash, full_name]
    );
    const token = jwt.sign({ id, email }, JWT_SECRET);
    res.json({ user: { id, email, full_name }, session: { access_token: token } });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'Este e-mail já está cadastrado no sistema.' });
    }
    console.error('Erro no registro:', err);
    res.status(500).json({ error: 'Não foi possível completar o cadastro agora. Tente novamente em instantes.' });
  }
});

app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const [rows] = await pool.query('SELECT * FROM profiles WHERE email = ?', [email]);
    if (rows.length === 0) return res.status(401).json({ error: 'Usuário não encontrado' });

    const user = rows[0];
    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) return res.status(401).json({ error: 'Senha incorreta' });

    const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET);
    res.json({ user: { id: user.id, email: user.email, full_name: user.full_name }, session: { access_token: token } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/auth/change-password', authenticateToken, async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  try {
    const [rows] = await pool.query('SELECT password_hash FROM profiles WHERE id = ?', [req.user.id]);
    const user = rows[0];
    
    const validPassword = await bcrypt.compare(currentPassword, user.password_hash);
    if (!validPassword) return res.status(401).json({ error: 'Senha atual incorreta' });

    const passwordError = validatePassword(newPassword);
    if (passwordError) return res.status(400).json({ error: passwordError });

    const newPasswordHash = await bcrypt.hash(newPassword, 10);
    await pool.query('UPDATE profiles SET password_hash = ? WHERE id = ?', [newPasswordHash, req.user.id]);
    
    res.json({ message: 'Senha alterada com sucesso' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/auth/forgot-password', async (req, res) => {
  const { email } = req.body;
  try {
    // Verifica se e-mail existe
    const [users] = await pool.query('SELECT id FROM profiles WHERE email = ?', [email]);
    if (users.length === 0) return res.status(404).json({ error: 'E-mail não encontrado' });

    // Gera PIN de 6 dígitos
    const pin = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutos

    // Remove PINs antigos e insere novo
    await pool.query('DELETE FROM password_resets WHERE email = ?', [email]);
    await pool.query('INSERT INTO password_resets (email, token, expires_at) VALUES (?, ?, ?)', [email, pin, expiresAt]);

    // LOG PARA DESENVOLVIMENTO
    console.log(`\n========================================`);
    console.log(`CÓDIGO DE RECUPERAÇÃO PARA: ${email}`);
    console.log(`CÓDIGO: ${pin}`);
    console.log(`========================================\n`);

    // Envio do E-mail Real
    const mailOptions = {
      from: `"Acervo360 Suporte" <${process.env.SMTP_USER}>`,
      to: email,
      subject: 'Recuperação de Senha - Acervo360',
      html: `
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
          <h2 style="color: #333; text-align: center;">Recuperação de Senha</h2>
          <p>Olá,</p>
          <p>Você solicitou a recuperação de senha da sua conta no <strong>Acervo360</strong>.</p>
          <p>Use o código abaixo para redefinir sua senha. Este código é válido por 15 minutos.</p>
          <div style="background-color: #f4f4f4; padding: 15px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 5px; border-radius: 4px; margin: 20px 0;">
            ${pin}
          </div>
          <p style="color: #666; font-size: 14px;">Se você não solicitou esta redefinição, por favor ignore este e-mail.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="text-align: center; color: #999; font-size: 12px;">© 2024 Acervo360 - Gestão Segura de Acervos</p>
        </div>
      `,
    };

    // Tenta enviar o e-mail e aguarda o resultado
    try {
      await transporter.sendMail(mailOptions);
      res.json({ success: true, message: 'Código enviado com sucesso' });
    } catch (mailErr) {
      console.error('Erro ao enviar e-mail SMTP:', mailErr.message);
      // Retorna o erro específico do SMTP para ajudar no diagnóstico
      res.status(500).json({ error: `Erro no servidor de e-mail: ${mailErr.message}` });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/auth/reset-password', async (req, res) => {
  const { email, token, newPassword } = req.body;
  try {
    // Verifica token (agora buscamos o registro e validamos o tempo no JS)
    const [rows] = await pool.query(
      'SELECT expires_at FROM password_resets WHERE email = ? AND token = ?',
      [email, token]
    );
    
    if (rows.length === 0) {
      return res.status(400).json({ error: 'Código inválido' });
    }

    const expiresAt = new Date(rows[0].expires_at);
    if (expiresAt < new Date()) {
      return res.status(400).json({ error: 'Código expirado' });
    }

    const passwordError = validatePassword(newPassword);
    if (passwordError) return res.status(400).json({ error: passwordError });

    // Atualiza senha
    const password_hash = await bcrypt.hash(newPassword, 10);
    await pool.query('UPDATE profiles SET password_hash = ? WHERE email = ?', [password_hash, email]);

    // Remove token usado
    await pool.query('DELETE FROM password_resets WHERE email = ?', [email]);

    res.json({ success: true, message: 'Senha redefinida com sucesso' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- ROTAS DE PERFIL ---

app.delete('/auth/me', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    await connection.query('DELETE FROM habitualities WHERE owner_user_id = ?', [userId]);
    await connection.query('DELETE FROM gtes WHERE owner_user_id = ?', [userId]);
    await connection.query('DELETE FROM firearms WHERE owner_user_id = ?', [userId]);
    await connection.query('DELETE FROM user_clubs WHERE user_id = ?', [userId]);
    await connection.query('DELETE FROM profile_addresses WHERE user_id = ?', [userId]);
    await connection.query('DELETE FROM user_subscriptions WHERE user_id = ?', [userId]);
    await connection.query('DELETE FROM profiles WHERE id = ?', [userId]);
    await connection.query('DELETE FROM clubs WHERE owner_user_id = ?', [userId]);
    await connection.commit();
    res.json({ success: true });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ error: err.message });
  } finally {
    connection.release();
  }
});

app.get('/profiles/me', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id, email, full_name, cpf, phone, cr_number, cr_categories, cr_valid_until, avatar_url, cr_url, is_admin FROM profiles WHERE id = ?', [req.user.id]);
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/profiles/upsert', authenticateToken, async (req, res) => {
  const data = req.body;
  try {
    // Busca dados atuais para exclusão de arquivos antigos
    const [existing] = await pool.query('SELECT avatar_url, cr_url FROM profiles WHERE id = ?', [req.user.id]);
    const oldData = existing.length > 0 ? existing[0] : {};

    // Se houver cr_categories, precisa converter para string JSON para o MySQL
    const dataToSave = { ...data, email: req.user.email };
    if ('cr_categories' in dataToSave && dataToSave.cr_categories !== null) {
      dataToSave.cr_categories = JSON.stringify(dataToSave.cr_categories);
    }

    const columns = Object.keys(dataToSave);
    if (columns.length > 0) {
      const values = columns.map(k => dataToSave[k]);
      const setClause = columns.map(c => `${c} = ?`).join(', ');
      
      await pool.query(
        `UPDATE profiles SET ${setClause} WHERE id = ?`,
        [...values, req.user.id]
      );
    }

    // Limpeza de arquivos antigos
    if ('avatar_url' in data && oldData.avatar_url && data.avatar_url !== oldData.avatar_url) {
      deleteFile(oldData.avatar_url);
    }
    if ('cr_url' in data && oldData.cr_url && data.cr_url !== oldData.cr_url) {
      deleteFile(oldData.cr_url);
    }

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- ROTAS DE ENDEREÇOS ---

app.get('/profile_addresses/me', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM profile_addresses WHERE user_id = ?', [req.user.id]);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/profile_addresses/upsert', authenticateToken, async (req, res) => {
  const data = req.body;
  const id = data.id || uuidv4();
  try {
    const columns = Object.keys(data).filter(k => k !== 'id');
    const values = columns.map(k => data[k]);
    
    await pool.query(
      `INSERT INTO profile_addresses (id, user_id, ${columns.join(', ')}) 
       VALUES (?, ?, ${columns.map(() => '?').join(', ')}) 
       ON DUPLICATE KEY UPDATE ${columns.map(c => `${c}=VALUES(${c})`).join(', ')}`,
      [id, req.user.id, ...values]
    );
    res.json({ success: true, id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/profile_addresses/:id', authenticateToken, async (req, res) => {
  try {
    await pool.query('DELETE FROM profile_addresses WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// --- ROTAS DE ARMAS ---

app.get('/firearms', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM firearms WHERE owner_user_id = ? ORDER BY created_at DESC', [req.user.id]);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/firearms', authenticateToken, async (req, res) => {
  const data = req.body;
  const id = data.id || uuidv4();
  try {
    // Busca dados atuais para exclusão de arquivos antigos
    const [existing] = await pool.query('SELECT avatar_url, craf_url FROM firearms WHERE id = ? AND owner_user_id = ?', [id, req.user.id]);
    const oldData = existing.length > 0 ? existing[0] : {};

    const columns = Object.keys(data).filter(k => k !== 'id');
    const values = columns.map(k => data[k]);
    
    await pool.query(
      `INSERT INTO firearms (id, owner_user_id, ${columns.join(', ')}) 
       VALUES (?, ?, ${columns.map(() => '?').join(', ')}) 
       ON DUPLICATE KEY UPDATE ${columns.map(c => `${c}=VALUES(${c})`).join(', ')}`,
      [id, req.user.id, ...values]
    );

    // Limpeza de arquivos antigos
    if ('avatar_url' in data && oldData.avatar_url && data.avatar_url !== oldData.avatar_url) {
      deleteFile(oldData.avatar_url);
    }
    if ('craf_url' in data && oldData.craf_url && data.craf_url !== oldData.craf_url) {
      deleteFile(oldData.craf_url);
    }

    res.json({ id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/firearms/:id', authenticateToken, async (req, res) => {
  try {
    await pool.query('DELETE FROM firearms WHERE id = ? AND owner_user_id = ?', [req.params.id, req.user.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- ROTAS DE GTES ---

app.get('/gtes', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT 
        g.*, 
        f.brand as firearm_brand,
        f.model as firearm_model,
        c.name as destination_club_name,
        a.street as origin_street,
        a.number as origin_number
      FROM gtes g 
      LEFT JOIN firearms f ON g.firearm_id = f.id 
      LEFT JOIN clubs c ON g.destination_club_id = c.id
      LEFT JOIN profile_addresses a ON g.profile_address_id = a.id
      WHERE g.owner_user_id = ? 
      ORDER BY g.created_at DESC
    `, [req.user.id]);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/gtes', authenticateToken, async (req, res) => {
  const data = req.body;
  const id = data.id || uuidv4();
  try {
    // Busca dados atuais para exclusão de arquivos antigos
    const [existing] = await pool.query('SELECT gte_url FROM gtes WHERE id = ? AND owner_user_id = ?', [id, req.user.id]);
    const oldGteUrl = existing.length > 0 ? existing[0].gte_url : null;

    const columns = Object.keys(data).filter(k => k !== 'id');
    const values = columns.map(k => data[k]);
    
    await pool.query(
      `INSERT INTO gtes (id, owner_user_id, ${columns.join(', ')}) 
       VALUES (?, ?, ${columns.map(() => '?').join(', ')}) 
       ON DUPLICATE KEY UPDATE ${columns.map(c => `${c}=VALUES(${c})`).join(', ')}`,
      [id, req.user.id, ...values]
    );

    // Limpeza de arquivos antigos
    if ('gte_url' in data && oldGteUrl && data.gte_url !== oldGteUrl) {
      deleteFile(oldGteUrl);
    }

    res.json({ success: true, id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/gtes/:id', authenticateToken, async (req, res) => {
  try {
    await pool.query('DELETE FROM gtes WHERE id = ? AND owner_user_id = ?', [req.params.id, req.user.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// --- ROTAS DE CLUBES ---

app.get('/clubs/search', authenticateToken, async (req, res) => {
  const { query } = req.query;
  try {
    const [rows] = await pool.query(
      'SELECT * FROM clubs WHERE name LIKE ? LIMIT 5',
      [`%${query}%`]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/clubs', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM clubs ORDER BY name ASC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/clubs', authenticateToken, async (req, res) => {
  const data = req.body;
  const id = data.id || uuidv4();
  
  if (!data.owner_user_id) {
    data.owner_user_id = req.user.id;
  }

  try {
    // Busca o logo atual antes de atualizar para poder excluir o arquivo antigo
    const [existing] = await pool.query('SELECT logo_url FROM clubs WHERE id = ?', [id]);
    const oldLogoUrl = existing.length > 0 ? existing[0].logo_url : null;

    const columns = Object.keys(data).filter(k => k !== 'id');
    const values = columns.map(k => data[k]);
    
    await pool.query(
      `INSERT INTO clubs (id, ${columns.join(', ')}) 
       VALUES (?, ${columns.map(() => '?').join(', ')}) 
       ON DUPLICATE KEY UPDATE ${columns.map(c => `${c}=VALUES(${c})`).join(', ')}`,
      [id, ...values]
    );

    // Se o logo_url mudou e havia um logo antigo, exclui o arquivo físico
    if ('logo_url' in data && oldLogoUrl && data.logo_url !== oldLogoUrl) {
      deleteFile(oldLogoUrl);
    }

    res.json({ success: true, id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/clubs/:id', authenticateToken, async (req, res) => {
  try {
    await pool.query('DELETE FROM clubs WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/user_clubs/me', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT c.*, uc.id as user_club_id 
      FROM user_clubs uc 
      JOIN clubs c ON uc.club_id = c.id 
      WHERE uc.user_id = ?
    `, [req.user.id]);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
app.post('/user_clubs', authenticateToken, async (req, res) => {
  const { club_id } = req.body;
  try {
    const [existing] = await pool.query('SELECT id FROM user_clubs WHERE user_id = ? AND club_id = ?', [req.user.id, club_id]);
    if (existing.length > 0) return res.json({ success: true, id: existing[0].id });
    
    const id = uuidv4();
    await pool.query('INSERT INTO user_clubs (id, user_id, club_id) VALUES (?, ?, ?)', [id, req.user.id, club_id]);
    res.json({ success: true, id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/user_clubs/:id', authenticateToken, async (req, res) => {
  try {
    await pool.query('DELETE FROM user_clubs WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


app.get('/habituality_modalities', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM habituality_modalities ORDER BY name ASC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/habitualities', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT h.*, f.brand, f.model, f.caliber 
      FROM habitualities h 
      LEFT JOIN firearms f ON h.firearm_id = f.id 
      WHERE h.owner_user_id = ? 
      ORDER BY h.date_realization DESC
    `, [req.user.id]);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/habitualities', authenticateToken, async (req, res) => {
  const data = req.body;
  const id = data.id || uuidv4();
  try {
    // Busca dados atuais para exclusão de arquivos antigos
    const [existing] = await pool.query('SELECT attachment_url FROM habitualities WHERE id = ? AND owner_user_id = ?', [id, req.user.id]);
    const oldAttachmentUrl = existing.length > 0 ? existing[0].attachment_url : null;

    const columns = Object.keys(data).filter(k => k !== 'id');
    const values = columns.map(k => data[k]);
    
    await pool.query(
      `INSERT INTO habitualities (id, owner_user_id, ${columns.join(', ')}) 
       VALUES (?, ?, ${columns.map(() => '?').join(', ')}) 
       ON DUPLICATE KEY UPDATE ${columns.map(c => `${c}=VALUES(${c})`).join(', ')}`,
      [id, req.user.id, ...values]
    );

    // Limpeza de arquivos antigos
    if ('attachment_url' in data && oldAttachmentUrl && data.attachment_url !== oldAttachmentUrl) {
      deleteFile(oldAttachmentUrl);
    }

    res.json({ id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/habitualities/:id', authenticateToken, async (req, res) => {
  try {
    await pool.query('DELETE FROM habitualities WHERE id = ? AND owner_user_id = ?', [req.params.id, req.user.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/habitualities/stats', authenticateToken, async (req, res) => {
  const { startDate, endDate } = req.query;
  const userId = req.user.id;

  if (!startDate || !endDate) {
    return res.status(400).json({ error: 'As datas de início e fim são obrigatórias.' });
  }

  try {
    // 1. Habitualidades e disparos por arma
    const [byFirearm] = await pool.query(`
      SELECT 
        f.id,
        f.brand, 
        f.model, 
        f.sigma_number,
        f.caliber,
        COUNT(h.id) as habituality_count,
        COALESCE(SUM(h.shot_count), 0) as total_shots
      FROM firearms f
      LEFT JOIN habitualities h ON f.id = h.firearm_id AND h.date_realization BETWEEN ? AND ?
      WHERE f.owner_user_id = ?
      GROUP BY f.id, f.brand, f.model, f.sigma_number, f.caliber
      ORDER BY habituality_count DESC
    `, [startDate, endDate, userId]);

    // 2. Habitualidades por clube
    const [byClub] = await pool.query(`
      SELECT 
        COALESCE(c.name, h.location_name, 'Local não informado') as club_name,
        COUNT(h.id) as habituality_count
      FROM habitualities h
      LEFT JOIN clubs c ON h.club_id = c.id
      WHERE h.owner_user_id = ? AND h.date_realization BETWEEN ? AND ?
      GROUP BY club_name
      ORDER BY habituality_count DESC
    `, [userId, startDate, endDate]);

    res.json({
      byFirearm,
      byClub
    });
  } catch (err) {
    console.error('Erro ao buscar estatísticas:', err);
    res.status(500).json({ error: err.message });
  }
});

// --- UPLOAD DE ARQUIVOS ---

app.post('/upload/:folder', authenticateToken, (req, res) => {
  const { folder } = req.params;
  const uploadMiddleware = upload.single('file');

  uploadMiddleware(req, res, (err) => {
    if (err) {
      console.error('Erro no upload:', err);
      return res.status(500).json({ error: err.message });
    }
    if (!req.file) return res.status(400).json({ error: 'Nenhum arquivo enviado' });

    const publicUrl = `${folder}/${req.file.filename}`;
    res.json({ path: publicUrl });
  });
});

// --- ROTAS DE ASSINATURA ---

app.get('/subscriptions/plans', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM subscription_plans WHERE active = 1 ORDER BY sort_order ASC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/subscriptions/me', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM user_subscriptions WHERE user_id = ?', [req.user.id]);
    res.json(rows[0] || null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/subscriptions/ensure', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id FROM user_subscriptions WHERE user_id = ?', [req.user.id]);
    if (rows.length === 0) {
      const start = new Date();
      const end = new Date();
      end.setDate(start.getDate() + 30);
      const sub_id = uuidv4();
      await pool.query(
        'INSERT INTO user_subscriptions (id, user_id, plan, start_date, end_date, status) VALUES (?, ?, ?, ?, ?, ?)',
        [sub_id, req.user.id, 'trial', start, end, 'active']
      );
    }
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/subscriptions/purchase', authenticateToken, async (req, res) => {
  try {
    const { plan, userId, price } = req.body;

    if (!userId) {
      return res.status(400).json({ error: 'ID do usuário é obrigatório' });
    }

    // Buscar dados do usuário para o e-mail
    const [users] = await pool.query('SELECT full_name, email FROM profiles WHERE id = ?', [userId]);
    const userProfile = users[0];

    if (!userProfile) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    // Formata o preço para o padrão brasileiro (R$ 0,00)
    const formattedPrice = new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL'
    }).format(price || 0);

    // Enviar e e-mail de notificação para o administrador (Braulio)
    const mailOptions = {
      from: `"Sistema Acervo360" <${process.env.SMTP_USER}>`,
      to: 'braulio.duque@gmail.com',
      subject: `🚀 Nova Solicitação de Assinatura - ${userProfile.full_name}`,
      html: `
        <div style="font-family: sans-serif; padding: 20px; color: #333; line-height: 1.6;">
          <h2 style="color: #1E56D1;">Nova Solicitação de Assinatura</h2>
          <p>O usuário abaixo manifestou interesse em um plano no <strong>Acervo360</strong>:</p>
          <div style="background-color: #f9f9f9; padding: 15px; border-radius: 8px; border-left: 4px solid #1E56D1;">
            <p style="margin: 5px 0;"><strong>Nome:</strong> ${userProfile.full_name}</p>
            <p style="margin: 5px 0;"><strong>E-mail:</strong> ${userProfile.email}</p>
            <p style="margin: 5px 0;"><strong>Plano Selecionado:</strong> <span style="color: #1E56D1; font-weight: bold;">${(plan || 'não informado').toUpperCase()}</span></p>
            <p style="margin: 5px 0;"><strong>Valor do Plano:</strong> <span style="color: #1E56D1; font-weight: bold;">${formattedPrice}</span></p>
            <p style="margin: 5px 0;"><strong>Data da Solicitação:</strong> ${new Date().toLocaleString('pt-BR')}</p>
          </div>
          <p>Por favor, entre em contato com o cliente para finalizar o processo de ativação.</p>
          <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;" />
          <div style="font-size: 11px; color: #999;">
            Mensagem gerada automaticamente pelo servidor Acervo360.
          </div>
        </div>
      `
    };

    // Enviar e aguardar o resultado para logar no console
    await transporter.sendMail(mailOptions);
    console.log(`SUCESSO: E-mail de interesse enviado para Braulio (Plano: ${plan}, Valor: ${formattedPrice})`);

    res.json({ success: true });
  } catch (err) {
    console.error('ERRO na rota de assinatura:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// --- ROTAS DE CONFIGURAÇÕES DO APP ---

// Função para garantir que a tabela de configurações existe
const ensureSettingsTable = async () => {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS app_settings (
        id INT PRIMARY KEY,
        cr_days INT DEFAULT 90,
        craf_days INT DEFAULT 90,
        gte_days INT DEFAULT 45,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  `);
};

app.get('/app-settings', authenticateToken, async (req, res) => {
  try {
    await ensureSettingsTable();
    const [rows] = await pool.query('SELECT * FROM app_settings WHERE id = 1');
    if (rows.length === 0) {
      // Retorna valores padrão caso não exista na tabela ainda
      return res.json({ cr_days: 90, craf_days: 90, gte_days: 45 });
    }
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/app-settings', authenticateToken, async (req, res) => {
  try {
    await ensureSettingsTable();
    
    // Verifica se é admin
    const [userRows] = await pool.query('SELECT is_admin FROM profiles WHERE id = ?', [req.user.id]);
    if (userRows.length === 0 || userRows[0].is_admin !== 'S') {
      return res.status(403).json({ error: 'Acesso negado. Apenas administradores podem alterar configurações.' });
    }

    const { cr_days, craf_days, gte_days } = req.body;
    
    await pool.query(
      `INSERT INTO app_settings (id, cr_days, craf_days, gte_days) 
       VALUES (1, ?, ?, ?) 
       ON DUPLICATE KEY UPDATE cr_days = VALUES(cr_days), craf_days = VALUES(craf_days), gte_days = VALUES(gte_days)`,
      [cr_days, craf_days, gte_days]
    );

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Inicializa o servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`\nServidor rodando em http://localhost:${PORT}`);
  
  // Testar conexão SMTP na inicialização
  transporter.verify((error, success) => {
    if (error) {
      console.log('ERRO: Configuração de e-mail (SMTP) inválida:', error.message);
    } else {
      console.log('SUCESSO: Servidor pronto para enviar e-mails via SMTP');
    }
  });
});
