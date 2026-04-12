.PHONY: web build clean help

# Variables
PORT := 3000
CHROME_TARGET := chrome

help:
	@echo "=== CONVIVE - Comandos útiles ==="
	@echo ""
	@echo "make web       - Ejecutar en http://localhost:3000 (Puerto FIJO)"
	@echo "make build     - Compilar la app web"
	@echo "make clean     - Limpiar build"
	@echo "make help      - Ver esta ayuda"
	@echo ""

web:
	@echo "🚀 Iniciando ConVive en http://localhost:$(PORT)..."
	flutter run -d $(CHROME_TARGET) --web-port=$(PORT)

build:
	@echo "🔨 Compilando app web..."
	flutter build web

clean:
	@echo "🧹 Limpiando build..."
	flutter clean

# Targets adicionales útiles
pub-get:
	@echo "📦 Obteniendo dependencias..."
	flutter pub get

pub-upgrade:
	@echo "⬆️  Actualizando dependencias..."
	flutter pub upgrade

pub-outdated:
	@echo "📊 Mostrando paquetes desactualizados..."
	flutter pub outdated

analyze:
	@echo "🔍 Analizando código..."
	flutter analyze

format:
	@echo "✨ Formateando código..."
	dart format lib/ --fix

test:
	@echo "🧪 Ejecutando tests..."
	flutter test
