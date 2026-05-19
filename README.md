<p align="center">
  <img src="https://img.shields.io/badge/Oracle-21c%20XE-F80000?style=for-the-badge&logo=oracle&logoColor=white" alt="Oracle 21c XE"/>
  <img src="https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python"/>
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI"/>
  <img src="https://img.shields.io/badge/JavaScript-ES6+-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black" alt="JavaScript"/>
</p>

<h1 align="center">QuindioFlix</h1>

<p align="center">
  <strong>Plataforma de streaming — Administración de Base de Datos Oracle</strong><br/>
  Proyecto académico · Bases de Datos II · Universidad del Quindío
</p>

<p align="center">
  <a href="#-descripción">Descripción</a> •
  <a href="#-arquitectura">Arquitectura</a> •
  <a href="#-modelo-relacional">Modelo Relacional</a> •
  <a href="#-scripts-sql">Scripts SQL</a> •
  <a href="#-backend-api">Backend API</a> •
  <a href="#-frontend-dashboard">Frontend Dashboard</a> •
  <a href="#-requisitos-previos">Requisitos</a> •
  <a href="#-instalación-y-ejecución">Instalación</a>
</p>

---

## 📋 Descripción

**QuindioFlix** es un sistema de gestión de base de datos para una plataforma de streaming ficticia, desarrollado como proyecto académico para la asignatura **Bases de Datos II**. El proyecto implementa un esquema relacional completo en **Oracle 21c Express Edition**, acompañado de una API RESTful en **FastAPI** y un panel de administración web moderno.

El sistema cubre los siguientes núcleos temáticos:

| Núcleo | Tema | Script |
|:------:|------|--------|
| 1 | Creación de tablas, restricciones y carga de datos | `01`, `02` |
| 2 | Vistas materializadas, tablespaces y consultas avanzadas | `03`, `03b` |
| 3 | PL/SQL: cursores, procedimientos, funciones, triggers | `04`, `04b` |
| 4 | Transacciones, concurrencia y control de bloqueos | `05`, `05b` |
| 5 | Índices y análisis de rendimiento (EXPLAIN PLAN) | `06` |
| 6 | Usuarios, roles, perfiles y administración de acceso | `07` |

---

## Arquitectura

```
┌──────────────────────────────────────────────────────────┐
│                    FRONTEND (HTML/CSS/JS)                 │
│              Panel de Administración QuindioFlix          │
│         http://localhost:8000                             │
├──────────────────────────────────────────────────────────┤
│                    BACKEND (FastAPI + Python)             │
│              API RESTful · Uvicorn · Puerto 8000         │
├──────────────────────────────────────────────────────────┤
│                    BASE DE DATOS (Oracle 21c XE)         │
│    17 tablas · 2 vistas materializadas · PL/SQL          │
│    4 índices optimizados · 4 roles · 4 usuarios Oracle   │
└──────────────────────────────────────────────────────────┘
```

---

## Modelo Relacional

El esquema contiene **17 tablas** organizadas en las siguientes áreas funcionales:

### Tablas Maestras
| Tabla | Descripción |
|-------|-------------|
| `planes` | Catálogo de planes de suscripción (Básico, Estándar, Premium) |
| `departamentos` | Departamentos internos de la compañía |
| `empleados` | Empleados organizados jerárquicamente por departamento |
| `categorias` | Categorías del catálogo (Película, Serie, Documental, etc.) |
| `generos` | Géneros del contenido multimedia |

### Gestión de Usuarios
| Tabla | Descripción |
|-------|-------------|
| `usuarios` | Cuentas de usuario con plan, estado y referidos |
| `perfiles` | Perfiles por usuario (adulto/infantil) |
| `roles_app` | Roles funcionales de la aplicación |
| `usuario_rol_app` | Asignación de roles a usuarios |

### Catálogo de Contenido
| Tabla | Descripción |
|-------|-------------|
| `contenido` | Catálogo general de títulos con popularidad y estado |
| `contenido_genero` | Relación N:M entre contenido y géneros |
| `temporadas` | Temporadas de series/podcasts |
| `episodios` | Episodios por temporada |
| `contenido_relacionado` | Relaciones entre contenidos (secuelas, remakes, etc.) |

### Actividad y Pagos
| Tabla | Descripción |
|-------|-------------|
| `pagos` | Historial de pagos con métodos colombianos (Nequi, Daviplata, PSE) |
| `reproducciones` | Eventos de reproducción (**particionada** por rango de fechas) |
| `calificaciones` | Valoraciones y reseñas de 1-5 estrellas |
| `favoritos` | Lista de favoritos por perfil |
| `reportes_contenido` | Sistema de reportes y moderación |

---

## Scripts SQL

Los scripts se encuentran en la carpeta `SQL/` y deben ejecutarse **en orden secuencial**:

### Script 01 — Creación de Tablas
```
SQL/01_create_tables_quindioflix.sql
```
- Creación de las 17 tablas con todas las restricciones (`PK`, `FK`, `UNIQUE`, `CHECK`)
- Tabla `reproducciones` con **particionamiento por rango** (`PARTITION BY RANGE`)
- Comentarios descriptivos en todas las tablas y columnas (`COMMENT ON`)

### Script 02 — Carga de Datos
```
SQL/02_insert_data_quindioflix.sql
```
- Datos de prueba realistas para todas las tablas
- Planes de suscripción, usuarios, contenido, reproducciones, pagos, etc.

### Script 03 — Vistas Materializadas y Consultas
```
SQL/03_nt1_quindioflix.sql
SQL/03b_tablespaces_reproducciones.sql
```
- **Vistas materializadas**: `mv_popularidad_contenido`, `mv_ingresos_mensuales`
- Tablespace dedicado para la tabla de reproducciones

### Script 04 — PL/SQL
```
SQL/04_nt2_plsql_quindioflix.sql
SQL/04b_verificacion.sql
```
Implementa los siguientes objetos PL/SQL:

| Tipo | Nombre | Función |
|------|--------|---------|
| **Cursor** | `cur_usuarios_morosos` | Reporte de usuarios con mora > 30 días |
| **Cursor** | `cur_popularidad_contenido` | Actualiza popularidad basada en reproducciones completas (≥90%) |
| **Procedimiento** | `sp_registrar_usuario` | Registro completo: usuario + perfil + primer pago |
| **Procedimiento** | `sp_cambiar_plan` | Cambio de plan con validación de perfiles |
| **Procedimiento** | `sp_reporte_consumo` | Reporte de consumo por perfil y categoría |
| **Función** | `fn_calcular_monto` | Cálculo de monto con descuentos por antigüedad y referidos |
| **Función** | `fn_contenido_recomendado` | Recomendación basada en géneros más reproducidos |
| **Trigger** | `trg_rep_cuenta_activa` | Bloquea reproducciones si la cuenta no está activa |
| **Trigger** | `trg_perf_max_plan` | Valida máximo de perfiles según el plan |
| **Trigger** | `trg_calif_avance_min` | Requiere avance mínimo para calificar |
| **Trigger** | `trg_pago_activa_cuenta` | Activa cuenta automáticamente al registrar pago exitoso |

**Manejo de excepciones** con códigos personalizados:
- `-20001`: Email duplicado
- `-20002`: Plan inválido
- `-20003`: Perfiles excedidos
- `-20004`: Cuenta inactiva
- `-20005`: Plan ya asignado

### Script 05 — Transacciones y Concurrencia
```
SQL/05_nt3_transacciones_quindioflix.sql
SQL/05b_verificacion.sql
```
- **Transacción 1**: Registro completo atómico (usuario + perfil + pago) → `COMMIT` / `ROLLBACK`
- **Transacción 2**: Renovación mensual en lote con `SAVEPOINT` por usuario
- **Transacción 3**: Eliminación en cascada respetando integridad referencial
- **Concurrencia**: Escenario documentado con `SELECT FOR UPDATE` / `NOWAIT`
- Documentación de los 5 estados transaccionales (Activa, Parcialmente Confirmada, Confirmada, Fallida, Abortada)

### Script 06 — Índices
```
SQL/06_nt4_indices_quindioflix.sql
```

| Índice | Tabla | Tipo | Justificación |
|--------|-------|------|---------------|
| `idx_rep_perfil_fecha` | `reproducciones` | Compuesto LOCAL | Historial "Seguir viendo" — elimina `FULL TABLE SCAN` |
| `idx_usr_email_lower` | `usuarios` | Funcional UNIQUE | Login case-insensitive — `INDEX UNIQUE SCAN` (costo ~1) |
| `idx_cont_categoria_anio` | `contenido` | Compuesto | Navegación del catálogo por categoría + año |
| `idx_pagos_usuario_estado` | `pagos` | Compuesto | Consultas de pagos exitosos por usuario |

- Análisis comparativo con `EXPLAIN PLAN` (antes vs. después)
- Estadísticas actualizadas con `DBMS_STATS`

### Script 07 — Usuarios, Roles y Perfiles
```
SQL/07_nt5_usuarios_roles_quindioflix.sql
```

| Rol | Usuario Oracle | Perfil | Acceso |
|-----|---------------|--------|--------|
| `ROL_ADMIN` | `qf_admin` | `perfil_estandar` | CRUD completo + administración de usuarios |
| `ROL_ANALISTA` | `qf_analista` | `perfil_estandar` | Solo lectura + reportes + vistas materializadas |
| `ROL_SOPORTE` | `qf_soporte` | `perfil_restringido` | Gestión de pagos + cambio de plan |
| `ROL_CONTENIDO` | `qf_contenido` | `perfil_estandar` | CRUD del catálogo + lectura de métricas |

**Perfiles Oracle (`PROFILE`)**:
- `perfil_estandar`: 3 sesiones, 8h conexión, 30 min inactividad, 5 intentos fallidos
- `perfil_restringido`: 1 sesión, 4h conexión, 15 min inactividad, 3 intentos fallidos

> **Nota:** El Script 07 debe ejecutarse como **DBA** (`SYS AS SYSDBA`) ya que crea usuarios, roles y perfiles Oracle.

---

## Backend API

API RESTful construida con **FastAPI** y el driver **python-oracledb** en modo Thin (no requiere Oracle Client instalado).

### Endpoints Disponibles

| Método | Ruta | Descripción |
|--------|------|-------------|
| `GET` | `/api/status` | Estado de conexión a Oracle |
| `GET` | `/api/metricas` | Conteo total de planes, usuarios, contenido y reproducciones |
| `GET` | `/api/planes` | Lista de planes de suscripción |
| `GET` | `/api/contenido` | Catálogo de contenido ordenado por popularidad |
| `GET` | `/api/indices` | Índices de QuindioFlix desde `user_indexes` |
| `GET` | `/api/roles` | Roles Oracle del sistema |
| `GET` | `/api/usuarios-oracle` | Usuarios Oracle de QuindioFlix |
| `GET` | `/` | Sirve el frontend estático |

### Configuración de Conexión

Variables de entorno (con valores por defecto):

```env
DB_USER=DHI
DB_PASSWORD=12345
DB_DSN=localhost:1521/ProyectoBD2
```

---

## Frontend Dashboard

Panel de administración SPA (Single Page Application) con diseño **glassmorphism**, tipografía **Inter** y navegación por secciones.

### Secciones

| Sección | Descripción |
|---------|-------------|
| **Dashboard** | Métricas en tiempo real (contenido, usuarios, planes, reproducciones), resumen de índices y roles |
| **Catálogo** | Tabla interactiva con búsqueda de contenido en vivo |
| **Planes** | Tarjetas visuales de cada plan de suscripción |
| **Índices** | Detalle de los 4 índices + comparación de rendimiento EXPLAIN PLAN (antes/después) |
| **Usuarios & Roles** | Roles Oracle, usuarios, perfiles de seguridad y demos de restricciones de acceso |

### Tecnologías Frontend
- **HTML5** semántico
- **CSS3** con variables, glassmorphism, gradientes y animaciones
- **JavaScript** vanilla (ES6+) — sin dependencias externas
- **Google Fonts**: Inter + JetBrains Mono
- Iconografía **SVG** inline

---

## Requisitos Previos

| Requisito | Versión Mínima |
|-----------|---------------|
| [Oracle Database 21c XE](https://www.oracle.com/database/technologies/xe-downloads.html) | 21c Express Edition |
| [Python](https://www.python.org/downloads/) | 3.10+ |
| [pip](https://pip.pypa.io/) | Incluido con Python |

### Dependencias Python

```
fastapi
uvicorn[standard]
oracledb
```

---

## Instalación y Ejecución

### 1. Clonar el repositorio

```bash
git clone https://github.com/Dyze17/Quindioflix.git
cd Quindioflix
```

### 2. Configurar la base de datos Oracle

Ejecutar los scripts SQL **en orden** usando SQL*Plus o SQL Developer conectado como el usuario del esquema:

```sql
-- Conectar al PDB o instancia correspondiente
@SQL/01_create_tables_quindioflix.sql
@SQL/02_insert_data_quindioflix.sql
@SQL/03_nt1_quindioflix.sql
@SQL/03b_tablespaces_reproducciones.sql
@SQL/04_nt2_plsql_quindioflix.sql
@SQL/05_nt3_transacciones_quindioflix.sql
@SQL/06_nt4_indices_quindioflix.sql

-- El Script 07 requiere privilegios DBA
-- Conectar como SYS AS SYSDBA antes de ejecutar:
@SQL/07_nt5_usuarios_roles_quindioflix.sql
```

### 3. Instalar dependencias Python

```bash
pip install fastapi uvicorn[standard] oracledb
```

### 4. Configurar la conexión (opcional)

Si tu base de datos usa credenciales diferentes, configura las variables de entorno:

```bash
# Windows (PowerShell)
$env:DB_USER = "tu_usuario"
$env:DB_PASSWORD = "tu_contraseña"
$env:DB_DSN = "localhost:1521/tu_servicio"
```

```bash
# Linux/macOS
export DB_USER=tu_usuario
export DB_PASSWORD=tu_contraseña
export DB_DSN=localhost:1521/tu_servicio
```

### 5. Ejecutar la aplicación

**Opción A** — Usar el script `run.bat` (Windows):

```bash
run.bat
```

**Opción B** — Ejecutar manualmente:

```bash
cd backend
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### 6. Abrir el panel de administración

Navegar a: **[http://localhost:8000](http://localhost:8000)**

---

## Estructura del Proyecto

```
QuindioFlix/
│
├── SQL/                                    # Scripts de base de datos
│   ├── 01_create_tables_quindioflix.sql     # DDL: tablas y restricciones
│   ├── 02_insert_data_quindioflix.sql       # DML: datos de prueba
│   ├── 03_nt1_quindioflix.sql              # Vistas materializadas
│   ├── 03b_tablespaces_reproducciones.sql  # Tablespace dedicado
│   ├── 04_nt2_plsql_quindioflix.sql        # PL/SQL completo
│   ├── 04b_verificacion.sql               # Verificación Núcleo 2
│   ├── 05_nt3_transacciones_quindioflix.sql # Transacciones y concurrencia
│   ├── 05b_verificacion.sql               # Verificación Núcleo 3
│   ├── 06_nt4_indices_quindioflix.sql      # Índices + EXPLAIN PLAN
│   └── 07_nt5_usuarios_roles_quindioflix.sql # Usuarios, roles y perfiles
│
├── backend/                                # API RESTful
│   ├── main.py                            # Endpoints FastAPI
│   └── database.py                        # Conexión Oracle (modo Thin)
│
├── frontend/                               # Panel de administración
│   ├── index.html                         # Estructura HTML5
│   ├── style.css                          # Estilos (glassmorphism, animaciones)
│   └── script.js                          # Lógica de navegación y consumo API
│
├── run.bat                                 # Script de inicio rápido (Windows)
└── README.md                              # Este archivo
```

---

## Tecnologías Utilizadas

<table>
  <tr>
    <td align="center"><strong>Base de Datos</strong></td>
    <td>Oracle Database 21c Express Edition</td>
  </tr>
  <tr>
    <td align="center"><strong>Lenguaje BD</strong></td>
    <td>SQL · PL/SQL</td>
  </tr>
  <tr>
    <td align="center"><strong>Backend</strong></td>
    <td>Python · FastAPI · Uvicorn · python-oracledb</td>
  </tr>
  <tr>
    <td align="center"><strong>Frontend</strong></td>
    <td>HTML5 · CSS3 · JavaScript (ES6+)</td>
  </tr>
  <tr>
    <td align="center"><strong>Driver Oracle</strong></td>
    <td>python-oracledb (modo Thin — sin Oracle Client)</td>
  </tr>
</table>

---

## Licencia

Este proyecto fue desarrollado con fines **exclusivamente académicos** para la asignatura de Bases de Datos II de la Universidad del Quindío.

---

<p align="center">
  <sub>Hecho en Armenia, Quindío — 2026</sub>
</p>
