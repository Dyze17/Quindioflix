@echo off
echo ==========================================
echo Iniciando QuindioFlix Backend y Frontend
echo ==========================================
echo Asegurate de haber configurado tu base de datos Oracle
echo.
cd backend
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
pause
