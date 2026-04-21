"""
Backend Chatbot IA - ConVive
Conecta con Supabase (via REST API) para usar datos reales

Requisitos:
    pip install fastapi uvicorn requests

Uso:
    python chatbot_backend_mock.py
    
La app Flutter se conecta desde: http://localhost:8000
"""

import sys
import os
sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
import random
import uuid
import requests
import json
import os
from dotenv import load_dotenv

load_dotenv()

# Configuración de Supabase (REST API)
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://xdpknfhbieejnqpjqpll.supabase.co")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "sb_publishable_N1HtO6hxmRLYb8V1kL0uoA_n3LKuHUv")
SUPABASE_API_URL = f"{SUPABASE_URL}/rest/v1"

# Headers para Supabase
SUPABASE_HEADERS = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    "Content-Type": "application/json",
}

app = FastAPI(title="ConVive Chatbot IA", version="1.0.0")

# CORS - Permitir requests desde la app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============ MODELOS ============

class ProcessMessageRequest(BaseModel):
    user_id: str
    message: str
    user_profile: dict
    user_habits: dict
    conversation_count: int = 0  # Número de mensajes en la conversación
    chat_history: list = []  # Historial de chat para mantener contexto

class RecommendationRequest(BaseModel):
    user_id: str
    responses: list[str]
    habits: dict  # Contiene: cleanliness, noise_level, party_frequency, guests_frequency, home_time, responsibility, pets_tolerance

class WelcomeRequest(BaseModel):
    user_name: str

# ============ SIMULACIÓN DE DATOS ============

SIMULATED_USERS = [
    {
        "id": "user_01",
        "name": "María García",
        "avatar": "https://i.pravatar.cc/150?img=1",
        "age": 24,
        "type": "roommate_seeker",
        "bio": "Estudiante de ingeniería, limpia y tranquila. Busco compañero/a para compartir apartamento.",
        "habits": {
            "cleanliness": 8,  # Muy limpia
            "noise_level": 2,  # Muy tranquila
            "party_frequency": 1,  # Casi no hace fiestas
            "guests_frequency": 2,  # Pocos invitados
            "home_time": 6,  # Mucho tiempo en casa
            "responsibility": 9,  # Muy responsable
            "pets_tolerance": 7,  # Tolera mascotas
        },
        "compatibility": 0.92,
        "location": {"lat": 10.4806, "lng": -66.9036, "address": "La Candelaria, Caracas"}
    },
    {
        "id": "user_02",
        "name": "Carlos López",
        "avatar": "https://i.pravatar.cc/150?img=2",
        "age": 29,
        "type": "property_owner",
        "bio": "Departamento amoblado 2 hab. Zona con vigilancia, permitidas mascotas.",
        "property_features": {
            "bedrooms": 2,
            "bathrooms": 1.5,
            "furnished": True,
            "pets_allowed": True,
            "cleanliness_level": 7,
            "common_areas": ["piscina", "gimnasio", "seguridad 24h"],
            "price": 600,
        },
        "compatibility": 0.85,
        "location": {"lat": 10.4889, "lng": -66.8637, "address": "Chacao, Caracas - $600/mes"}
    },
    {
        "id": "user_03",
        "name": "Ana Martínez",
        "avatar": "https://i.pravatar.cc/150?img=3",
        "age": 26,
        "type": "roommate_seeker",
        "bio": "Diseñadora gráfica, trabajo en casa. Necesito ambiente tranquilo para concentrarme.",
        "habits": {
            "cleanliness": 7,  # Limpia
            "noise_level": 2,  # Muy tranquila - IMPORTANTE
            "party_frequency": 1,  # No hace fiestas
            "guests_frequency": 1,  # Muy pocos invitados
            "home_time": 9,  # Casi siempre en casa
            "responsibility": 8,  # Responsable
            "pets_tolerance": 4,  # Baja tolerancia a mascotas
        },
        "compatibility": 0.88,
        "location": {"lat": 10.4969, "lng": -66.8640, "address": "Las Mercedes, Caracas"}
    },
    {
        "id": "user_04",
        "name": "Pedro Rodríguez",
        "avatar": "https://i.pravatar.cc/150?img=4",
        "age": 35,
        "type": "property_owner",
        "bio": "Apartamentos modernos en zona residencial. Permite mascotas.",
        "property_features": {
            "bedrooms": 3,
            "bathrooms": 2,
            "furnished": False,
            "pets_allowed": True,
            "cleanliness_level": 8,
            "common_areas": ["gimnasio", "salón social", "seguridad"],
            "price": 1200,
        },
        "compatibility": 0.80,
        "location": {"lat": 10.4830, "lng": -66.8719, "address": "Altamira, Caracas - $1200/mes"}
    },
]

# ============ FUNCIONES PARA OBTENER DATOS REALES DE SUPABASE (REST API) ============

def get_real_roommate_searches(exclude_user_id: str = None):
    """Obtener búsquedas de compañero de cuarto activas desde Supabase"""
    try:
        url = f"{SUPABASE_API_URL}/roommate_searches?status=eq.active"
        if exclude_user_id:
            url += f"&user_id=neq.{exclude_user_id}"
        
        response = requests.get(url, headers=SUPABASE_HEADERS, timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Búsquedas de roommate obtenidas: {len(data)} resultados")
            return data
        else:
            print(f"⚠️ Error obteniendo búsquedas: {response.status_code}")
            return []
    except Exception as e:
        print(f"❌ Error en get_real_roommate_searches: {e}")
        return []

def get_real_properties(exclude_user_id: str = None):
    """Obtener propiedades disponibles desde Supabase"""
    try:
        url = f"{SUPABASE_API_URL}/properties?is_active=eq.true"
        if exclude_user_id:
            url += f"&user_id=neq.{exclude_user_id}"
        
        response = requests.get(url, headers=SUPABASE_HEADERS, timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Propiedades obtenidas: {len(data)} resultados")
            return data
        else:
            print(f"⚠️ Error obteniendo propiedades: {response.status_code}")
            return []
    except Exception as e:
        print(f"❌ Error en get_real_properties: {e}")
        return []

def get_user_habits(user_id: str):
    """Obtener hábitos reales del usuario desde Supabase"""
    try:
        url = f"{SUPABASE_API_URL}/habits?user_id=eq.{user_id}"
        response = requests.get(url, headers=SUPABASE_HEADERS, timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            if data:
                print(f"✅ Hábitos obtenidos para usuario {user_id}")
                return data[0]
        return None
    except Exception as e:
        print(f"❌ Error en get_user_habits: {e}")
        return None

def get_user_profile(user_id: str):
    """Obtener perfil del usuario desde Supabase"""
    try:
        url = f"{SUPABASE_API_URL}/profiles?user_id=eq.{user_id}"
        response = requests.get(url, headers=SUPABASE_HEADERS, timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            if data:
                print(f"✅ Perfil obtenido para usuario {user_id}")
                return data[0]
        return None
    except Exception as e:
        print(f"❌ Error en get_user_profile: {e}")
        return None

# ============ FALLBACK A DATOS SIMULADOS ============

@app.get("/")
async def root():
    """Health check"""
    return {
        "status": "ok",
        "service": "ConVive Chatbot IA Mock Backend",
        "version": "1.0.0"
    }

@app.post("/chatbot/welcome")
async def get_welcome_message(request: WelcomeRequest):
    """Obtener mensaje de bienvenida + primera pregunta con opciones"""
    welcome_messages = [
        f"¡Hola {request.user_name}! 👋 Soy tu asistente de ConVive. Estoy aquí para ayudarte a encontrar el hogar ideal.",
    ]
    
    # Retornar bienvenida con la primera pregunta y opciones
    return JSONResponse({
        "id": str(uuid.uuid4()),
        "type": "assistant",
        "content": random.choice(welcome_messages) + "\n\n¿Estás buscando compañero/a de habitación o departamento?",
        "options": ["Compañero de cuarto", "Departamento"],
        "timestamp": datetime.now().isoformat(),
    })

@app.post("/chatbot/process")
async def process_user_message(request: ProcessMessageRequest):
    """Procesar mensaje del usuario con FLUJO CONVERSACIONAL EXTENDIDO + CONTEXTO"""
    
    user_message = request.message.lower()
    conversation_stage = request.conversation_count
    responses = []
    options = []
    
    # Analizar historial para detectar tipo de búsqueda ya seleccionado
    # Solo leer mensajes del USUARIO (no del asistente) para evitar falsos positivos
    user_history_text = ' '.join([
        msg.get('content', '').lower()
        for msg in request.chat_history
        if msg.get('type') == 'user'
    ])
    
    # Detectar tipo de búsqueda del mensaje actual
    is_roommate_search = any(word in user_message for word in ['compañero', 'compañera', 'roommate', 'habitacion', 'cuarto', 'compartir', 'convivir'])
    is_property_search = any(word in user_message for word in ['departamento', 'apartamento', 'casa', 'arrendar', 'alquilar', 'renta', 'alojamiento', 'vivienda'])
    
    # Si no se detecta en el mensaje actual, verificar en el historial de USER
    if not is_roommate_search and not is_property_search:
        is_roommate_search = 'compañero' in user_history_text or 'roommate' in user_history_text or 'habitacion' in user_history_text
        is_property_search = 'departamento' in user_history_text or 'apartamento' in user_history_text or 'casa' in user_history_text
    
    # ============ BÚSQUEDA DE COMPAÑERO (9 ETAPAS) ============
    if is_roommate_search:
        
        if conversation_stage <= 1:
            # ETAPA 1: Prioridad principal
            responses = [
                "✨ **Búsqueda de Compañero Ideal**\n\nPerfecto, vamos a encontrarte el compañero ideal paso a paso.\n\n📋 Lo primero: ¿cuál es tu PRIORIDAD al convivir?",
            ]
            options = ["🧹 Limpio y ordenado", "🤫 Tranquilo/silencioso", "🎉 Social y amigable"]
        
        elif conversation_stage == 2:
            # ETAPA 2: Nivel de limpieza
            responses = [
                "🧹 Anotado.\n\nSobre **LIMPIEZA Y ORDEN**:\n\n📊 ¿Qué nivel de limpieza esperas?",
            ]
            options = ["⭐⭐⭐ Impecable siempre (9-10)", "⭐⭐ Normal y responsable (6-8)", "⭐ Flexible, no me exijo (1-5)"]
        
        elif conversation_stage == 3:
            # ETAPA 3: Ruido
            responses = [
                "✅ Entendido.\n\nSobre **RUIDO Y AMBIENTE**:\n\n🔊 ¿Cómo prefieres el ambiente en casa?",
            ]
            options = ["🔇 Muy tranquilo (casi silencio)", "🔉 Normal (algo de ruido está bien)", "🔊 Animado (no me molesta el ruido)"]
        
        elif conversation_stage == 4:
            # ETAPA 4: Fiestas
            responses = [
                "👌 Perfecto.\n\nSobre **FIESTAS Y REUNIONES**:\n\n🎊 ¿Con qué frecuencia?",
            ]
            options = ["🚫 Nunca o casi nunca", "📅 Ocasionalmente (1 vez/mes)", "🎉 Frecuente (cada semana)"]
        
        elif conversation_stage == 5:
            # ETAPA 5: Invitados
            responses = [
                "✔️ Anotado.\n\nSobre **VISITAS E INVITADOS**:\n\n👥 ¿Cuántas visitas esperas en casa?",
            ]
            options = ["👤 Muy pocas (casi nadie)", "👥 Regulares (amigos/familia)", "👨‍👩‍👧‍👦 Muchas (casa muy concurrida)"]
        
        elif conversation_stage == 6:
            # ETAPA 6: Horarios
            responses = [
                "🗓️ Genial.\n\nSobre **HORARIOS DE VIDA**:\n\n⏰ ¿Cuál describe mejor tu rutina?",
            ]
            options = ["🌅 Madrugador (duermo temprano)", "🌙 Trasnochador (duermo tarde)", "🕐 Horario flexible / irregular"]
        
        elif conversation_stage == 7:
            # ETAPA 7: Mascotas
            responses = [
                "⏱️ Anotado tu horario.\n\nSobre **MASCOTAS**:\n\n🐾 ¿Qué tan cómodo/a te sientes?",
            ]
            options = ["❌ No tolero mascotas", "🐱 Solo mascotas pequeñas", "🐕 Cualquier mascota, las amo"]
        
        elif conversation_stage == 8:
            # ETAPA 8: Zona
            responses = [
                "🏠 Perfecto.\n\nCasi terminamos — **ZONA PREFERIDA**:\n\n📍 ¿Dónde buscas compañero/a?",
            ]
            options = ["🏙️ Centro (céntrico)", "🌳 Residencial (tranquilo)", "🎓 Cerca de universidad", "📌 Flexible"]
        
        elif conversation_stage >= 9:
            # ETAPA 9+: Confirmación
            responses = [
                "🎯 ¡Listo! Tengo **toda** la información necesaria.\n\n✅ Analizando perfiles compatibles...\n\n¿Quieres ver tus mejores coincidencias?",
            ]
            options = ["✅ Sí, mostrar compañeros", "🔄 Cambiar mis respuestas"]
    
    # ============ BÚSQUEDA DE DEPARTAMENTO (8 ETAPAS) ============
    elif is_property_search:
        
        if conversation_stage <= 1:
            # ETAPA 1: Zona
            responses = [
                "🏠 **Búsqueda de Departamento**\n\nVamos a encontrar tu hogar ideal paso a paso.\n\n📍 Primero: ¿en qué **ZONA** quieres vivir?",
            ]
            options = ["🏙️ Centro (céntrico, comercial)", "🌳 Residencial (tranquilo)", "🎓 Cerca universidad", "📌 Flexible"]
        
        elif conversation_stage == 2:
            # ETAPA 2: Tamaño
            responses = [
                "📍 Zona anotada.\n\n**TAMAÑO DEL ESPACIO**:\n\n📐 ¿Qué tanto espacio necesitas?",
            ]
            options = ["🏠 Pequeño (estudio/1 cuarto)", "🏡 Mediano (2 cuartos)", "🏘️ Grande (3+ cuartos)", "📌 Flexible"]
        
        elif conversation_stage == 3:
            # ETAPA 3: Número de habitaciones
            responses = [
                "📐 Tamaño anotado.\n\n**HABITACIONES** para ti:\n\n🛏️ ¿Cuántas habitaciones necesitas?",
            ]
            options = ["🛏️ 1 habitación (para mí solo/a)", "🛏️🛏️ 2 habitaciones", "🛏️🛏️🛏️ 3 o más habitaciones", "📌 Cualquiera"]
        
        elif conversation_stage == 4:
            # ETAPA 4: Presupuesto
            responses = [
                "🛏️ Perfecto.\n\n**PRESUPUESTO MENSUAL**:\n\n💰 ¿Cuánto puedes pagar al mes?",
            ]
            options = ["💵 Menos de $400", "💵💵 $400 - $700", "💵💵💵 $700 - $1200", "💰 Más de $1200"]
        
        elif conversation_stage == 5:
            # ETAPA 5: Amoblado
            responses = [
                "💰 Presupuesto anotado.\n\n**MOBILIARIO**:\n\n🪑 ¿Cómo lo prefieres?",
            ]
            options = ["✅ Totalmente amoblado", "🔧 Semi-amoblado", "📦 Sin amueblar (lo pongo yo)", "📌 Flexible"]
        
        elif conversation_stage == 6:
            # ETAPA 6: Pisos / planta
            responses = [
                "🪑 Anotado.\n\n**CARACTERÍSTICAS DEL EDIFICIO**:\n\n🏢 ¿Qué necesitas?",
            ]
            options = ["🔒 Seguridad / portería 24h", "🚗 Estacionamiento incluido", "🏋️ Gimnasio / áreas comunes", "🛗 Ascensor"]
        
        elif conversation_stage == 7:
            # ETAPA 7: Mascotas / políticas
            responses = [
                "🏢 Anotadas las amenidades.\n\n**POLÍTICA DE MASCOTAS**:\n\n🐾 ¿Tienes o planeas tener mascotas?",
            ]
            options = ["🐕 Sí, necesito que se permitan", "🚫 No tengo mascotas", "🤔 Quizás en el futuro"]
        
        elif conversation_stage >= 8:
            # ETAPA 8+: Confirmación
            responses = [
                "🎯 ¡Excelente! Tengo **toda** la información.\n\n✅ Buscando departamentos disponibles que se ajusten a ti...\n\n¿Listo para ver las opciones?",
            ]
            options = ["✅ Sí, mostrar departamentos", "🔄 Cambiar mis criterios"]
    
    # ============ RESPUESTA POR DEFECTO (Aún no se detectó búsqueda) ============
    else:
        is_greeting = any(w in user_message for w in ['hola', 'hi', 'hello', 'buenas', 'buen dia', 'buenos dias', 'buenas tardes', 'buenas noches', 'hey', 'saludos', 'ola'])
        if is_greeting:
            default_responses = [
                "¡Hola! 👋 ¿En qué te puedo ayudar hoy?\n\n¿Estás buscando compañero/a de habitación o un departamento?",
            ]
        else:
            default_responses = [
                "👂 Entendido.\n\n¿Buscas un compañero de cuarto o un departamento?",
            ]
        responses = default_responses
        options = ["Compañero de cuarto", "Departamento"]
    
    return JSONResponse({
        "id": str(uuid.uuid4()),
        "type": "assistant",
        "content": random.choice(responses),
        "options": options,
        "timestamp": datetime.now().isoformat(),
        "matched_user_id": None,
        "matched_user_name": None,
        "matched_user_avatar": None,
        "compatibility_score": None,
        "property_location": None,
    })

@app.post("/chatbot/recommend")
def get_compatibility_recommendation(request: RecommendationRequest):
    """Obtener recomendaciones usando DATOS REALES de Supabase"""

    responses_text = ' '.join(request.responses).lower()
    print(f"🔍 Búsqueda: {responses_text}")
    print(f"📋 Hábitos del usuario: {request.habits}")

    recommendations = []
    search_type = "compañero de cuarto"

    # Detectar tipo: departamento tiene prioridad porque "cuarto" puede aparecer
    # en etiquetas de opciones de apartamento ("estudio/1 cuarto")
    is_dept = any(w in responses_text for w in ['departamento', 'apartamento', 'renta', 'arrendar', 'alquilar', 'alojamiento', 'mostrar departamentos', 'si, mostrar departamentos'])
    is_roommate = (not is_dept) and any(w in responses_text for w in ['compañero', 'compañera', 'habitacion', 'compartir', 'roommate', 'mostrar compañeros'])

    # ─────────────────────────────────────────────────
    # 1. BÚSQUEDA DE COMPAÑERO DE CUARTO
    # ─────────────────────────────────────────────────
    if is_roommate:
        print("👤 Modo: COMPAÑEROS reales en Supabase")
        search_type = "compañero de cuarto"

        # Traer todos los hábitos y luego los perfiles por separado
        try:
            url_habits = f"{SUPABASE_API_URL}/habits?select=*"
            resp_h = requests.get(url_habits, headers=SUPABASE_HEADERS, timeout=5)
            rows = resp_h.json() if resp_h.status_code == 200 else []
        except Exception as e:
            print(f"❌ Error consultando hábitos: {e}")
            rows = []

        for row in rows:
            try:
                candidate_uid = row.get('user_id')
                if candidate_uid == request.user_id:
                    continue  # No compararse con uno mismo

                # Obtener perfil por separado
                profile = get_user_profile(candidate_uid) or {}
                name = profile.get('full_name') or 'Usuario'
                avatar = profile.get('profile_image_url')
                bio = profile.get('bio') or ''

                # Normalizar hábitos de Supabase al formato del cálculo
                # pet_tolerance en Supabase es boolean → convertir a escala 0-10
                pet_raw = row.get('pet_tolerance', False)
                pet_val = 10 if pet_raw is True else (0 if pet_raw is False else int(pet_raw))

                candidate_habits = {
                    'cleanliness': row.get('cleanliness_level', 5),
                    'noise_level': row.get('noise_tolerance', 5),
                    'party_frequency': row.get('party_frequency', 5),
                    'guests_frequency': row.get('guests_tolerance', 5),
                    'home_time': row.get('time_at_home', 5),
                    'responsibility': row.get('responsibility_level', 5),
                    'pets_tolerance': pet_val,
                }

                compat = calculate_roommate_compatibility(request.habits, candidate_habits)
                print(f"  {name}: {int(compat*100)}%")

                if compat >= 0.50:
                    recommendations.append({
                        "id": str(uuid.uuid4()),
                        "type": "suggestion",
                        "content": f"🎯 {name} ({int(compat*100)}% compatible)\n{bio}",
                        "timestamp": datetime.now().isoformat(),
                        "matched_user_id": candidate_uid,
                        "matched_user_name": name,
                        "matched_user_avatar": avatar,
                        "compatibility_score": compat,
                        "property_location": None,
                    })
            except Exception as e:
                print(f"❌ Error procesando candidato: {e}")

    # ─────────────────────────────────────────────────
    # 2. BÚSQUEDA DE DEPARTAMENTO
    # ─────────────────────────────────────────────────
    elif is_dept:
        print("🏠 Modo: PROPIEDADES reales en Supabase")
        search_type = "departamento"

        try:
            url = f"{SUPABASE_API_URL}/properties?is_active=eq.true"
            resp = requests.get(url, headers=SUPABASE_HEADERS, timeout=5)
            props = resp.json() if resp.status_code == 200 else []
        except Exception as e:
            print(f"❌ Error consultando propiedades: {e}")
            props = []

        for prop in props:
            try:
                owner_uid = prop.get('owner_id') or prop.get('user_id')
                if owner_uid == request.user_id:
                    continue

                profile = get_user_profile(owner_uid) if owner_uid else None
                name = profile.get('full_name', 'Propietario') if profile else 'Propietario'
                avatar = profile.get('profile_image_url') if profile else None
                description = prop.get('description') or prop.get('title') or ''
                address = prop.get('address', '')
                price = prop.get('price') or prop.get('rent_amount') or prop.get('budget')
                price_text = f" - ${int(price)}/mes" if price else ""

                # Calcular compatibilidad con hábitos del propietario (si existen)
                compat = 0.75  # Base si no hay hábitos
                if owner_uid:
                    habits_raw = get_user_habits(owner_uid)
                    if habits_raw:
                        pet_raw = habits_raw.get('pet_tolerance', False)
                        pet_val = 10 if pet_raw is True else (0 if pet_raw is False else int(pet_raw))
                        owner_habits = {
                            'cleanliness': habits_raw.get('cleanliness_level', 5),
                            'noise_level': habits_raw.get('noise_tolerance', 5),
                            'party_frequency': habits_raw.get('party_frequency', 5),
                            'guests_frequency': habits_raw.get('guests_tolerance', 5),
                            'home_time': habits_raw.get('time_at_home', 5),
                            'responsibility': habits_raw.get('responsibility_level', 5),
                            'pets_tolerance': pet_val,
                        }
                        compat = calculate_roommate_compatibility(request.habits, owner_habits)

                print(f"  {name} ({prop.get('title','?')}): {int(compat*100)}%")

                if compat >= 0.50:
                    recommendations.append({
                        "id": str(uuid.uuid4()),
                        "type": "suggestion",
                        "content": f"🏠 {description}{price_text}\n({int(compat*100)}% compatible)",
                        "timestamp": datetime.now().isoformat(),
                        "matched_user_id": owner_uid or prop.get('id'),
                        "matched_user_name": name,
                        "matched_user_avatar": avatar,
                        "compatibility_score": compat,
                        "property_location": {
                            "address": address,
                            "lat": prop.get('latitude'),
                            "lng": prop.get('longitude'),
                        } if address else None,
                    })
            except Exception as e:
                print(f"❌ Error procesando propiedad: {e}")

    # ─────────────────────────────────────────────────
    # 3. DEVOLVER RESULTADOS O MENSAJE "SIN COINCIDENCIAS"
    # ─────────────────────────────────────────────────
    if recommendations:
        recommendations = sorted(recommendations, key=lambda x: x['compatibility_score'], reverse=True)[:3]
        print(f"✅ {len(recommendations)} coincidencias encontradas")
        return JSONResponse({
            "type": "suggestions_batch",
            "recommendations": recommendations,
            "count": len(recommendations),
        })
    else:
        print(f"❌ Sin coincidencias para {search_type}")
        return JSONResponse({
            "id": str(uuid.uuid4()),
            "type": "assistant",
            "content": f"😔 Lo siento, no encontramos ningún {search_type} compatible para ti en este momento.\n\nPuedes intentarlo más tarde cuando haya más usuarios registrados en tu zona.",
            "options": ["Intentar de nuevo", "Cambiar preferencias"],
            "timestamp": datetime.now().isoformat(),
        })

@app.post("/compatibility-score")
async def calculate_compatibility_score(request: dict):
    """Calcular score de compatibilidad entre dos usuarios"""
    
    # Simulación: puntuación aleatoria entre 0.5 y 1.0
    score = round(random.uniform(0.5, 1.0), 2)
    
    return JSONResponse({
        "compatibility_score": score,
        "user_id_1": request.get("user_id_1"),
        "user_id_2": request.get("user_id_2"),
    })

@app.get("/health")
async def health_check():
    """Verificar estado del servicio"""
    return JSONResponse({
        "status": "healthy",
        "service": "Chatbot IA",
        "timestamp": datetime.now().isoformat(),
    })

def calculate_roommate_compatibility(user_habits: dict, candidate_habits: dict) -> float:
    """
    Calcula compatibilidad entre hábitos de dos personas usando la misma lógica
    que CompatibilityService en Dart.
    
    Factores:
    1. Horarios de sueño (15%)
    2. Nivel de limpieza (20%)
    3. Tolerancia al ruido (15%)
    4. Frecuencia de fiestas (15%)
    5. Tolerancia a invitados (10%)
    6. Mascotas (10%)
    7. Frecuencia de alcohol (5%)
    8. Tiempo en casa (10%)
    """
    total_score = 0.0
    
    # 1. HORARIOS DE SUEÑO (15%)
    sleep_score = _calculate_sleep_compatibility(
        user_habits.get('sleep_start', 23),
        user_habits.get('sleep_end', 7),
        candidate_habits.get('sleep_start', 23),
        candidate_habits.get('sleep_end', 7),
    )
    total_score += sleep_score * 0.15
    
    # 2. NIVEL DE LIMPIEZA (20%) - PESO MÁS ALTO
    cleanliness_score = _calculate_scale_difference(
        user_habits.get('cleanliness', 5),
        candidate_habits.get('cleanliness', 5),
        max_difference=10
    )
    total_score += cleanliness_score * 0.20
    
    # 3. TOLERANCIA AL RUIDO (15%)
    noise_score = _calculate_scale_difference(
        user_habits.get('noise_level', 5),
        candidate_habits.get('noise_level', 5),
        max_difference=10
    )
    total_score += noise_score * 0.15
    
    # 4. FRECUENCIA DE FIESTAS (15%)
    party_score = _calculate_scale_difference(
        user_habits.get('party_frequency', 5),
        candidate_habits.get('party_frequency', 5),
        max_difference=10
    )
    total_score += party_score * 0.15
    
    # 5. TOLERANCIA A INVITADOS (10%)
    guests_score = _calculate_scale_difference(
        user_habits.get('guests_frequency', 5),
        candidate_habits.get('guests_frequency', 5),
        max_difference=10
    )
    total_score += guests_score * 0.10
    
    # 6. MASCOTAS (10%)
    pets_score = _calculate_pet_compatibility(
        user_habits.get('has_pets', False),
        user_habits.get('pets_tolerance', 5),
        candidate_habits.get('has_pets', False),
        candidate_habits.get('pets_tolerance', 5),
    )
    total_score += pets_score * 0.10
    
    # 7. FRECUENCIA DE ALCOHOL (5%)
    alcohol_score = _calculate_scale_difference(
        user_habits.get('alcohol_frequency', 3),
        candidate_habits.get('alcohol_frequency', 3),
        max_difference=10
    )
    total_score += alcohol_score * 0.05
    
    # 8. TIEMPO EN CASA (10%)
    home_time_score = _calculate_scale_difference(
        user_habits.get('home_time', 5),
        candidate_habits.get('home_time', 5),
        max_difference=10
    )
    total_score += home_time_score * 0.10
    
    return min(max(total_score, 0.0), 1.0)

def _calculate_sleep_compatibility(user_start: int, user_end: int, other_start: int, other_end: int) -> float:
    """Calcula compatibilidad de horarios de sueño (0 a 1)"""
    # Calcular diferencia en hora de inicio
    start_diff = abs(user_start - other_start)
    if start_diff > 12:
        start_diff = 24 - start_diff
    
    # Calcular diferencia en hora de fin
    end_diff = abs(user_end - other_end)
    if end_diff > 12:
        end_diff = 24 - end_diff
    
    # Penalizar diferencias grandes (máximo 6 horas aceptable)
    avg_diff = (start_diff + end_diff) / 2.0
    return max(0, 1 - (avg_diff / 6.0))

def _calculate_scale_difference(user_value: int, other_value: int, max_difference: int = 10) -> float:
    """Calcula compatibilidad en escalas numéricas (0 a 1)"""
    difference = abs(user_value - other_value)
    return max(0, 1 - (difference / max_difference))

def _calculate_pet_compatibility(user_has_pets: bool, user_pet_tolerance: int, other_has_pets: bool, other_pet_tolerance: int) -> float:
    """Calcula compatibilidad de mascotas (0 a 1)"""
    # Si ninguno tiene mascotas
    if not user_has_pets and not other_has_pets:
        return 1.0
    
    # Si uno tiene mascotas
    if user_has_pets and not other_has_pets:
        return other_pet_tolerance / 10.0
    
    if not user_has_pets and other_has_pets:
        return user_pet_tolerance / 10.0
    
    # Si ambos tienen mascotas
    if user_has_pets and other_has_pets:
        return 1.0
    
    return 0.5

def calculate_property_compatibility(user_habits: dict, property_features: dict) -> float:
    """Calcular compatibilidad entre usuario y características del departamento"""
    score = 0.0
    factors = 0
    
    # 1. Mascotas: si el usuario tolera mascotas, el departamento debe permitirlas
    if user_habits.get('pets_tolerance', 0) >= 7:
        if property_features.get('pets_allowed', False):
            score += 1.0
        else:
            score += 0.3
        factors += 1
    else:
        score += 1.0
        factors += 1
    
    # 2. Limpieza: si el usuario es limpio, el departamento debe estar limpio
    user_cleanliness = user_habits.get('cleanliness', 5)
    property_cleanliness = property_features.get('cleanliness_level', 5)
    cleanliness_match = 1.0 - (abs(user_cleanliness - property_cleanliness) / 10.0)
    score += cleanliness_match
    factors += 1
    
    # 3. Amueblado: si el usuario tiene poco tiempo, preferir amueblado
    user_home_time = user_habits.get('home_time', 5)
    if user_home_time < 5:  # Poco tiempo en casa
        if property_features.get('furnished', False):
            score += 0.9
        else:
            score += 0.5
    else:
        score += 0.8
    factors += 1
    
    # Normalizar
    final_score = (score / factors) if factors > 0 else 0.5
    return min(max(final_score, 0.0), 1.0)

# ============ EJECUCIÓN ============

if __name__ == "__main__":
    import uvicorn
    print("🚀 Iniciando Chatbot IA Backend Mock...")
    print("📍 URL: http://localhost:8001")
    print("📊 Docs: http://localhost:8001/docs")
    print("✅ Presiona Ctrl+C para detener")
    uvicorn.run(app, host="0.0.0.0", port=8001)
