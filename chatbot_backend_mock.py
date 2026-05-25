"""
Backend Chatbot IA - ConVive
==============================
Combina datos reales de Supabase con Groq IA para generar
recomendaciones de compañeros y departamentos con compatibilidad real.

Variables de entorno requeridas:
    SUPABASE_URL       → URL del proyecto Supabase
    SUPABASE_ANON_KEY  → Clave anónima (solo lectura)
    GROQ_API_KEY       → Clave de Groq para redactar respuestas
    PORT               → Puerto (default: 7860 para Hugging Face)

Uso local:
    pip install fastapi uvicorn requests python-dotenv
    python chatbot_backend_mock.py

Hugging Face:
    Subir como app.py o importar desde hf_app.py
"""

import sys
import os
import uuid
import random
import requests
import json
import re
from datetime import datetime
from math import sqrt

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

# ── Encoding UTF-8 para tildes ──────────────────────────────────────────────
sys.stdout.reconfigure(encoding="utf-8")
sys.stderr.reconfigure(encoding="utf-8")

load_dotenv()

# ── Configuración de Supabase ────────────────────────────────────────────────
SUPABASE_URL      = os.getenv("SUPABASE_URL",      "https://xdpknfhbieejnqpjqpll.supabase.co")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "sb_publishable_N1HtO6hxmRLYb8V1kL0uoA_n3LKuHUv")
SUPABASE_API_URL  = f"{SUPABASE_URL}/rest/v1"

SUPABASE_HEADERS = {
    "apikey":        SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    "Content-Type":  "application/json",
}

# ── Configuración de Groq ────────────────────────────────────────────────────
GROQ_API_KEY  = os.getenv("GROQ_API_KEY",  "")
GROQ_MODEL    = os.getenv("GROQ_MODEL",    "llama-3.1-8b-instant")
GROQ_BASE_URL = "https://api.groq.com/openai/v1"

# ── FastAPI ──────────────────────────────────────────────────────────────────
app = FastAPI(title="ConVive Chatbot IA", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # Flutter Web, APK, Hugging Face
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Modelos ──────────────────────────────────────────────────────────────────
class WelcomeRequest(BaseModel):
    user_name: str

class ProcessMessageRequest(BaseModel):
    user_id: str
    message: str
    user_profile: dict = {}
    user_habits: dict = {}
    conversation_count: int = 0
    chat_history: list = []

class RecommendationRequest(BaseModel):
    user_id: str
    responses: list
    habits: dict = {}

# ════════════════════════════════════════════════════════════════════════════
# SUPABASE — funciones de acceso a datos reales
# ════════════════════════════════════════════════════════════════════════════

def _sb_get(path: str, params: str = "") -> list:
    """GET genérico a Supabase REST API."""
    try:
        url = f"{SUPABASE_API_URL}/{path}?{params}" if params else f"{SUPABASE_API_URL}/{path}"
        resp = requests.get(url, headers=SUPABASE_HEADERS, timeout=6)
        if resp.status_code == 200:
            data = resp.json()
            return data if isinstance(data, list) else []
        print(f"⚠️  Supabase {path} → HTTP {resp.status_code}")
        return []
    except Exception as e:
        print(f"❌ Supabase error [{path}]: {e}")
        return []

def get_user_profile(user_id: str) -> dict:
    rows = _sb_get("profiles", f"user_id=eq.{user_id}&select=*")
    return rows[0] if rows else {}

def get_user_habits(user_id: str) -> dict:
    rows = _sb_get("habits", f"user_id=eq.{user_id}&select=*")
    return rows[0] if rows else {}

def get_all_habits(exclude_user_id: str) -> list:
    rows = _sb_get("habits", "select=*")
    return [r for r in rows if r.get("user_id") != exclude_user_id]

def get_available_properties(exclude_user_id: str) -> list:
    rows = _sb_get(
        "properties",
        "is_active=eq.true&is_rented=eq.false&is_approved=eq.true&select=*"
    )
    return [p for p in rows if p.get("owner_id") != exclude_user_id
                             and p.get("user_id")  != exclude_user_id]

# ════════════════════════════════════════════════════════════════════════════
# GROQ — generación de texto bonito
# ════════════════════════════════════════════════════════════════════════════

def groq_describe_roommate(name: str, bio: str, score: float, habits: dict) -> str:
    """Pide a Groq que redacte una descripción atractiva del candidato."""
    if not GROQ_API_KEY:
        return f"🎯 {name} — {int(score*100)}% compatible\n{bio}"
    try:
        prompt = f"""Eres el asistente de ConVive. Redacta en 2-3 oraciones por qué {name} es un buen compañero de cuarto.
Compatibilidad: {int(score*100)}%
Bio: {bio or 'No disponible'}
Hábitos (escala 1-10): limpieza={habits.get('cleanliness',5)}, ruido={habits.get('noise_level',5)}, fiestas={habits.get('party_frequency',5)}, invitados={habits.get('guests_frequency',5)}, tiempo_en_casa={habits.get('home_time',5)}, responsabilidad={habits.get('responsibility',5)}.
Escribe en español. Sé breve, cálido y motivador. No uses asteriscos ni markdown."""
        resp = requests.post(
            f"{GROQ_BASE_URL}/chat/completions",
            headers={"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"},
            json={"model": GROQ_MODEL, "messages": [{"role": "user", "content": prompt}],
                  "max_tokens": 150, "temperature": 0.7},
            timeout=10,
        )
        if resp.status_code == 200:
            return resp.json()["choices"][0]["message"]["content"].strip()
    except Exception as e:
        print(f"⚠️  Groq roommate description error: {e}")
    return f"🎯 {name} — {int(score*100)}% compatible\n{bio}"

def groq_describe_property(title: str, address: str, price, score: float, features: dict) -> str:
    """Pide a Groq que redacte una descripción atractiva de la propiedad."""
    if not GROQ_API_KEY:
        price_text = f" · ${int(price)}/mes" if price else ""
        return f"🏠 {title or address}{price_text}\n{int(score*100)}% compatible con tu perfil."
    try:
        price_text = f"${int(price)}/mes" if price else "precio no especificado"
        prompt = f"""Eres el asistente de ConVive. Redacta en 2-3 oraciones por qué este departamento es ideal para el usuario.
Título: {title or 'Departamento disponible'}
Dirección: {address or 'Sin dirección'}
Precio: {price_text}
Características: habitaciones={features.get('bedrooms','?')}, baños={features.get('bathrooms','?')}, amoblado={features.get('furnished',False)}, mascotas={features.get('pets_allowed',False)}, alícuota incluida={features.get('aliquot_included',False)}.
Compatibilidad: {int(score*100)}%
Escribe en español. Sé breve y entusiasta. No uses asteriscos ni markdown."""
        resp = requests.post(
            f"{GROQ_BASE_URL}/chat/completions",
            headers={"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"},
            json={"model": GROQ_MODEL, "messages": [{"role": "user", "content": prompt}],
                  "max_tokens": 150, "temperature": 0.7},
            timeout=10,
        )
        if resp.status_code == 200:
            return resp.json()["choices"][0]["message"]["content"].strip()
    except Exception as e:
        print(f"⚠️  Groq property description error: {e}")
    price_text = f" · ${int(price)}/mes" if price else ""
    return f"🏠 {title or address}{price_text}\n{int(score*100)}% compatible con tu perfil."

# ════════════════════════════════════════════════════════════════════════════
# COMPATIBILIDAD — algoritmo espejado del CompatibilityService de Dart
# ════════════════════════════════════════════════════════════════════════════

def _scale_diff(a: float, b: float, max_d: float = 10.0) -> float:
    return max(0.0, 1.0 - abs(a - b) / max_d)

def _sleep_compat(us: int, ue: int, os_: int, oe: int) -> float:
    sd = abs(us - os_); sd = 24 - sd if sd > 12 else sd
    ed = abs(ue - oe);  ed = 24 - ed if ed > 12 else ed
    return max(0.0, 1.0 - ((sd + ed) / 2.0) / 6.0)

def _pet_compat(u_has: bool, u_tol: float, o_has: bool, o_tol: float) -> float:
    if not u_has and not o_has: return 1.0
    if u_has  and not o_has:   return o_tol / 10.0
    if not u_has and o_has:    return u_tol / 10.0
    return 1.0

def _normalize_habits(raw: dict) -> dict:
    """Convierte hábitos de Supabase (snake_case) al formato interno."""
    pet_raw = raw.get("pet_tolerance", False)
    pet_val = 10.0 if pet_raw is True else (0.0 if pet_raw is False else float(pet_raw))
    return {
        "cleanliness":     float(raw.get("cleanliness_level",   5)),
        "noise_level":     float(raw.get("noise_tolerance",     5)),
        "party_frequency": float(raw.get("party_frequency",     5)),
        "guests_frequency":float(raw.get("guests_tolerance",    5)),
        "home_time":       float(raw.get("time_at_home",        5)),
        "responsibility":  float(raw.get("responsibility_level",5)),
        "pets_tolerance":  pet_val,
        "has_pets":        bool(raw.get("pets", False)),
        "sleep_start":     int(raw.get("sleep_schedule_start",  23)),
        "sleep_end":       int(raw.get("sleep_schedule_end",    7)),
        "alcohol_frequency":float(raw.get("alcohol_frequency",  3)),
    }

def calculate_roommate_compatibility(user_h: dict, candidate_h: dict) -> float:
    """
    Calcula compatibilidad entre hábitos de dos personas.
    Factores (suman 100%):
      sueño 15% · limpieza 20% · ruido 15% · fiestas 15%
      invitados 10% · mascotas 10% · alcohol 5% · tiempo casa 10%
    """
    total = 0.0
    total += _sleep_compat(
        user_h.get("sleep_start", 23), user_h.get("sleep_end", 7),
        candidate_h.get("sleep_start", 23), candidate_h.get("sleep_end", 7)
    ) * 0.15
    total += _scale_diff(user_h.get("cleanliness", 5),      candidate_h.get("cleanliness", 5))      * 0.20
    total += _scale_diff(user_h.get("noise_level", 5),      candidate_h.get("noise_level", 5))      * 0.15
    total += _scale_diff(user_h.get("party_frequency", 5),  candidate_h.get("party_frequency", 5))  * 0.15
    total += _scale_diff(user_h.get("guests_frequency", 5), candidate_h.get("guests_frequency", 5)) * 0.10
    total += _pet_compat(
        user_h.get("has_pets", False), user_h.get("pets_tolerance", 5),
        candidate_h.get("has_pets", False), candidate_h.get("pets_tolerance", 5)
    ) * 0.10
    total += _scale_diff(user_h.get("alcohol_frequency", 3), candidate_h.get("alcohol_frequency", 3)) * 0.05
    total += _scale_diff(user_h.get("home_time", 5),         candidate_h.get("home_time", 5),  max_d=100.0 if user_h.get("home_time", 5) > 10 else 10.0) * 0.10
    return round(min(max(total, 0.0), 1.0), 4)

def calculate_property_compatibility(user_h: dict, prop: dict, owner_h: dict = None) -> float:
    """
    Compatibilidad usuario ↔ departamento.
    Factores:
      hábitos del propietario 40% · precio ajustado 20%
      mascotas 15% · amoblado 10% · disponibilidad 15%
    """
    total = 0.0

    # 1. Hábitos del propietario (40%) — si no hay, neutral
    if owner_h:
        habit_score = calculate_roommate_compatibility(user_h, owner_h)
        total += habit_score * 0.40
    else:
        total += 0.70 * 0.40  # neutral

    # 2. Precio vs presupuesto del usuario (20%)
    price = prop.get("price") or prop.get("rent_amount") or prop.get("budget") or 0
    user_budget_str = user_h.get("budget", "")
    price_score = 0.75  # neutral si no hay dato
    if price and user_budget_str:
        budget_max = _parse_budget(str(user_budget_str))
        if budget_max and budget_max > 0:
            price_score = 1.0 if price <= budget_max else max(0.0, 1.0 - (price - budget_max) / budget_max)
    total += price_score * 0.20

    # 3. Mascotas (15%)
    user_tol = user_h.get("pets_tolerance", 5)
    pets_ok   = prop.get("pets_allowed", False)
    if user_tol >= 7:
        total += (1.0 if pets_ok else 0.2) * 0.15
    else:
        total += 1.0 * 0.15  # no necesita mascotas → siempre ok

    # 4. Amoblado (10%)
    furnished = prop.get("furnished", False) or prop.get("is_furnished", False)
    home_time = user_h.get("home_time", 5)
    furnished_score = (0.9 if furnished else 0.5) if home_time < 5 else 0.8
    total += furnished_score * 0.10

    # 5. Disponibilidad real (15%)
    avail = (
        prop.get("is_active", False) and
        not prop.get("is_rented", True) and
        prop.get("is_approved", False)
    )
    total += (1.0 if avail else 0.0) * 0.15

    return round(min(max(total, 0.0), 1.0), 4)

def _parse_budget(text: str) -> float:
    """Extrae número máximo de presupuesto del texto del usuario."""
    # "menos de $400" → 400; "$700 - $1200" → 1200; "más de $1200" → 9999
    text = text.lower().replace("$", "").replace(",", "")
    nums = list(map(float, re.findall(r"\d+", text)))
    if not nums:
        return 0.0
    if "más de" in text or "mas de" in text:
        return 9999.0
    return max(nums)

# ════════════════════════════════════════════════════════════════════════════
# ENDPOINTS
# ════════════════════════════════════════════════════════════════════════════

@app.get("/")
async def root():
    return {"status": "ok", "service": "ConVive Chatbot IA v2.0", "docs": "/docs"}

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "groq_configured": bool(GROQ_API_KEY),
        "supabase_url": SUPABASE_URL,
        "timestamp": datetime.now().isoformat(),
    }

# ── /chatbot/welcome ─────────────────────────────────────────────────────────
@app.post("/chatbot/welcome")
async def welcome(request: WelcomeRequest):
    """Mensaje de bienvenida personalizado con opciones iniciales."""
    name = request.user_name or "amigo/a"
    print(f"👋 Bienvenida para: {name}")
    return JSONResponse({
        "id": str(uuid.uuid4()),
        "type": "assistant",
        "content": (
            f"¡Hola {name}! 👋 Soy tu asistente de ConVive.\n\n"
            "Estoy aquí para ayudarte a encontrar el hogar ideal usando "
            "compatibilidad real basada en tus hábitos.\n\n"
            "¿Qué estás buscando hoy?"
        ),
        "options": ["Compañero de cuarto", "Departamento"],
        "timestamp": datetime.now().isoformat(),
    })

# ── /chatbot/process ─────────────────────────────────────────────────────────
@app.post("/chatbot/process")
async def process_message(request: ProcessMessageRequest):
    """Flujo conversacional guiado por etapas para roommate y departamento."""
    msg   = request.message.lower()
    stage = request.conversation_count

    # Detectar tipo desde mensaje actual O historial de usuario
    user_history = " ".join(
        m.get("content", "").lower()
        for m in request.chat_history
        if m.get("type") == "user"
    )
    combined = msg + " " + user_history

    is_dept     = any(w in combined for w in ["departamento","apartamento","arrendar","alquilar","renta","alojamiento","vivienda","mostrar departamentos"])
    is_roommate = (not is_dept) and any(w in combined for w in ["compañero","compañera","roommate","habitación","habitacion","cuarto","compartir","convivir","mostrar compañeros"])

    print(f"💬 stage={stage} | dept={is_dept} | roommate={is_roommate} | msg='{msg[:60]}'")

    # ── FLUJO COMPAÑERO (9 etapas) ───────────────────────────────────────────
    if is_roommate:
        stages = [
            (["✨ **Búsqueda de Compañero Ideal**\n\nPerfecto, encontremos el compañero ideal paso a paso.\n\n📋 Primera pregunta: ¿cuál es tu PRIORIDAD al convivir?"],
             ["🧹 Limpio y ordenado", "🤫 Tranquilo/silencioso", "🎉 Social y amigable"]),

            (["🧹 Anotado.\n\n**LIMPIEZA Y ORDEN**\n\n📊 ¿Qué nivel de limpieza esperas de tu compañero?"],
             ["⭐⭐⭐ Impecable siempre (9-10)", "⭐⭐ Normal y responsable (6-8)", "⭐ Flexible, no me exijo (1-5)"]),

            (["✅ Entendido.\n\n**RUIDO Y AMBIENTE**\n\n🔊 ¿Cómo prefieres el ambiente en casa?"],
             ["🔇 Muy tranquilo (silencio total)", "🔉 Normal (algo de ruido está bien)", "🔊 Animado (no me molesta)"]),

            (["👌 Perfecto.\n\n**FIESTAS Y REUNIONES**\n\n🎊 ¿Con qué frecuencia organizas fiestas o reuniones?"],
             ["🚫 Nunca o casi nunca", "📅 Ocasionalmente (1 vez/mes)", "🎉 Frecuente (cada semana)"]),

            (["✔️ Anotado.\n\n**VISITAS E INVITADOS**\n\n👥 ¿Cuántas visitas esperas recibir en casa?"],
             ["👤 Muy pocas (casi nadie)", "👥 Regulares (amigos/familia)", "👨‍👩‍👧‍👦 Muchas (casa concurrida)"]),

            (["🗓️ Genial.\n\n**HORARIOS DE VIDA**\n\n⏰ ¿Cuál describe mejor tu rutina?"],
             ["🌅 Madrugador (duermo temprano)", "🌙 Trasnochador (duermo tarde)", "🕐 Horario flexible"]),

            (["⏱️ Anotado tu horario.\n\n**MASCOTAS**\n\n🐾 ¿Qué tan cómodo/a te sientes con mascotas?"],
             ["❌ No tolero mascotas", "🐱 Solo mascotas pequeñas", "🐕 Las amo, cualquier mascota"]),

            (["🏠 Perfecto.\n\n**ZONA PREFERIDA**\n\n📍 ¿Dónde buscas compañero/a de cuarto?"],
             ["🏙️ Centro (céntrico)", "🌳 Residencial (tranquilo)", "🎓 Cerca de universidad", "📌 Flexible"]),

            (["🎯 ¡Listo! Tengo toda la información necesaria.\n\n✅ Analizando perfiles compatibles con tus hábitos...\n\n¿Quieres ver tus mejores coincidencias?"],
             ["✅ Sí, mostrar compañeros", "🔄 Cambiar mis respuestas"]),
        ]
        idx = min(stage - 1, len(stages) - 1) if stage > 0 else 0
        content, options = stages[idx]
        return JSONResponse({
            "id": str(uuid.uuid4()), "type": "assistant",
            "content": content[0], "options": options,
            "timestamp": datetime.now().isoformat(),
        })

    # ── FLUJO DEPARTAMENTO (8 etapas) ────────────────────────────────────────
    elif is_dept:
        stages = [
            (["🏠 **Búsqueda de Departamento**\n\nVamos a encontrar tu hogar ideal.\n\n📍 Primera pregunta: ¿en qué ZONA quieres vivir?"],
             ["🏙️ Centro (céntrico, comercial)", "🌳 Residencial (tranquilo)", "🎓 Cerca de universidad", "📌 Flexible"]),

            (["📍 Zona anotada.\n\n**TAMAÑO DEL ESPACIO**\n\n📐 ¿Qué tanto espacio necesitas?"],
             ["🏠 Pequeño (estudio/1 cuarto)", "🏡 Mediano (2 cuartos)", "🏘️ Grande (3+ cuartos)", "📌 Flexible"]),

            (["📐 Tamaño anotado.\n\n**HABITACIONES**\n\n🛏️ ¿Cuántas habitaciones necesitas?"],
             ["🛏️ 1 habitación", "🛏️🛏️ 2 habitaciones", "🛏️🛏️🛏️ 3 o más", "📌 Cualquiera"]),

            (["🛏️ Perfecto.\n\n**PRESUPUESTO MENSUAL**\n\n💰 ¿Cuánto puedes pagar al mes?"],
             ["💵 Menos de $400", "💵💵 $400 - $700", "💵💵💵 $700 - $1200", "💰 Más de $1200"]),

            (["💰 Presupuesto anotado.\n\n**MOBILIARIO**\n\n🪑 ¿Cómo prefieres el departamento?"],
             ["✅ Totalmente amoblado", "🔧 Semi-amoblado", "📦 Sin amueblar (lo pongo yo)", "📌 Flexible"]),

            (["🪑 Anotado.\n\n**CARACTERÍSTICAS DEL EDIFICIO**\n\n🏢 ¿Qué necesitas?"],
             ["🔒 Seguridad 24h", "🚗 Estacionamiento incluido", "🏋️ Áreas comunes / gimnasio", "🛗 Ascensor"]),

            (["🏢 Anotadas las amenidades.\n\n**POLÍTICA DE MASCOTAS**\n\n🐾 ¿Tienes o planeas tener mascotas?"],
             ["🐕 Sí, necesito que se permitan", "🚫 No tengo mascotas", "🤔 Quizás en el futuro"]),

            (["🎯 ¡Excelente! Tengo toda la información.\n\n✅ Buscando departamentos disponibles que se ajusten a ti...\n\n¿Listo para ver las opciones?"],
             ["✅ Sí, mostrar departamentos", "🔄 Cambiar mis criterios"]),
        ]
        idx = min(stage - 1, len(stages) - 1) if stage > 0 else 0
        content, options = stages[idx]
        return JSONResponse({
            "id": str(uuid.uuid4()), "type": "assistant",
            "content": content[0], "options": options,
            "timestamp": datetime.now().isoformat(),
        })

    # ── RESPUESTA GENÉRICA ────────────────────────────────────────────────────
    else:
        is_greeting = any(w in msg for w in ["hola","hi","hello","buenas","hey","saludos"])
        content = (
            "¡Hola! 👋 ¿En qué te puedo ayudar hoy?\n\n¿Buscas compañero/a de habitación o un departamento?"
            if is_greeting else
            "👂 Entendido. ¿Buscas un compañero de cuarto o un departamento?"
        )
        return JSONResponse({
            "id": str(uuid.uuid4()), "type": "assistant",
            "content": content,
            "options": ["Compañero de cuarto", "Departamento"],
            "timestamp": datetime.now().isoformat(),
        })

# ── /chatbot/recommend ───────────────────────────────────────────────────────
@app.post("/chatbot/recommend")
def recommend(request: RecommendationRequest):
    """
    Recomendaciones con datos reales de Supabase + Groq para redacción.
    Devuelve máximo 3 resultados ordenados por compatibilidad.
    """
    responses_text = " ".join(request.responses).lower()
    user_h         = request.habits  # hábitos del usuario desde Flutter

    print(f"\n{'='*60}")
    print(f"🔍 RECOMMEND | user_id={request.user_id}")
    print(f"📝 Respuestas: {responses_text[:120]}")
    print(f"📋 Hábitos: {user_h}")

    is_dept     = any(w in responses_text for w in [
        "departamento","apartamento","renta","arrendar","alquilar",
        "alojamiento","mostrar departamentos","sí, mostrar departamentos","si, mostrar departamentos"
    ])
    is_roommate = (not is_dept) and any(w in responses_text for w in [
        "compañero","compañera","habitación","habitacion","compartir",
        "roommate","mostrar compañeros","sí, mostrar compañeros","si, mostrar compañeros"
    ])

    print(f"🏷️  Tipo: {'DEPARTAMENTO' if is_dept else 'COMPAÑERO' if is_roommate else 'DESCONOCIDO'}")

    recommendations = []

    # ── COMPAÑERO DE CUARTO ──────────────────────────────────────────────────
    if is_roommate:
        all_habits = get_all_habits(request.user_id)
        print(f"👥 Candidatos con hábitos en Supabase: {len(all_habits)}")

        for row in all_habits:
            try:
                cuid = row.get("user_id")
                if not cuid:
                    continue
                candidate_h = _normalize_habits(row)
                score = calculate_roommate_compatibility(user_h, candidate_h)
                print(f"  → {cuid[:8]}... score={int(score*100)}% {'✅' if score >= 0.60 else '❌'}")

                if score < 0.60:
                    continue

                profile = get_user_profile(cuid)
                name    = profile.get("full_name") or profile.get("name") or "Usuario"
                avatar  = profile.get("profile_image_url") or profile.get("avatar_url")
                bio     = profile.get("bio") or ""

                # Ubicación del candidato (desde perfil o roommate_searches)
                prop_location = None
                lat = profile.get("latitude") or profile.get("lat")
                lng = profile.get("longitude") or profile.get("lng")
                if lat and lng:
                    prop_location = {
                        "lat":     float(lat),
                        "lng":     float(lng),
                        "address": profile.get("address") or profile.get("city") or "",
                    }

                # Groq redacta la descripción
                content = groq_describe_roommate(name, bio, score, candidate_h)

                recommendations.append({
                    "content":              content,
                    "matched_user_id":      cuid,
                    "matched_user_name":    name,
                    "matched_user_avatar":  avatar,
                    "compatibility_score":  score,
                    "property_location":    prop_location,
                })
            except Exception as e:
                print(f"  ⚠️ Error procesando candidato: {e}")

    # ── DEPARTAMENTO ─────────────────────────────────────────────────────────
    elif is_dept:
        props = get_available_properties(request.user_id)
        print(f"🏠 Propiedades disponibles en Supabase: {len(props)}")

        for prop in props:
            try:
                prop_id  = prop.get("id")
                owner_id = prop.get("owner_id") or prop.get("user_id")

                owner_h_raw = get_user_habits(owner_id) if owner_id else {}
                owner_h     = _normalize_habits(owner_h_raw) if owner_h_raw else {}

                score = calculate_property_compatibility(user_h, prop, owner_h or None)
                print(f"  → {prop.get('title','?')[:30]} | score={int(score*100)}% {'✅' if score >= 0.55 else '❌'}")

                if score < 0.55:
                    continue

                owner_profile = get_user_profile(owner_id) if owner_id else {}
                name   = owner_profile.get("full_name") or owner_profile.get("name") or "Propietario"
                avatar = (
                    prop.get("main_image_url") or
                    prop.get("image_url") or
                    owner_profile.get("profile_image_url")
                )
                title   = prop.get("title") or prop.get("name") or "Departamento"
                address = prop.get("address") or prop.get("location") or ""
                price   = prop.get("price") or prop.get("rent_amount") or prop.get("budget")

                features = {
                    "bedrooms":         prop.get("bedrooms"),
                    "bathrooms":        prop.get("bathrooms"),
                    "furnished":        prop.get("furnished") or prop.get("is_furnished", False),
                    "pets_allowed":     prop.get("pets_allowed", False),
                    "aliquot_included": prop.get("aliquot_included", False),
                }

                # Ubicación de la propiedad
                lat = prop.get("latitude") or prop.get("lat")
                lng = prop.get("longitude") or prop.get("lng")
                prop_location = None
                if lat and lng:
                    prop_location = {
                        "lat":     float(lat),
                        "lng":     float(lng),
                        "address": address,
                    }

                content = groq_describe_property(title, address, price, score, features)

                recommendations.append({
                    "content":              content,
                    "matched_user_id":      owner_id or prop_id,
                    "matched_user_name":    name,
                    "matched_user_avatar":  avatar,
                    "compatibility_score":  score,
                    "property_location":    prop_location,
                })
            except Exception as e:
                print(f"  ⚠️ Error procesando propiedad: {e}")

    # ── Ordenar y limitar ─────────────────────────────────────────────────────
    recommendations.sort(key=lambda x: x["compatibility_score"], reverse=True)
    top3 = recommendations[:3]

    print(f"\n✅ Top {len(top3)} recomendaciones devueltas")
    for r in top3:
        print(f"  • {r['matched_user_name']} → {int(r['compatibility_score']*100)}%")
    print(f"{'='*60}\n")

    if top3:
        return JSONResponse({
            "type":            "suggestions_batch",
            "recommendations": top3,
            "count":           len(top3),
        })

    # Sin resultados
    search_type = "departamento" if is_dept else "compañero/a de cuarto"
    return JSONResponse({
        "type":    "assistant",
        "content": (
            f"😔 Lo siento, no encontramos ningún {search_type} compatible con tus preferencias "
            "en este momento.\n\nPuedes ajustar tus preferencias o intentarlo más tarde "
            "cuando haya más usuarios en la plataforma."
        ),
        "options": ["Intentar de nuevo", "Cambiar preferencias"],
        "timestamp": datetime.now().isoformat(),
    })

# ── /api/chat (fallback Groq libre) ─────────────────────────────────────────
@app.post("/api/chat")
async def api_chat(request: dict):
    """Endpoint de chat libre — llamada directa a Groq."""
    if not GROQ_API_KEY:
        return JSONResponse({"content": "⚠️ Groq no configurado en el servidor."}, status_code=503)
    try:
        messages = []
        sp = request.get("system_prompt")
        if sp:
            messages.append({"role": "system", "content": sp})
        for m in (request.get("chat_history") or []):
            messages.append({"role": m.get("role","user"), "content": m.get("content","")})
        messages.append({"role": "user", "content": request.get("user_message","")})

        resp = requests.post(
            f"{GROQ_BASE_URL}/chat/completions",
            headers={"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"},
            json={"model": GROQ_MODEL, "messages": messages, "max_tokens": 512, "temperature": 0.7},
            timeout=20,
        )
        if resp.status_code == 200:
            content = resp.json()["choices"][0]["message"]["content"]
            return JSONResponse({"content": content})
        return JSONResponse({"content": "Error conectando con Groq."}, status_code=resp.status_code)
    except Exception as e:
        return JSONResponse({"content": f"Error: {e}"}, status_code=500)

# ── Ejecución local ──────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "7860"))
    print("🚀 ConVive Chatbot IA v2.0")
    print(f"📍 http://localhost:{port}")
    print(f"📊 Docs: http://localhost:{port}/docs")
    print(f"🤖 Groq: {'✅ configurado' if GROQ_API_KEY else '❌ NO configurado'}")
    print(f"🗄️  Supabase: {SUPABASE_URL}")
    uvicorn.run(app, host="0.0.0.0", port=port)
