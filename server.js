

const express = require('express');
const fs = require('fs');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// ========================================
// ARQUIVO JSON ONDE AS KEYS FICAM SALVAS
// ========================================
const KEYS_FILE = path.join(__dirname, 'keys.json');

// ========================================
// FUNÇÕES DE LEITURA/ESCRITA DO JSON
// ========================================
function readKeys() {
    try {
        const data = fs.readFileSync(KEYS_FILE, 'utf8');
        return JSON.parse(data);
    } catch (err) {
        // Se o arquivo não existir, cria com array vazio
        return [];
    }
}

function writeKeys(keys) {
    fs.writeFileSync(KEYS_FILE, JSON.stringify(keys, null, 2), 'utf8');
}

// ========================================
// SEU SCRIPT PRINCIPAL (PROTEGIDO)
// ========================================
const PROTECTED_SCRIPT = `
print("✅ SCRIPT CARREGADO COM SEGURANÇA!")

-- === COLOCA AQUI O SEU SCRIPT (HUB, FARM, ETC) ===
local player = game.Players.LocalPlayer
if player and player.Character then
    player.Character.Humanoid.WalkSpeed = 100
    print("Speed ativado!")
end
-- ================================================
`;

// ========================================
// ROTA DE VERIFICAÇÃO (USADA PELO EXECUTOR)
// ========================================
app.get('/verificar', (req, res) => {
    const userKey = req.query.key || '';
    const keys = readKeys();
    const found = keys.find(k => k.chave === userKey);

    if (found) {
        // Verifica se expirou
        const agora = Date.now();
        const expiracao = new Date(found.criadoEm).getTime() + (found.dias * 24 * 60 * 60 * 1000);
        if (expiracao < agora) {
            return res.send('EXPIRADA');
        }
        console.log(`✅ Key válida: ${userKey} (${found.nome})`);
        return res.send(PROTECTED_SCRIPT);
    } else {
        console.log(`❌ Key inválida: ${userKey}`);
        return res.send('INVALIDO');
    }
});

// ========================================
// MIDDLEWARE PARA JSON E ARQUIVOS ESTÁTICOS
// ========================================
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public'))); // se quiser HTML separado

// ========================================
// ROTAS DA API DE GERENCIAMENTO
// ========================================

// Listar todas as keys
app.get('/api/keys', (req, res) => {
    const keys = readKeys();
    res.json(keys);
});

// Adicionar nova key
app.post('/api/keys', (req, res) => {
    const { nome, chave, dias } = req.body;
    if (!nome || !chave || !dias) {
        return res.status(400).json({ erro: 'Campos obrigatórios: nome, chave, dias' });
    }
    if (isNaN(dias) || dias <= 0) {
        return res.status(400).json({ erro: 'Dias deve ser um número positivo' });
    }

    const keys = readKeys();
    if (keys.find(k => k.chave === chave)) {
        return res.status(400).json({ erro: 'Esta chave já existe' });
    }

    const novaKey = {
        nome: nome,
        chave: chave,
        dias: parseInt(dias),
        criadoEm: new Date().toISOString()
    };
    keys.push(novaKey);
    writeKeys(keys);
    res.status(201).json(novaKey);
});

// Remover uma key
app.delete('/api/keys/:chave', (req, res) => {
    const chave = req.params.chave;
    let keys = readKeys();
    const filtradas = keys.filter(k => k.chave !== chave);
    if (filtradas.length === keys.length) {
        return res.status(404).json({ erro: 'Key não encontrada' });
    }
    writeKeys(filtradas);
    res.json({ mensagem: 'Key removida com sucesso' });
});

// ========================================
// SERVE O HTML DO PAINEL (embutido)
// ========================================
app.get('/', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gerenciador de Keys</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #0b0e14;
            color: #e0e0e0;
            padding: 20px;
            min-height: 100vh;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        h1 {
            font-size: 2.2rem;
            font-weight: 300;
            border-bottom: 2px solid #2a2f3a;
            padding-bottom: 10px;
            margin-bottom: 25px;
            color: #fff;
        }
        .card {
            background: #1a1e26;
            border-radius: 12px;
            padding: 20px 25px;
            margin-bottom: 25px;
            box-shadow: 0 8px 16px rgba(0,0,0,0.4);
        }
        .card h2 {
            font-size: 1.3rem;
            font-weight: 400;
            margin-bottom: 15px;
            color: #c0c8d8;
        }
        .flex-row {
            display: flex;
            flex-wrap: wrap;
            gap: 15px;
            align-items: flex-end;
        }
        .form-group {
            display: flex;
            flex-direction: column;
            flex: 1 1 180px;
        }
        .form-group label {
            font-size: 0.8rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #888fa0;
            margin-bottom: 4px;
        }
        .form-group input {
            background: #0f131a;
            border: 1px solid #2f3542;
            color: #fff;
            padding: 8px 12px;
            border-radius: 6px;
            font-size: 0.95rem;
        }
        .form-group input:focus {
            outline: none;
            border-color: #4a7cf7;
        }
        .btn {
            background: #2a3240;
            border: none;
            color: #fff;
            padding: 8px 18px;
            border-radius: 6px;
            font-size: 0.95rem;
            cursor: pointer;
            transition: background 0.2s;
            height: 40px;
            font-weight: 500;
            white-space: nowrap;
        }
        .btn:hover { background: #3a4456; }
        .btn-primary { background: #1f6feb; }
        .btn-primary:hover { background: #3884ff; }
        .btn-danger { background: #b3313a; }
        .btn-danger:hover { background: #d13e48; }
        .btn-success { background: #2d8f4e; }
        .btn-success:hover { background: #3aac62; }
        .btn-sm { padding: 4px 12px; font-size: 0.8rem; height: 30px; }
        .table-wrapper { overflow-x: auto; margin-top: 5px; }
        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.9rem;
        }
        th {
            text-align: left;
            padding: 12px 10px;
            background: #252b36;
            color: #b0baca;
            font-weight: 500;
            border-bottom: 2px solid #303845;
        }
        td {
            padding: 10px 10px;
            border-bottom: 1px solid #262d38;
            vertical-align: middle;
        }
        tr:hover td { background: #1e232d; }
        .badge {
            display: inline-block;
            padding: 3px 12px;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
        }
        .badge-success { background: #1f6f4a; color: #b0f0d0; }
        .badge-danger { background: #7a2d34; color: #f8b0b0; }
        .empty { text-align: center; color: #5a6478; padding: 40px 0; font-style: italic; }
        .actions {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 15px;
            align-items: center;
        }
        .status-text { font-size: 0.8rem; margin-top: 5px; color: #a0aaba; }
        .key-cell { font-family: 'Courier New', monospace; font-size: 0.85rem; color: #a0b8d8; word-break: break-all; }
        .copy-btn {
            background: transparent;
            border: 1px solid #3a4456;
            color: #b0baca;
            border-radius: 4px;
            padding: 0 6px;
            font-size: 0.7rem;
            cursor: pointer;
            transition: 0.2s;
            height: 22px;
            margin-left: 6px;
        }
        .copy-btn:hover { background: #2a3240; border-color: #5a6a8a; }
        .gen-btn {
            background: #2a3240;
            border: none;
            color: #b0baca;
            border-radius: 4px;
            padding: 0 10px;
            font-size: 0.8rem;
            cursor: pointer;
            height: 32px;
        }
        .gen-btn:hover { background: #3a4456; }
        .inline-flex { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
        .file-input-label {
            background: #2a3240;
            padding: 8px 18px;
            border-radius: 6px;
            cursor: pointer;
            transition: background 0.2s;
            height: 40px;
            display: inline-flex;
            align-items: center;
        }
        .file-input-label:hover { background: #3a4456; }
        #fileInput { display: none; }
        @media (max-width: 700px) {
            .flex-row { flex-direction: column; align-items: stretch; }
            .form-group { flex: 1 1 auto; }
            .btn { width: 100%; justify-content: center; }
            .actions { flex-direction: column; align-items: stretch; }
            .file-input-label { justify-content: center; }
        }
    </style>
</head>
<body>
<div class="container">
    <h1>🔐 Gerenciador de Keys</h1>

    <div class="card">
        <h2>➕ Adicionar nova Key</h2>
        <div class="flex-row">
            <div class="form-group">
                <label>Nome / Identificação</label>
                <input type="text" id="keyName" placeholder="Ex: Plano VIP" />
            </div>
            <div class="form-group">
                <label>Dias de validade</label>
                <input type="number" id="keyDays" value="30" min="1" />
            </div>
            <div class="form-group" style="flex:1 1 220px;">
                <label>Chave (deixe em branco para gerar)</label>
                <div class="inline-flex">
                    <input type="text" id="keyValue" placeholder="Ou clique em gerar" style="flex:1;" />
                    <button class="gen-btn" id="generateKeyBtn">🎲 Gerar</button>
                </div>
            </div>
            <button class="btn btn-primary" id="addKeyBtn">➕ Adicionar</button>
        </div>
        <div id="addStatus" class="status-text"></div>
    </div>

    <div class="card">
        <div class="actions">
            <button class="btn btn-danger" id="clearAllBtn">🗑️ Limpar todas</button>
            <button class="btn btn-success" id="exportBtn">📥 Exportar JSON</button>
            <label class="file-input-label" id="importLabel">📤 Importar JSON
                <input type="file" id="fileInput" accept=".json" />
            </label>
            <span style="color:#5a6478; margin-left:auto; font-size:0.8rem;" id="totalCount">Total: 0 keys</span>
        </div>
    </div>

    <div class="card" style="padding: 10px 0 0 0;">
        <div style="padding: 0 20px 10px 20px; display:flex; justify-content:space-between; align-items:center;">
            <h2 style="margin:0;">📋 Keys cadastradas</h2>
            <button class="btn btn-sm" id="refreshBtn" style="background:transparent; border:1px solid #3a4456;">🔄 Atualizar</button>
        </div>
        <div class="table-wrapper">
            <table>
                <thead>
                    <tr>
                        <th>Nome</th>
                        <th>Chave</th>
                        <th>Dias</th>
                        <th>Criada em</th>
                        <th>Válida até</th>
                        <th>Status</th>
                        <th style="text-align:center;">Ações</th>
                    </tr>
                </thead>
                <tbody id="keysTableBody">
                    <tr><td colspan="7" class="empty">Nenhuma key cadastrada.</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</div>

<script>
    (function() {
        const STORAGE_KEY = 'keyManagerData'; // não usado mais, usamos a API

        let keys = [];

        // DOM refs
        const keyNameInput = document.getElementById('keyName');
        const keyDaysInput = document.getElementById('keyDays');
        const keyValueInput = document.getElementById('keyValue');
        const addStatus = document.getElementById('addStatus');
        const tbody = document.getElementById('keysTableBody');
        const totalCount = document.getElementById('totalCount');
        const fileInput = document.getElementById('fileInput');

        // ========== FUNÇÕES AUX ==========
        function generateKey(length = 12) {
            const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
            let result = '';
            for (let i = 0; i < length; i++) {
                result += chars.charAt(Math.floor(Math.random() * chars.length));
            }
            return result;
        }

        function formatDate(isoString) {
            if (!isoString) return '-';
            const d = new Date(isoString);
            return d.toLocaleDateString('pt-BR') + ' ' + d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
        }

        function getExpirationDate(createdISO, days) {
            const d = new Date(createdISO);
            d.setDate(d.getDate() + days);
            return d.toISOString();
        }

        function isExpired(expirationISO) {
            return new Date(expirationISO) < new Date();
        }

        // ========== API CALLS ==========
        async function listarKeys() {
            try {
                const resp = await fetch('/api/keys');
                if (!resp.ok) throw new Error('Erro ao listar');
                keys = await resp.json();
                renderTable();
            } catch (err) {
                alert('Erro ao carregar keys: ' + err.message);
            }
        }

        async function adicionarKey(nome, chave, dias) {
            try {
                const resp = await fetch('/api/keys', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ nome, chave, dias })
                });
                const data = await resp.json();
                if (resp.ok) {
                    addStatus.textContent = '✅ Key adicionada com sucesso!';
                    addStatus.style.color = '#b0f0d0';
                    listarKeys();
                    return true;
                } else {
                    addStatus.textContent = '❌ ' + (data.erro || 'Erro ao adicionar');
                    addStatus.style.color = '#f8b0b0';
                    return false;
                }
            } catch (err) {
                addStatus.textContent = '❌ Erro de conexão: ' + err.message;
                addStatus.style.color = '#f8b0b0';
                return false;
            }
        }

        async function removerKey(chave) {
            try {
                const resp = await fetch('/api/keys/' + encodeURIComponent(chave), { method: 'DELETE' });
                const data = await resp.json();
                if (resp.ok) {
                    listarKeys();
                } else {
                    alert('Erro ao remover: ' + (data.erro || 'desconhecido'));
                }
            } catch (err) {
                alert('Erro de conexão: ' + err.message);
            }
        }

        async function limparTodas() {
            if (!confirm('Tem certeza que deseja remover TODAS as keys?')) return;
            // Remover uma por uma
            for (let k of keys) {
                await removerKey(k.chave);
            }
            listarKeys();
        }

        // ========== RENDER ==========
        function renderTable() {
            if (keys.length === 0) {
                tbody.innerHTML = '<tr><td colspan="7" class="empty">Nenhuma key cadastrada.</td></tr>';
                totalCount.textContent = 'Total: 0 keys';
                return;
            }

            let html = '';
            keys.forEach((key, index) => {
                const expISO = getExpirationDate(key.criadoEm, key.dias);
                const expired = isExpired(expISO);
                const statusClass = expired ? 'badge-danger' : 'badge-success';
                const statusText = expired ? 'Expirada' : 'Válida';

                html += '<tr>';
                html += '<td><strong>' + escapeHtml(key.nome || 'Sem nome') + '</strong></td>';
                html += '<td class="key-cell">' + escapeHtml(key.chave) +
                    '<button class="copy-btn" data-key="' + escapeHtml(key.chave) + '">📋 Copiar</button></td>';
                html += '<td>' + key.dias + '</td>';
                html += '<td>' + formatDate(key.criadoEm) + '</td>';
                html += '<td>' + formatDate(expISO) + '</td>';
                html += '<td><span class="badge ' + statusClass + '">' + statusText + '</span></td>';
                html += '<td style="text-align:center;">';
                html += '<button class="btn btn-danger btn-sm delete-btn" data-chave="' + escapeHtml(key.chave) + '">Excluir</button>';
                html += '</td>';
                html += '</tr>';
            });

            tbody.innerHTML = html;
            totalCount.textContent = 'Total: ' + keys.length + ' keys';

            // Copiar
            document.querySelectorAll('.copy-btn').forEach(btn => {
                btn.addEventListener('click', function() {
                    const key = this.getAttribute('data-key');
                    navigator.clipboard.writeText(key).then(() => {
                        this.textContent = '✅ Copiado!';
                        setTimeout(() => { this.textContent = '📋 Copiar'; }, 1500);
                    }).catch(() => alert('Não foi possível copiar.'));
                });
            });

            // Excluir
            document.querySelectorAll('.delete-btn').forEach(btn => {
                btn.addEventListener('click', function() {
                    const chave = this.getAttribute('data-chave');
                    if (confirm('Remover a key "' + chave + '"?')) {
                        removerKey(chave);
                    }
                });
            });
        }

        function escapeHtml(text) {
            if (!text) return '';
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        // ========== EVENTOS ==========
        document.getElementById('addKeyBtn').addEventListener('click', async function() {
            const nome = keyNameInput.value.trim() || 'Sem nome';
            const dias = parseInt(keyDaysInput.value, 10);
            if (isNaN(dias) || dias < 1) {
                addStatus.textContent = '❌ Dias deve ser um número positivo.';
                addStatus.style.color = '#f8b0b0';
                return;
            }
            let chave = keyValueInput.value.trim();
            if (!chave) {
                chave = generateKey(12);
                keyValueInput.value = chave;
            }
            const ok = await adicionarKey(nome, chave, dias);
            if (ok) {
                keyNameInput.value = '';
                keyValueInput.value = '';
                keyDaysInput.value = '30';
            }
        });

        document.getElementById('generateKeyBtn').addEventListener('click', function() {
            keyValueInput.value = generateKey(12);
        });

        document.getElementById('clearAllBtn').addEventListener('click', limparTodas);

        document.getElementById('exportBtn').addEventListener('click', function() {
            if (keys.length === 0) { alert('Nenhuma key para exportar.'); return; }
            const dataStr = JSON.stringify(keys, null, 2);
            const blob = new Blob([dataStr], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'keys_' + new Date().toISOString().slice(0,10) + '.json';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        });

        fileInput.addEventListener('change', function(e) {
            if (this.files && this.files.length > 0) {
                const file = this.files[0];
                const reader = new FileReader();
                reader.onload = async function(ev) {
                    try {
                        const imported = JSON.parse(ev.target.result);
                        if (!Array.isArray(imported)) {
                            alert('Arquivo inválido: não é uma lista.');
                            return;
                        }
                        if (!confirm('Isso irá SUBSTITUIR todas as keys atuais. Continuar?')) return;
                        // Envia cada key para o servidor
                        for (let item of imported) {
                            if (!item.chave || !item.dias) continue;
                            const nome = item.nome || 'Importado';
                            const dias = parseInt(item.dias, 10) || 30;
                            const chave = item.chave;
                            await adicionarKey(nome, chave, dias);
                        }
                        listarKeys();
                        alert('Importação concluída!');
                    } catch (err) {
                        alert('Erro ao ler JSON: ' + err.message);
                    }
                };
                reader.readAsText(file);
                this.value = '';
            }
        });

        document.getElementById('refreshBtn').addEventListener('click', listarKeys);

        // Enter para adicionar
        keyNameInput.addEventListener('keypress', (e) => { if (e.key === 'Enter') document.getElementById('addKeyBtn').click(); });
        keyDaysInput.addEventListener('keypress', (e) => { if (e.key === 'Enter') document.getElementById('addKeyBtn').click(); });
        keyValueInput.addEventListener('keypress', (e) => { if (e.key === 'Enter') document.getElementById('addKeyBtn').click(); });

        // ========== INIT ==========
        listarKeys();
    })();
</script>
</body>
</html>
    `);
});

// ========================================
// INICIA O SERVIDOR
// ========================================
app.listen(PORT, () => {
    console.log(`🚀 Servidor rodando em http://localhost:${PORT}`);
    console.log(`📁 Arquivo de keys: ${KEYS_FILE}`);
});