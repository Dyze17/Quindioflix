const API = '/api';

// ── NAVIGATION ─────────────────────────────────────────────
const pageTitles = {
    dashboard: ['Dashboard', 'Resumen del sistema en tiempo real'],
    contenido: ['Catálogo de Contenido', 'Títulos, series y episodios de la plataforma'],
    planes:    ['Planes de Suscripción', 'Configuración de niveles de acceso'],
    indices:   ['Gestión de Índices', 'Núcleo 4 · Optimización de consultas Oracle'],
    acceso:    ['Usuarios & Roles', 'Núcleo 5 · Administración de acceso a la base de datos'],
};

function navigateTo(target) {
    document.querySelectorAll('.nav-item').forEach(n => {
        n.classList.toggle('active', n.dataset.target === target);
    });
    document.querySelectorAll('.view-section').forEach(s => {
        s.classList.toggle('active', s.id === target);
    });
    const [title, sub] = pageTitles[target] || ['', ''];
    document.getElementById('page-title').textContent = title;
    document.getElementById('page-subtitle').textContent = sub;

    if (target === 'dashboard')  loadDashboard();
    if (target === 'contenido')  loadContenido();
    if (target === 'planes')     loadPlanes();
    if (target === 'indices')    loadIndices();
    if (target === 'acceso')     loadAcceso();
}

document.querySelectorAll('.nav-item').forEach(btn => {
    btn.addEventListener('click', () => navigateTo(btn.dataset.target));
});

// ── HELPERS ─────────────────────────────────────────────────
const fmt = v => new Intl.NumberFormat('es-CO',{style:'currency',currency:'COP',maximumFractionDigits:0}).format(v);
const pct = v => Math.max(4, Math.min(80, (v / 100) * 80));

// ── STATUS ──────────────────────────────────────────────────
async function checkStatus() {
    const dot  = document.getElementById('db-status-indicator');
    const txt  = document.getElementById('db-status-text');
    const bdot = document.getElementById('db-badge-dot');
    const btxt = document.getElementById('db-badge-text');
    try {
        const r = await fetch(`${API}/status`);
        const d = await r.json();
        const ok = d.status === 'success';
        dot.className  = 'status-dot ' + (ok ? 'online' : 'offline');
        bdot.className = 'badge-dot '  + (ok ? 'online' : 'offline');
        txt.textContent = ok ? 'Conectada' : 'Error BD';
        btxt.textContent = ok ? 'Oracle OK' : 'Error BD';
    } catch {
        dot.className  = 'status-dot offline';
        bdot.className = 'badge-dot offline';
        txt.textContent  = 'API Inactiva';
        btxt.textContent = 'Sin API';
    }
}

// ── DASHBOARD ───────────────────────────────────────────────
async function loadDashboard() {
    try {
        const r = await fetch(`${API}/metricas`);
        const d = await r.json();
        document.getElementById('metric-contenido').textContent       = d.total_contenido ?? '—';
        document.getElementById('metric-usuarios').textContent        = d.total_usuarios ?? '—';
        document.getElementById('metric-planes').textContent          = d.total_planes ?? '—';
        document.getElementById('metric-reproducciones').textContent  = d.total_reproducciones ?? '—';
    } catch { ['metric-contenido','metric-usuarios','metric-planes','metric-reproducciones'].forEach(id => document.getElementById(id).textContent = 'Error'); }

    // Mini indices list
    try {
        const r = await fetch(`${API}/indices`);
        const indices = await r.json();
        const el = document.getElementById('dash-indices-list');
        el.innerHTML = indices.slice(0,4).map(i => `
            <div class="dash-item">
                <span class="dash-item-left"><span class="dot"></span>${i.index_name}</span>
                <span class="dash-item-right">${i.table_name}</span>
            </div>`).join('');
    } catch {
        document.getElementById('dash-indices-list').innerHTML = '<div class="loading-row">No disponible</div>';
    }

    // Mini roles list
    const roles = [
        {name:'rol_admin',    desc:'CRUD total',          color:'#E50914'},
        {name:'rol_analista', desc:'Solo lectura',        color:'#3b82f6'},
        {name:'rol_soporte',  desc:'Usuarios y pagos',    color:'#f59e0b'},
        {name:'rol_contenido',desc:'Gestión catálogo',    color:'#a855f7'},
    ];
    document.getElementById('dash-roles-list').innerHTML = roles.map(r => `
        <div class="dash-item">
            <span class="dash-item-left">
                <span class="dot" style="background:${r.color}"></span>${r.name}
            </span>
            <span class="dash-item-right">${r.desc}</span>
        </div>`).join('');
}

// ── CONTENIDO ───────────────────────────────────────────────
let allContenido = [];
async function loadContenido() {
    const tbody = document.getElementById('contenido-tbody');
    tbody.innerHTML = '<tr><td colspan="7" class="text-center"><span class="spinner"></span> Cargando...</td></tr>';
    try {
        const r = await fetch(`${API}/contenido`);
        allContenido = await r.json();
        renderContenido(allContenido);
    } catch {
        tbody.innerHTML = '<tr><td colspan="7" class="text-center">Error al cargar datos.</td></tr>';
    }
}

function renderContenido(data) {
    const tbody = document.getElementById('contenido-tbody');
    if (!data.length) { tbody.innerHTML = '<tr><td colspan="7" class="text-center">Sin resultados.</td></tr>'; return; }
    tbody.innerHTML = data.map(c => {
        const estado = (c.estado_publicacion || 'ACTIVO').toLowerCase();
        const pop = c.popularidad ?? 0;
        return `<tr>
            <td><code style="font-family:'JetBrains Mono',monospace;font-size:.75rem;color:var(--text-muted)">#${c.id_contenido}</code></td>
            <td><strong>${c.titulo}</strong></td>
            <td>${c.anio_lanzamiento}</td>
            <td>${c.duracion_minutos ?? '—'} min</td>
            <td><span class="status-badge status-activo">${c.clasificacion_edad}</span></td>
            <td>
                <div class="pop-bar-wrap">
                    <div class="pop-bar" style="width:${pct(pop)}px"></div>
                    <span class="pop-val">${pop}</span>
                </div>
            </td>
            <td><span class="status-badge status-${estado}">${c.estado_publicacion}</span></td>
        </tr>`;
    }).join('');
}

document.addEventListener('DOMContentLoaded', () => {
    const searchInput = document.getElementById('search-contenido');
    if (searchInput) {
        searchInput.addEventListener('input', e => {
            const q = e.target.value.toLowerCase();
            renderContenido(allContenido.filter(c => c.titulo.toLowerCase().includes(q)));
        });
    }
});

// ── PLANES ──────────────────────────────────────────────────
async function loadPlanes() {
    const grid = document.getElementById('planes-grid');
    grid.innerHTML = '<div class="loading-center"><span class="spinner large"></span></div>';
    try {
        const r = await fetch(`${API}/planes`);
        const data = await r.json();
        if (!data.length) { grid.innerHTML = '<p>Sin planes configurados.</p>'; return; }
        grid.innerHTML = data.map(p => `
            <div class="plan-card glass-panel">
                <h4 class="plan-name">${p.nombre_plan}</h4>
                <p class="plan-price">${fmt(p.precio_mensual)}<small>/mes</small></p>
                <ul class="plan-features">
                    <li><span>Pantallas simultáneas</span><strong>${p.max_pantallas}</strong></li>
                    <li><span>Calidad de video</span><strong>${p.calidad_video}</strong></li>
                    <li><span>Descripción</span><span>${p.descripcion || '—'}</span></li>
                </ul>
                <button class="btn-primary">Editar Plan</button>
            </div>`).join('');
    } catch {
        grid.innerHTML = '<p style="color:var(--error)">Error al cargar planes.</p>';
    }
}

// ── ÍNDICES ─────────────────────────────────────────────────
const INDICES_DATA = [
    {
        name: 'IDX_REP_PERFIL_FECHA',
        table: 'REPRODUCCIONES',
        type: 'COMPOSITE',
        typeLabel: 'Compuesto · LOCAL',
        cols: ['ID_PERFIL', 'FECHA_HORA_INICIO DESC'],
        desc: 'Optimiza el historial de reproducción ("Seguir viendo") de cada perfil. Evita TABLE ACCESS FULL y permite PARTITION PRUNING.',
    },
    {
        name: 'IDX_USR_EMAIL_LOWER',
        table: 'USUARIOS',
        type: 'FUNCTIONAL',
        typeLabel: 'Funcional · UNIQUE',
        cols: ['LOWER(EMAIL)'],
        desc: 'Permite login case-insensitive con INDEX UNIQUE SCAN (costo ~1) en lugar de FULL TABLE SCAN sobre todos los usuarios.',
    },
    {
        name: 'IDX_CONT_CATEGORIA_ANIO',
        table: 'CONTENIDO',
        type: 'COMPOSITE',
        typeLabel: 'Compuesto',
        cols: ['ID_CATEGORIA', 'ANIO_LANZAMIENTO'],
        desc: 'Acelera la navegación del catálogo filtrando por categoría y rango de años. La consulta más frecuente de la plataforma.',
    },
    {
        name: 'IDX_PAGOS_USUARIO_ESTADO',
        table: 'PAGOS',
        type: 'COMPOSITE',
        typeLabel: 'Compuesto',
        cols: ['ID_USUARIO', 'ESTADO_PAGO'],
        desc: 'Optimiza la verificación de pagos EXITOSOS por usuario. Usado por SP_CAMBIAR_PLAN, triggers y reportes financieros.',
    },
];

async function loadIndices() {
    // Try to fetch live data, fall back to static
    let liveData = null;
    try {
        const r = await fetch(`${API}/indices`);
        if (r.ok) liveData = await r.json();
    } catch {}

    const grid = document.getElementById('indices-grid');
    grid.innerHTML = INDICES_DATA.map(idx => {
        const typeClass = idx.type === 'FUNCTIONAL' ? 'index-type--functional'
                        : idx.type === 'COMPOSITE'  ? 'index-type--composite'
                        : 'index-type--standard';
        return `<div class="index-card glass-panel">
            <div class="index-card-header">
                <span class="index-name">${idx.name}</span>
                <span class="index-type-badge ${typeClass}">${idx.typeLabel}</span>
            </div>
            <p class="index-table">${idx.table}</p>
            <p class="index-desc">${idx.desc}</p>
            <div class="index-columns">${idx.cols.map(c => `<span class="index-col">${c}</span>`).join('')}</div>
        </div>`;
    }).join('');
}

// ── USUARIOS & ROLES ────────────────────────────────────────
const ROLES_DATA = [
    {
        name: 'rol_admin',
        className: 'admin',
        user: 'qf_admin',
        desc: 'Administrador de la plataforma. CRUD completo en todas las tablas y procedimientos.',
        privs: ['SELECT','INSERT','UPDATE','DELETE','EXECUTE'],
        tables: '18 tablas + 2 MVs + 6 SPs',
        icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>`,
    },
    {
        name: 'rol_analista',
        className: 'analista',
        user: 'qf_analista',
        desc: 'Analista de datos y gerencia. Solo lectura sobre todas las tablas y acceso a reportes.',
        privs: ['SELECT','EXECUTE'],
        tables: '18 tablas + 2 MVs + 5 SPs',
        icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>`,
    },
    {
        name: 'rol_soporte',
        className: 'soporte',
        user: 'qf_soporte',
        desc: 'Soporte al cliente. Lectura de cuentas, gestión de pagos y cambio de plan.',
        privs: ['SELECT','INSERT','UPDATE','EXECUTE'],
        tables: '4 tablas + SP_CAMBIAR_PLAN',
        icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>`,
    },
    {
        name: 'rol_contenido',
        className: 'contenido',
        user: 'qf_contenido',
        desc: 'Gestor del catálogo. CRUD en contenido, temporadas, episodios y géneros.',
        privs: ['SELECT','INSERT','UPDATE','DELETE'],
        tables: '7 tablas + 1 MV',
        icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="23 7 16 12 23 17 23 7"/><rect x="1" y="5" width="15" height="14" rx="2"/></svg>`,
    },
];

const USUARIOS_DATA = [
    { user:'qf_admin',    rol:'rol_admin',    perfil:'perfil_estandar',    sesiones:3, idle:'30 min', pwd:'90 días' },
    { user:'qf_analista', rol:'rol_analista', perfil:'perfil_estandar',    sesiones:3, idle:'30 min', pwd:'90 días' },
    { user:'qf_soporte',  rol:'rol_soporte',  perfil:'perfil_restringido', sesiones:1, idle:'15 min', pwd:'60 días' },
    { user:'qf_contenido',rol:'rol_contenido',perfil:'perfil_estandar',    sesiones:3, idle:'30 min', pwd:'90 días' },
];

const DEMOS_DATA = [
    { num:1, title:'Soporte intenta DELETE en USUARIOS', ok:false,  desc:'ROL_SOPORTE no tiene privilegio DELETE en USUARIOS.', result:'ORA-01031: insufficient privileges' },
    { num:2, title:'Analista intenta INSERT en PAGOS',   ok:false,  desc:'ROL_ANALISTA no tiene privilegio INSERT en PAGOS.', result:'ORA-01031: insufficient privileges' },
    { num:3, title:'Contenido intenta SELECT en PAGOS',  ok:false,  desc:'ROL_CONTENIDO no tiene acceso a la tabla PAGOS.', result:'ORA-00942: table or view does not exist' },
    { num:4, title:'Soporte ejecuta SP_CAMBIAR_PLAN',    ok:true,   desc:'ROL_SOPORTE tiene EXECUTE en SP_CAMBIAR_PLAN.', result:'EXEC sp_cambiar_plan(1, 2) → ÉXITO' },
    { num:5, title:'Perfil limita sesiones a qf_soporte',ok:true,   desc:'perfil_restringido: SESSIONS_PER_USER = 1.', result:'Segunda sesión → ORA-02391: exceeded simultaneous SESSIONS_PER_USER limit' },
];

function loadAcceso() {
    // Roles grid
    document.getElementById('roles-grid').innerHTML = ROLES_DATA.map(r => `
        <div class="role-card glass-panel">
            <div class="role-card-header">
                <div class="role-avatar role-avatar--${r.className}">${r.icon}</div>
                <div>
                    <p class="role-name">${r.name}</p>
                    <p class="role-desc">${r.tables}</p>
                </div>
            </div>
            <div class="role-privs">${r.privs.map(p => `<span class="priv-tag priv-${p.toLowerCase()}">${p}</span>`).join('')}</div>
            <p class="role-desc" style="margin-bottom:.5rem">${r.desc}</p>
            <p class="role-user">Usuario: <strong>${r.user}</strong></p>
        </div>`).join('');

    // Usuarios oracle table
    document.getElementById('usuarios-oracle-tbody').innerHTML = USUARIOS_DATA.map(u => `
        <tr>
            <td><code style="font-family:'JetBrains Mono',monospace;font-size:.8rem">${u.user}</code></td>
            <td><code style="font-family:'JetBrains Mono',monospace;font-size:.8rem;color:var(--primary)">${u.rol}</code></td>
            <td>${u.perfil === 'perfil_estandar'
                ? '<span class="status-badge status-activo">perfil_estandar</span>'
                : '<span class="status-badge status-inactivo">perfil_restringido</span>'}</td>
            <td>${u.sesiones}</td>
            <td>${u.idle}</td>
            <td>${u.pwd}</td>
        </tr>`).join('');

    // Demos
    document.getElementById('demos-grid').innerHTML = DEMOS_DATA.map(d => `
        <div class="demo-card glass-panel">
            <div class="demo-header">
                <span class="demo-num">${d.num}</span>
                <span class="demo-title">${d.title}</span>
            </div>
            <p class="demo-desc">${d.desc}</p>
            <div class="demo-result ${d.ok ? 'demo-result--ok' : 'demo-result--fail'}">${d.result}</div>
        </div>`).join('');
}

// ── INIT ────────────────────────────────────────────────────
window.navigateTo = navigateTo;
checkStatus();
loadDashboard();
setInterval(checkStatus, 30000);
