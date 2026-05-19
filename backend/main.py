from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
import os
import database as db

app = FastAPI(title="QuindioFlix API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)

@app.get("/api/status")
def get_status():
    conn = db.get_connection()
    if conn:
        conn.close()
        return {"status": "success", "message": "Conectado a Oracle exitosamente"}
    return {"status": "error", "message": "Error al conectar a Oracle"}

@app.get("/api/planes")
def get_planes():
    result = db.fetch_all(
        "SELECT id_plan, nombre_plan, precio_mensual, max_pantallas, calidad_video, descripcion FROM planes ORDER BY precio_mensual"
    )
    if isinstance(result, dict) and "error" in result:
        raise HTTPException(status_code=500, detail=result["error"])
    return result

@app.get("/api/contenido")
def get_contenido():
    result = db.fetch_all("""
        SELECT id_contenido, titulo, anio_lanzamiento, duracion_minutos,
               clasificacion_edad, popularidad, estado_publicacion
        FROM contenido ORDER BY popularidad DESC NULLS LAST
    """)
    if isinstance(result, dict) and "error" in result:
        raise HTTPException(status_code=500, detail=result["error"])
    return result

@app.get("/api/metricas")
def get_metricas():
    def count(table):
        r = db.fetch_all(f"SELECT COUNT(*) AS total FROM {table}")
        return r[0]["total"] if not isinstance(r, dict) and r else 0
    return {
        "total_planes":         count("planes"),
        "total_usuarios":       count("usuarios"),
        "total_contenido":      count("contenido"),
        "total_reproducciones": count("reproducciones"),
    }

@app.get("/api/indices")
def get_indices():
    """Devuelve los índices de QuindioFlix desde user_indexes."""
    result = db.fetch_all("""
        SELECT ui.index_name, ui.table_name, ui.index_type,
               ui.uniqueness, ui.status, ui.partitioned
        FROM user_indexes ui
        WHERE ui.index_name IN (
            'IDX_REP_PERFIL_FECHA',
            'IDX_USR_EMAIL_LOWER',
            'IDX_CONT_CATEGORIA_ANIO',
            'IDX_PAGOS_USUARIO_ESTADO'
        )
        ORDER BY ui.table_name, ui.index_name
    """)
    if isinstance(result, dict) and "error" in result:
        raise HTTPException(status_code=500, detail=result["error"])
    return result

@app.get("/api/roles")
def get_roles():
    """Devuelve los roles Oracle de QuindioFlix desde dba_roles (requiere privilegio SELECT ANY DICTIONARY o DBA)."""
    result = db.fetch_all("""
        SELECT role, role_id, password_required, authentication_type
        FROM dba_roles
        WHERE role IN ('ROL_ADMIN','ROL_ANALISTA','ROL_SOPORTE','ROL_CONTENIDO')
        ORDER BY role
    """)
    if isinstance(result, dict) and "error" in result:
        # Fallback: retornar lista estática si el usuario no tiene acceso a dba_roles
        return [
            {"role": "ROL_ADMIN",     "description": "Administrador completo"},
            {"role": "ROL_ANALISTA",  "description": "Solo lectura + reportes"},
            {"role": "ROL_SOPORTE",   "description": "Gestión de cuentas y pagos"},
            {"role": "ROL_CONTENIDO", "description": "Gestión del catálogo"},
        ]
    return result

@app.get("/api/usuarios-oracle")
def get_usuarios_oracle():
    """Devuelve los usuarios Oracle de QuindioFlix."""
    result = db.fetch_all("""
        SELECT username, profile, account_status, default_tablespace
        FROM dba_users
        WHERE username IN ('QF_ADMIN','QF_ANALISTA','QF_SOPORTE','QF_CONTENIDO')
        ORDER BY username
    """)
    if isinstance(result, dict) and "error" in result:
        raise HTTPException(status_code=500, detail=result["error"])
    return result

# ── Static files ────────────────────────────────────────────
frontend_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "frontend")
if os.path.exists(frontend_path):
    app.mount("/static", StaticFiles(directory=frontend_path), name="static")

    @app.get("/")
    def serve_frontend():
        return FileResponse(os.path.join(frontend_path, "index.html"))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
