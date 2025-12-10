#!/bin/bash
echo "🛡️ Iniciando despliegue de Privacy Shield..."
echo "--------------------------------------------"

# Comprobar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no encontrado. Por favor instálalo primero."
    exit 1
fi

# Levantar contenedores
echo "🚀 Levantando contenedores..."
docker compose up -d

echo "✅ ¡Despliegue completado!"
echo "👉 Accede a: http://localhost:8080/admin"