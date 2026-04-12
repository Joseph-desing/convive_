#!/bin/bash

# Script para ejecutar Flutter en puerto fijo 3000 (Mac/Linux)
# Uso: chmod +x run_web.sh && ./run_web.sh

echo ""
echo "============================================"
echo "    🚀 CONVIVE - Flutter Web Server"
echo "============================================"
echo ""
echo "🌐 Puerto: http://localhost:3000"
echo "📱 Plataforma: Chrome (Web)"
echo ""
echo "⚠️  Este puerto será SIEMPRE el mismo"
echo "✅ Reset de contraseña funcionará correctamente"
echo ""
echo "============================================"
echo ""

flutter run -d chrome --web-port=3000
