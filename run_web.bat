@echo off
REM Script para ejecutar Flutter en puerto fijo 3000
REM Uso: Doble clic en este archivo o desde terminal: run_web.bat

echo.
echo ============================================
echo    🚀 CONVIVE - Flutter Web Server
echo ============================================
echo.
echo 🌐 Puerto: http://localhost:3000
echo 📱 Plataforma: Chrome (Web)
echo.
echo ⚠️  Este puerto será SIEMPRE el mismo
echo ✅ Reset de contraseña funcionará correctamente
echo.
echo ============================================
echo.

flutter run -d chrome --web-port=3000

pause
