"""
Backend Chatbot IA - ConVive
Conecta con Supabase (via REST API) para usar datos reales

Requisitos:
    pip install fastapi uvicorn requests

Uso:
    python chatbot_backend_mock.py
    
La app Flutter se conecta desde: http://localhost:8000
"""

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
import random
import uuid
import requests
import json

# Configuración de Supabase (REST API)
SUPABASE_URL = "https://dfjlfxcjbsgsltzvjrqs.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmamxmeGNqYnNnc2x0endqcnFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDA0ODI0NTMsImV4cCI6MjAxNjA1ODQ1M30.w9AXQB3Y0IW_l1oFdCxnNL3-0p5Q_VKtSJFnuVJJ3vE"
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
    chat_text = ' '.join([msg.get('content', '').lower() for msg in request.chat_history])
    
    # Detectar tipo de búsqueda del mensaje actual
    is_roommate_search = any(word in user_message for word in ['compañero', 'compañera', 'roommate', 'habitacion', 'cuarto', 'compartir', 'convivir'])
    is_property_search = any(word in user_message for word in ['departamento', 'apartamento', 'casa', 'arrendar', 'alquilar', 'renta', 'alojamiento', 'vivienda'])
    
    # Si no se detecta en el mensaje actual, verificar en el historial
    if not is_roommate_search and not is_property_search:
        is_roommate_search = 'compañero' in chat_text or 'roommate' in chat_text or 'habitacion' in chat_text
        is_property_search = 'departamento' in chat_text or 'apartamento' in chat_text or 'casa' in chat_text
    
    # ============ BÚSQUEDA DE COMPAÑERO (7+ ETAPAS) ============
    if is_roommate_search:
        
        if conversation_stage <= 1:
            # ETAPA 1: Tipo de búsqueda
            responses = [
                "✨ Búsqueda de Compañero Ideal\n\nPerfecto, vamos a encontrarte el compañero perfecto.\n\n📋 Primero, ¿cuál es tu PRIORIDAD?",
            ]
            options = ["Limpio y ordenado", "Tranquilo/a", "Social y amigable"]
        
        elif conversation_stage == 2:
            # ETAPA 2: Nivel de limpieza deseado
            responses = [
                "🧹 Excelente, anotado tu preferencia.\n\nAhora, sobre LIMPIEZA:\n\n📊 ¿Prefieres a alguien:",
            ]
            options = ["Extremadamente limpio (8-10)", "Normal, responsable (6-7)", "Flexible con hábitos"]
        
        elif conversation_stage == 3:
            # ETAPA 3: Preferencia de ruido/tranquilidad
            responses = [
                "✅ Entendido tu punto con limpieza.\n\nAhora, sobre RUIDO Y TRANQUILIDAD:\n\n🔊 ¿Cómo te llevas con ruido?",
            ]
            options = ["Muy tranquilo, casi silencio", "Normal, algo de ruido está bien", "Social, no me importa ruido"]
        
        elif conversation_stage == 4:
            # ETAPA 4: Frecuencia de fiestas
            responses = [
                "👍 Anotado tu preferencia.\n\nSobre FIESTAS Y REUNIONES:\n\n🎉 ¿Con qué frecuencia te gustaría?",
            ]
            options = ["Casi nunca (ocasionalmente)", "A veces (cada 2-3 semanas)", "Frecuente (semanalmente)"]
        
        elif conversation_stage == 5:
            # ETAPA 5: Frecuencia de invitados
            responses = [
                "🎊 Perfecto, anotado.\n\nSobre INVITADOS:\n\n👥 ¿Qué tan frecuentes?",
            ]
            options = ["Muy pocas visitas", "Visitas regulares", "Muchos amigos viniendo"]
        
        elif conversation_stage == 6:
            # ETAPA 6: Mascotas
            responses = [
                "🤝 Genial.\n\nEn cuanto a MASCOTAS:\n\n🐾 ¿Qué tan importante es esto?",
            ]
            options = ["No tolero mascotas", "Pequeñas mascotas está bien", "Amo mascotas (cualquier tamaño)"]
        
        elif conversation_stage == 7:
            # ETAPA 7: Zona/Ubicación
            responses = [
                "🏡 Excelente.\n\nÚltimo detalle, UBICACIÓN:\n\n📍 ¿Qué zona prefieres?",
            ]
            options = ["Centro (céntrico)", "Residencial (tranquilo)", "Cerca universidad", "Flexible"]
        
        elif conversation_stage >= 8:
            # ETAPA 8+: Confirmación y listo para recomendación
            responses = [
                "🎯 ¡Perfecto! Tengo TODA la información.\n\n✅ Analizando compatibilidad...\n\n🎉 ¿Listo para ver a los compañeros más compatibles contigo?",
            ]
            options = ["Sí, mostrar compañeros", "Revisar mis respuestas"]
    
    # ============ BÚSQUEDA DE DEPARTAMENTO (6+ ETAPAS) ============
    elif is_property_search:
        
        if conversation_stage <= 1:
            # ETAPA 1: Zona preferida
            responses = [
                "🏡 Búsqueda de Departamento\n\nVamos a encontrar tu hogar ideal.\n\n📍 Primero, ZONA PREFERIDA:",
            ]
            options = ["Centro (céntrico, comercial)", "Residencial (tranquilo)", "Cerca universidad", "Flexible"]
        
        elif conversation_stage == 2:
            # ETAPA 2: Número de habitaciones
            responses = [
                "✅ Zona anotada.\n\nAhora, HABITACIONES:\n\n🛏️ ¿Cuántas necesitas?",
            ]
            options = ["1 habitación", "2 habitaciones", "3 o más", "Flexible"]
        
        elif conversation_stage == 3:
            # ETAPA 3: Presupuesto
            responses = [
                "🏠 Anotado.\n\nPresupuesto MENSUAL:\n\n💰 ¿Cuánto puedes invertir?",
            ]
            options = ["$300-500", "$500-800", "$800-1200", "$1200+"]
        
        elif conversation_stage == 4:
            # ETAPA 4: Amoblado
            responses = [
                "💸 Presupuesto anotado.\n\nMUEBLES E ENSERES:\n\n🔑 ¿Cómo lo prefieres?",
            ]
            options = ["Totalmente amoblado", "Semi-amoblado", "Sin amueblar", "Flexible"]
        
        elif conversation_stage == 5:
            # ETAPA 5: Servicios/Amenidades
            responses = [
                "✅ Anotado.\n\nServicios IMPORTANTES:\n\n⚡ ¿Cuáles necesitas?",
            ]
            options = ["Servicios incluidos", "Estacionamiento", "Ascensor/Accesibilidad", "Seguridad/Portería"]
        
        elif conversation_stage >= 6:
            # ETAPA 6+: Confirmación
            responses = [
                "🎯 ¡Perfecto! Tengo todos los detalles.\n\n✅ Buscando departamentos...\n\n🏠 ¿Listo para ver las opciones?",
            ]
            options = ["Sí, mostrar departamentos", "Cambiar criterios"]
    
    # ============ RESPUESTA POR DEFECTO (Aún no se detectó búsqueda) ============
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
    """Obtener MÚLTIPLES recomendaciones + MENSAJE si sin hay coincidencias"""
    
    responses_text = ' '.join(request.responses).lower()
    matches = []
    is_roommate_search = False
    
    # 🔍 BÚSQUEDA DE COMPAÑERO DE CUARTO
    if any(word in responses_text for word in ['compañero', 'habitacion', 'cuarto', 'compartir', 'roommate']):
        is_roommate_search = True
        print(f"🔍 Buscando compañeros de cuarto para usuario {request.user_id}...")
        
        roommate_searches = get_real_roommate_searches(exclude_user_id=request.user_id)
        
        if roommate_searches:
            print(f"✅ Encontradas {len(roommate_searches)} búsquedas de roommate")
            scores = []
            
            for search in roommate_searches:
                candidate_habits = get_user_habits(search.get('user_id', ''))
                
                if candidate_habits:
                    candidate_habits_dict = {
                        'sleep_start': candidate_habits.get('sleep_start_hour', 23),
                        'sleep_end': candidate_habits.get('sleep_end_hour', 7),
                        'cleanliness': candidate_habits.get('cleanliness_level', 5),
                        'noise_level': candidate_habits.get('noise_tolerance', 5),
                        'party_frequency': candidate_habits.get('party_frequency', 5),
                        'guests_frequency': candidate_habits.get('guests_tolerance', 5),
                        'alcohol_frequency': candidate_habits.get('alcohol_frequency', 3),
                        'home_time': candidate_habits.get('time_at_home', 5),
                        'has_pets': candidate_habits.get('has_pets', False),
                        'pets_tolerance': candidate_habits.get('pets_tolerance', 5),
                    }
                    
                    compat_score = calculate_roommate_compatibility(request.habits, candidate_habits_dict)
                    
                    # Filtrar por puntuación mínima (70% compatible)
                    if compat_score >= 0.70:
                        profile = get_user_profile(search.get('user_id', ''))
                        
                        match = {
                            'id': search.get('user_id', 'unknown'),
                            'name': profile.get('full_name', 'Usuario') if profile else 'Usuario',
                            'avatar': profile.get('avatar_url', 'https://i.pravatar.cc/150?img=1') if profile else 'https://i.pravatar.cc/150?img=1',
                            'bio': search.get('description', 'Busca compañero de apartamento'),
                            'location': {
                                'lat': search.get('latitude', 10.4806),
                                'lng': search.get('longitude', -66.9036),
                                'address': search.get('address', 'Caracas'),
                            },
                            'compatibility': compat_score,
                            'score': compat_score,
                        }
                        scores.append(match)
            
            # Ordenar y tomar top 3
            matches = sorted(scores, key=lambda x: x['score'], reverse=True)[:3]
            print(f"📊 Coincidencias encontradas después de filtrar: {len(matches)}")
        else:
            print("⚠️ Sin búsquedas de roommate en BD")
    
    # 🏘️ BÚSQUEDA DE DEPARTAMENTO
    elif any(word in responses_text for word in ['departamento', 'apartamento', 'renta', 'arrendar', 'alquilar', 'alojamiento']):
        is_roommate_search = False
        print(f"🔍 Buscando departamentos para usuario {request.user_id}...")
        
        properties = get_real_properties(exclude_user_id=request.user_id)
        
        if properties:
            print(f"✅ Encontradas {len(properties)} propiedades")
            scores = []
            
            for prop in properties:
                property_features = {
                    'bedrooms': prop.get('bedrooms', 1),
                    'bathrooms': prop.get('bathrooms', 1),
                    'furnished': prop.get('is_furnished', False),
                    'pets_allowed': prop.get('allows_pets', False),
                    'cleanliness_level': prop.get('cleanliness_level', 5),
                    'price': prop.get('price_per_month', 0),
                }
                
                compat_score = calculate_property_compatibility(request.habits, property_features)
                
                # Filtrar por puntuación mínima (70% compatible)
                if compat_score >= 0.70:
                    owner_profile = get_user_profile(prop.get('user_id', ''))
                    
                    match = {
                        'id': prop.get('id', 'unknown'),
                        'name': owner_profile.get('full_name', 'Propietario') if owner_profile else 'Propietario',
                        'avatar': owner_profile.get('avatar_url', 'https://i.pravatar.cc/150?img=2') if owner_profile else 'https://i.pravatar.cc/150?img=2',
                        'bio': prop.get('title', 'Departamento disponible'),
                        'location': {
                            'lat': prop.get('latitude', 10.4806),
                            'lng': prop.get('longitude', -66.9036),
                            'address': prop.get('address', 'Caracas'),
                        },
                        'compatibility': compat_score,
                        'price': property_features['price'],
                        'score': compat_score,
                    }
                    scores.append(match)
            
            # Ordenar y tomar top 3
            matches = sorted(scores, key=lambda x: x['score'], reverse=True)[:3]
            print(f"📊 Propiedades encontradas después de filtrar: {len(matches)}")
        else:
            print("⚠️ Sin propiedades en BD")
    
    # 📭 SI NO HAY COINCIDENCIAS → MENSAJE ESPECIAL
    if not matches:
        print("❌ NO HAY COINCIDENCIAS QUE CUMPLAN LOS CRITERIOS")
        return JSONResponse({
            "id": str(uuid.uuid4()),
            "type": "assistant",
            "content": "😔 Lo siento, no hay nadie que cumpla con tus características y requisitos en este momento.\n\n¿Deseas intentar de nuevo con criterios más flexibles?",
            "options": ["Sí, intentar de nuevo", "No, gracias"],
            "timestamp": datetime.now().isoformat(),
        })
    
    # ✅ DEVOLVER MÚLTIPLES RECOMENDACIONES
    recommendations = []
    for match in matches:
        if is_roommate_search:
            msg = f"🎯 {match['name']} ({int(match.get('compatibility', 0.8)*100)}% compatible)\n{match['bio']}"
        else:
            price_text = f"${match.get('price', 0)}/mes" if match.get('price') else ""
            msg = f"🎯 {match['bio']} {price_text}\n({int(match.get('compatibility', 0.8)*100)}% compatible)"
        
        recommendations.append({
            "id": str(uuid.uuid4()),
            "type": "suggestion",
            "content": msg,
            "timestamp": datetime.now().isoformat(),
            "matched_user_id": match["id"],
            "matched_user_name": match["name"],
            "matched_user_avatar": match["avatar"],
            "compatibility_score": match.get("compatibility", 0.8),
            "property_location": match.get("location"),
        })
    
    return JSONResponse({
        "recommendations": recommendations,
        "count": len(recommendations),
        "type": "suggestions_batch",
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
        max_difference=100
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
    print("📍 URL: http://localhost:8000")
    print("📊 Docs: http://localhost:8000/docs")
    print("✅ Presiona Ctrl+C para detener")
    uvicorn.run(app, host="0.0.0.0", port=8000)
