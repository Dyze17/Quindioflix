import oracledb
import os
import json
from pathlib import Path

# Carga automática del archivo .env si existe (no requiere que esté presente)
try:
    from dotenv import load_dotenv
    # Busca .env en la carpeta backend/ (misma carpeta que este archivo)
    _env_path = Path(__file__).parent / ".env"
    load_dotenv(dotenv_path=_env_path)
except ImportError:
    pass  # python-dotenv es opcional; también funcionan variables de entorno del sistema

# Parámetros de conexión — configurables vía .env o variables de entorno del sistema
DB_USER     = os.environ.get("DB_USER",     "DHI")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "12345")
DB_DSN      = os.environ.get("DB_DSN",      "localhost:1521/XEPDB1")

# Configuración para que oracledb funcione en modo "Thin" (no necesita cliente de Oracle instalado)
oracledb.defaults.fetch_lobs = False


def get_connection():
    """
    Establece una conexión a la base de datos Oracle.
    """
    try:
        connection = oracledb.connect(
            user=DB_USER,
            password=DB_PASSWORD,
            dsn=DB_DSN
        )
        return connection
    except Exception as e:
        print(f"Error conectando a Oracle: {e}")
        return None

def fetch_all(query, params=None):
    """
    Ejecuta un query SELECT y devuelve todos los resultados como una lista de diccionarios.
    """
    if params is None:
        params = {}
    
    conn = get_connection()
    if not conn:
        return {"error": "No database connection"}
        
    try:
        cursor = conn.cursor()
        # Obtener nombres de columnas
        cursor.execute(query, params)
        columns = [col[0].lower() for col in cursor.description]
        
        # Obtener las filas
        rows = cursor.fetchall()
        
        # Mapear a diccionarios
        result = [dict(zip(columns, row)) for row in rows]
        return result
    except Exception as e:
        print(f"Error ejecutando query: {e}")
        return {"error": str(e)}
    finally:
        if 'cursor' in locals():
            cursor.close()
        if conn:
            conn.close()
