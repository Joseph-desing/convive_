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
_configured_groq_model = os.getenv("GROQ_MODEL", "").strip()
GROQ_MODEL = (
    "llama-3.1-8b-instant"
    if _configured_groq_model in {"", "llama-3.1-70b-versatile"}
    else _configured_groq_model
)
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
    """
    Obtiene SOLO propiedades:
      - is_active = true
      - is_rented = false
      - is_approved = true
    Filtra a nivel de Supabase Y en Python para triple seguridad.
    """
    rows = _sb_get(
        "properties",
        "is_active=eq.true&is_rented=eq.false&is_approved=eq.true&select=*"
    )
    result = []
    for p in rows:
        # Filtro Python redundante — nunca debe pasar una propiedad invalida
        if p.get("is_rented", False):
            print(f"  🛡️  Prop descartada (alquilada): {p.get('title','?')}")
            continue
        if not p.get("is_approved", True):
            print(f"  🛡️  Prop descartada (no aprobada): {p.get('title','?')}")
            continue
        if not p.get("is_active", True):
            print(f"  🛡️  Prop descartada (inactiva): {p.get('title','?')}")
            continue
        # Excluir propiedades del mismo usuario
        if p.get("owner_id") == exclude_user_id or p.get("user_id") == exclude_user_id:
            continue
        result.append(p)
    print(f"  ✅ Propiedades válidas tras filtro triple: {len(result)}")
    return result

# ════════════════════════════════════════════════════════════════════════════
# GROQ — solo redacta explicaciones en lenguaje natural
# 🛑 REGLA ABSOLUTA: Groq NUNCA calcula ni inventa el porcentaje.
#    El score viene únicamente del algoritmo matemático v2.
# ════════════════════════════════════════════════════════════════════════════

def _normalize_text(value) -> str:
    text = str(value or "").strip().lower()
    replacements = {
        "á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u", "ü": "u",
        "ñ": "n",
    }
    for src, dst in replacements.items():
        text = text.replace(src, dst)
    return re.sub(r"\s+", " ", text)

def _normalize_housing_type(value: str) -> str:
    normalized = _normalize_text(value)
    if any(word in normalized for word in [
        "departamento", "departamentos", "apartamento", "apartamentos",
        "depa", "dpto", "vivienda", "alojamiento", "casa",
    ]):
        return "departamento"
    return normalized

def _is_available_property(prop: dict, exclude_user_id: str) -> bool:
    status = _normalize_text(prop.get("status"))
    is_active = prop.get("is_active")
    is_rented = bool(prop.get("is_rented", False))

    if is_rented:
        print(f"  Prop descartada (alquilada): {prop.get('title','?')}")
        return False
    if status and status != "active":
        print(f"  Prop descartada (status={status}): {prop.get('title','?')}")
        return False
    if not status and is_active is False:
        print(f"  Prop descartada (inactiva): {prop.get('title','?')}")
        return False
    if prop.get("owner_id") == exclude_user_id or prop.get("user_id") == exclude_user_id:
        print(f"  Prop descartada (propia): {prop.get('title','?')}")
        return False
    return True

def _property_matches_housing_type(prop: dict, housing_type: str) -> bool:
    normalized_type = _normalize_housing_type(housing_type)
    if normalized_type == "departamento":
        explicit_type = _normalize_text(
            prop.get("housing_type") or prop.get("property_type") or prop.get("type")
        )
        if explicit_type:
            return _normalize_housing_type(explicit_type) == "departamento"
        return True

    searchable = " ".join([
        _normalize_text(prop.get("title")),
        _normalize_text(prop.get("description")),
        _normalize_text(prop.get("address")),
    ])
    return normalized_type in searchable

def _dedupe_properties(rows: list) -> list:
    seen = set()
    result = []
    for row in rows:
        prop_id = row.get("id")
        if prop_id and prop_id in seen:
            continue
        if prop_id:
            seen.add(prop_id)
        result.append(row)
    return result

def get_available_properties(exclude_user_id: str, housing_type: str = "departamento") -> list:
    normalized_type = _normalize_housing_type(housing_type)
    print(f"Buscando propiedades | tipo='{housing_type}' -> '{normalized_type}'")

    exact_params = (
        "status=eq.active&is_rented=eq.false"
        "&select=*&order=created_at.desc&limit=30"
    )
    exact_rows = _sb_get("properties", exact_params)
    print(f"Filtro exacto enviado: {exact_params}")
    print(f"Resultados Supabase exactos: {len(exact_rows)}")
    exact = [
        p for p in exact_rows
        if _is_available_property(p, exclude_user_id)
        and _property_matches_housing_type(p, normalized_type)
    ]
    print(f"Resultados exactos/compatibles tras filtro local: {len(exact)}")
    if exact:
        return _dedupe_properties(exact)

    ilike_term = "departamento" if normalized_type == "departamento" else normalized_type
    flexible_params = (
        "status=eq.active&is_rented=eq.false"
        f"&or=(title.ilike.*{ilike_term}*,description.ilike.*{ilike_term}*,address.ilike.*{ilike_term}*)"
        "&select=*&order=created_at.desc&limit=30"
    )
    flexible_rows = _sb_get("properties", flexible_params)
    print(f"Filtro flexible enviado: {flexible_params}")
    print(f"Resultados Supabase flexible: {len(flexible_rows)}")
    flexible = [
        p for p in flexible_rows
        if _is_available_property(p, exclude_user_id)
    ]
    print(f"Resultados flexibles tras filtro local: {len(flexible)}")
    if flexible:
        return _dedupe_properties(flexible)

    general_params = (
        "status=eq.active&is_rented=eq.false"
        "&select=*&order=created_at.desc&limit=30"
    )
    general_rows = _sb_get("properties", general_params)
    print(f"Fallback general enviado: {general_params}")
    print(f"Resultados Supabase general: {len(general_rows)}")
    general = [
        p for p in general_rows
        if _is_available_property(p, exclude_user_id)
    ]
    print(f"Resultados generales disponibles: {len(general)}")
    return _dedupe_properties(general)

def groq_describe_roommate_v2(
    name: str, bio: str, score: float,
    breakdown: dict, strong: list, weak: list, penalties: list
) -> str:
    """
    Groq redacta la explicación en lenguaje natural.
    El score (pct) ya fue calculado por el algoritmo y se pasa como dato.
    Groq NO puede cambiarlo — el prompt lo prohíbe explicitamente.
    """
    pct = int(score * 100)
    strong_str = ", ".join(strong[:3]) if strong else "hábitos similares"
    weak_str   = ", ".join(weak[:2])   if weak   else ""
    pen_str    = "; ".join(p.split("→")[0].strip() for p in penalties[:2]) if penalties else ""

    # Fallback sin Groq
    if not GROQ_API_KEY:
        note = f" La compatibilidad baja un poco en {weak_str}." if weak_str else ""
        return f"Te recomiendo a {name} porque coinciden bien en {strong_str}.{note}"

    try:
        debil_text = f"Puntos débiles detectados por el algoritmo: {weak_str}." if weak_str else "No hay puntos débiles relevantes."
        penal_text = f"Penalizaciones aplicadas: {pen_str}." if pen_str else ""
        prompt = (
            f"Eres el asistente de ConVive. Tu tarea es redactar una explicación en 2 oraciones de por qué {name} "
            f"es recomendado como compañero de cuarto, basándote en estos datos del algoritmo:\n"
            f"- Puntos fuertes: {strong_str}\n"
            f"- {debil_text}\n"
            f"- {penal_text}\n"
            f"- Bio del candidato: {bio or 'Sin bio'}\n"
            f"INSTRUCCIONES OBLIGATORIAS:\n"
            f"1. NO escribas ningún porcentaje ni número de compatibilidad. El porcentaje lo muestra la app, no tú.\n"
            f"2. Si hay puntos débiles o penalizaciones, mencionarlos honestamente en pocas palabras.\n"
            f"3. Escribe en español, sin asteriscos, sin markdown, sin emojis."
        )
        resp = requests.post(
            f"{GROQ_BASE_URL}/chat/completions",
            headers={"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"},
            json={"model": GROQ_MODEL, "messages": [{"role": "user", "content": prompt}],
                  "max_tokens": 120, "temperature": 0.55},
            timeout=10,
        )
        if resp.status_code == 200:
            text = resp.json()["choices"][0]["message"]["content"].strip()
            # Seguridad extra: si Groq metió un porcentaje en el texto, removerlo
            text = re.sub(r'\b\d{1,3}\s*%', '', text).strip()
            return text
    except Exception as e:
        print(f"⚠️ Groq roommate error: {e}")

    note = f" Atención: difiere en {weak_str}." if weak_str else ""
    return f"Te recomiendo a {name} porque coinciden en {strong_str}.{note}"


def groq_describe_property_v2(
    title: str, address: str, price,
    score: float, features: dict, breakdown: dict, penalties: list
) -> str:
    """
    Groq redacta la explicación del departamento en lenguaje natural.
    El score ya fue calculado por el algoritmo. Groq NO lo inventa.
    """
    pct = int(score * 100)  # solo para referencia interna, NO se pasa a Groq
    price_text = f"${int(price)}/mes" if price else "precio no especificado"
    pen_str    = "; ".join(p.split("→")[0].strip() for p in penalties[:2]) if penalties else ""

    # Fallback sin Groq
    if not GROQ_API_KEY:
        pen_note = f" Observación: {penalties[0].split('→')[0].strip()}." if penalties else ""
        return f"Este departamento en {address or title} ({price_text}) se ajusta bien a tu perfil.{pen_note}"

    try:
        budget_score = breakdown.get('presupuesto', 65)
        rooms_score  = breakdown.get('habitaciones', 70)
        avail_score  = breakdown.get('disponibilidad', 100)
        penal_text   = f"Observaciones del algoritmo: {pen_str}." if pen_str else "Sin penalizaciones."
        prompt = (
            f"Eres el asistente de ConVive. Redacta en 2 oraciones por qué este departamento es recomendado, "
            f"basándote en estos datos del algoritmo:\n"
            f"- Título: {title}. Dirección: {address or 'Sin dirección'}. Precio: {price_text}.\n"
            f"- Habitaciones: {features.get('bedrooms','?')}, amoblado: {features.get('furnished',False)}, "
            f"mascotas permitidas: {features.get('pets_allowed',False)}, alícuota incluida: {features.get('aliquot_included',False)}.\n"
            f"- Score presupuesto: {budget_score}/100. Score habitaciones: {rooms_score}/100. Disponibilidad: {avail_score}/100.\n"
            f"- {penal_text}\n"
            f"INSTRUCCIONES OBLIGATORIAS:\n"
            f"1. NO escribas ningún porcentaje ni número de compatibilidad. El porcentaje lo calcula y muestra la app.\n"
            f"2. Si hay observaciones o penalizaciones, mencionarlas brevemente y con honestidad.\n"
            f"3. Escribe en español, sin asteriscos, sin markdown, sin emojis."
        )
        resp = requests.post(
            f"{GROQ_BASE_URL}/chat/completions",
            headers={"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"},
            json={"model": GROQ_MODEL, "messages": [{"role": "user", "content": prompt}],
                  "max_tokens": 120, "temperature": 0.55},
            timeout=10,
        )
        if resp.status_code == 200:
            text = resp.json()["choices"][0]["message"]["content"].strip()
            # Seguridad extra: remover cualquier porcentaje que Groq pudiera haber inventado
            text = re.sub(r'\b\d{1,3}\s*%', '', text).strip()
            return text
    except Exception as e:
        print(f"⚠️ Groq property error: {e}")

    pen_note = f" Observación: {pen_str}." if pen_str else ""
    return f"Departamento en {address or title} ({price_text}).{pen_note}"

# ════════════════════════════════════════════════════════════════════════════
# COMPATIBILIDAD v2 — algoritmo diferenciado con pesos, penalizaciones y
# variación controlada para producir porcentajes realistas (45%–95%)
# ════════════════════════════════════════════════════════════════════════════

def _scale_diff(a: float, b: float, max_d: float = 10.0) -> float:
    """Diferencia normalizada entre 0 y 1 (0=opuestos, 1=idénticos)."""
    return max(0.0, 1.0 - abs(a - b) / max_d)

def _sleep_compat(us: int, ue: int, os_: int, oe: int) -> float:
    """Compatibilidad de horarios de sueño (máx 6h toleradas)."""
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
        "cleanliness":      float(raw.get("cleanliness_level",    5)),
        "noise_level":      float(raw.get("noise_tolerance",      5)),
        "party_frequency":  float(raw.get("party_frequency",      5)),
        "guests_frequency": float(raw.get("guests_tolerance",     5)),
        "home_time":        float(raw.get("time_at_home",         5)),
        "responsibility":   float(raw.get("responsibility_level", 5)),
        "pets_tolerance":   pet_val,
        "has_pets":         bool(raw.get("pets", False)),
        "sleep_start":      int(raw.get("sleep_schedule_start",   23)),
        "sleep_end":        int(raw.get("sleep_schedule_end",      7)),
        "alcohol_frequency":float(raw.get("alcohol_frequency",    3)),
    }

# ── ROOMMATE ─────────────────────────────────────────────────────────────────

def calculate_roommate_compatibility(user_h: dict, candidate_h: dict) -> tuple:
    """
    Retorna (score: float, breakdown: dict, penalties: list).
    Pesos:
      limpieza 18% · responsabilidad 15% · ruido 15% · sueño 12%
      visitas 10% · fiestas 10% · mascotas 8% · tiempo_casa 7% · ubicación 5%
    Penalizaciones extra por diferencias críticas.
    Variación desempate: ±3% (nunca reemplaza el cálculo real).
    """
    breakdown = {}
    penalties = []

    # ── Criterios base ───────────────────────────────────────────────────────
    c_clean = _scale_diff(user_h.get("cleanliness", 5),      candidate_h.get("cleanliness", 5))
    c_resp  = _scale_diff(user_h.get("responsibility", 5),   candidate_h.get("responsibility", 5))
    c_noise = _scale_diff(user_h.get("noise_level", 5),      candidate_h.get("noise_level", 5))
    c_sleep = _sleep_compat(
        user_h.get("sleep_start", 23), user_h.get("sleep_end", 7),
        candidate_h.get("sleep_start", 23), candidate_h.get("sleep_end", 7)
    )
    c_guests = _scale_diff(user_h.get("guests_frequency", 5), candidate_h.get("guests_frequency", 5))
    c_party  = _scale_diff(user_h.get("party_frequency", 5),  candidate_h.get("party_frequency", 5))
    c_pets   = _pet_compat(
        user_h.get("has_pets", False), user_h.get("pets_tolerance", 5),
        candidate_h.get("has_pets", False), candidate_h.get("pets_tolerance", 5)
    )
    c_home   = _scale_diff(user_h.get("home_time", 5), candidate_h.get("home_time", 5))
    c_zone   = 0.75  # neutral: no tenemos zona del candidato normalmente

    breakdown = {
        "limpieza":        round(c_clean * 100),
        "responsabilidad": round(c_resp  * 100),
        "ruido":           round(c_noise * 100),
        "suenio":          round(c_sleep * 100),
        "visitas":         round(c_guests* 100),
        "fiestas":         round(c_party * 100),
        "mascotas":        round(c_pets  * 100),
        "tiempo_casa":     round(c_home  * 100),
        "ubicacion":       round(c_zone  * 100),
    }

    # ── Score ponderado ───────────────────────────────────────────────────────
    total = (
        c_clean  * 0.18 +
        c_resp   * 0.15 +
        c_noise  * 0.15 +
        c_sleep  * 0.12 +
        c_guests * 0.10 +
        c_party  * 0.10 +
        c_pets   * 0.08 +
        c_home   * 0.07 +
        c_zone   * 0.05
    )

    # ── Penalizaciones por diferencias críticas ───────────────────────────────
    # 1) Limpieza muy diferente (≥5 puntos) → -8%
    clean_diff = abs(user_h.get("cleanliness", 5) - candidate_h.get("cleanliness", 5))
    if clean_diff >= 5:
        total -= 0.08
        penalties.append(f"limpieza muy diferente ({clean_diff:.0f} pts) → -8%")
    elif clean_diff >= 3:
        total -= 0.04
        penalties.append(f"limpieza algo diferente ({clean_diff:.0f} pts) → -4%")

    # 2) Silencio vs fiestas: uno quiere silencio (noise<4) y otro muchas fiestas (party>7) → -12%
    user_wants_quiet   = user_h.get("noise_level", 5) < 4
    cand_has_parties   = candidate_h.get("party_frequency", 5) > 7
    cand_wants_quiet   = candidate_h.get("noise_level", 5) < 4
    user_has_parties   = user_h.get("party_frequency", 5) > 7
    if (user_wants_quiet and cand_has_parties) or (cand_wants_quiet and user_has_parties):
        total -= 0.12
        penalties.append("conflicto silencio vs fiestas → -12%")

    # 3) Horarios de sueño muy distintos (score < 0.40) → -7%
    if c_sleep < 0.40:
        total -= 0.07
        penalties.append(f"horarios de sueño muy distintos (compat {int(c_sleep*100)}%) → -7%")

    # 4) Responsabilidad muy baja del candidato (< 3/10) → -6%
    if candidate_h.get("responsibility", 5) < 3:
        total -= 0.06
        penalties.append("candidato con responsabilidad muy baja → -6%")

    # ── Variación de desempate: ±3% máximo ───────────────────────────────────
    noise = random.uniform(-0.03, 0.03)
    total += noise

    score = round(min(max(total, 0.0), 1.0), 4)
    return score, breakdown, penalties

# ── DEPARTAMENTO ─────────────────────────────────────────────────────────────

def calculate_property_compatibility(user_h: dict, prop: dict, owner_h: dict = None, user_responses_text: str = "") -> tuple:
    """
    Retorna (score: float, breakdown: dict, penalties: list).
    Pesos:
      presupuesto 25% · ubicación 20% · habitaciones 15%
      disponibilidad 12% · aprobado_admin 10% · preferencias 10% · alícuota 8%
    """
    breakdown = {}
    penalties = []

    # ── Filtros descalificadores (score = 0 inmediato) ───────────────────────
    # Estas condiciones eliminan la propiedad ANTES de calcular nada.
    # El score devuelto es 0.0 y Flutter nunca la mostrará.
    prop_status = _normalize_text(prop.get("status"))
    if prop.get("is_rented", False):
        penalties.append("DESCARTADO: propiedad ya alquilada")
        return 0.0, breakdown, penalties
    if prop_status and prop_status != "active":
        penalties.append(f"DESCARTADO: status {prop_status}")
        return 0.0, breakdown, penalties
    if not prop_status and not prop.get("is_approved", True):
        penalties.append("DESCARTADO: no aprobada por admin")
        return 0.0, breakdown, penalties
    if not prop_status and not prop.get("is_active", True):
        penalties.append("DESCARTADO: propiedad inactiva")
        return 0.0, breakdown, penalties

    # ── 1. Presupuesto vs precio (25%) ────────────────────────────────────────
    price = float(prop.get("price") or prop.get("rent_amount") or prop.get("budget") or 0)
    budget_str = user_responses_text  # texto de respuestas del usuario
    budget_max = _parse_budget(budget_str) if budget_str else 0.0

    if price > 0 and budget_max > 0:
        if price <= budget_max:
            c_price = 1.0
        elif price <= budget_max * 1.15:   # hasta 15% sobre presupuesto → gradual
            c_price = max(0.0, 1.0 - (price - budget_max) / (budget_max * 0.5))
        else:                              # muy sobre presupuesto → penalización fuerte
            c_price = max(0.0, 0.3 - (price - budget_max * 1.15) / price)
            penalties.append(f"precio ${price:.0f} muy sobre presupuesto ${budget_max:.0f} → penalización fuerte")
    else:
        c_price = 0.65  # neutral si no hay dato
    breakdown["presupuesto"] = round(c_price * 100)

    # ── 2. Ubicación (20%) ────────────────────────────────────────────────────
    has_lat = bool(prop.get("latitude") or prop.get("lat"))
    c_location = 0.80 if has_lat else 0.55  # penalizar si no hay coords
    if not has_lat:
        penalties.append("sin coordenadas de ubicación → -20% en ubicación")
    breakdown["ubicacion"] = round(c_location * 100)

    # ── 3. Habitaciones (15%) ─────────────────────────────────────────────────
    bedrooms = int(prop.get("bedrooms") or 0)
    # Detectar habitaciones pedidas del texto de respuestas
    c_rooms = 0.70  # neutral por defecto
    if bedrooms > 0:
        if "3 o más" in budget_str or "3+" in budget_str:
            c_rooms = 1.0 if bedrooms >= 3 else max(0.3, 1.0 - (3 - bedrooms) * 0.35)
        elif "2 habitaciones" in budget_str:
            c_rooms = 1.0 if bedrooms == 2 else (0.7 if bedrooms > 2 else 0.4)
        elif "1 habitación" in budget_str or "estudio" in budget_str:
            c_rooms = 1.0 if bedrooms == 1 else (0.6 if bedrooms == 2 else 0.5)
    breakdown["habitaciones"] = round(c_rooms * 100)

    # ── 4. Disponibilidad real (12%) ──────────────────────────────────────────
    is_active  = prop_status == "active" if prop_status else prop.get("is_active", True)
    is_rented  = prop.get("is_rented", False)
    c_avail = 1.0 if (is_active and not is_rented) else 0.0
    breakdown["disponibilidad"] = round(c_avail * 100)

    # ── 5. Aprobado por admin (10%) ───────────────────────────────────────────
    is_approved = True if prop_status == "active" else prop.get("is_approved", True)
    c_approved  = 1.0 if is_approved else 0.0
    breakdown["aprobado"] = round(c_approved * 100)

    # ── 6. Preferencias del usuario (10%) ────────────────────────────────────
    pref_score = 0.70
    pets_ok    = prop.get("pets_allowed", False)
    user_tol   = user_h.get("pets_tolerance", 5)
    if user_tol >= 7 and not pets_ok:
        pref_score -= 0.25
        penalties.append("usuario necesita mascotas pero no se permiten → -25% preferencias")
    furnished = prop.get("furnished") or prop.get("is_furnished", False)
    if "amoblado" in budget_str.lower() and not furnished:
        pref_score -= 0.15
        penalties.append("usuario quiere amoblado pero no lo está → -15% preferencias")
    c_pref = max(0.0, pref_score)
    breakdown["preferencias"] = round(c_pref * 100)

    # ── 7. Alícuota incluida (8%) ─────────────────────────────────────────────
    aliquot_included = prop.get("aliquot_included", False)
    c_aliquot = 1.0 if aliquot_included else 0.60
    breakdown["alicuota"] = round(c_aliquot * 100)

    # ── Score ponderado ───────────────────────────────────────────────────────
    total = (
        c_price    * 0.25 +
        c_location * 0.20 +
        c_rooms    * 0.15 +
        c_avail    * 0.12 +
        c_approved * 0.10 +
        c_pref     * 0.10 +
        c_aliquot  * 0.08
    )

    # ── Variación de desempate ±3% ────────────────────────────────────────────
    noise = random.uniform(-0.03, 0.03)
    total += noise

    score = round(min(max(total, 0.0), 1.0), 4)
    return score, breakdown, penalties

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
    Recomendaciones con datos reales de Supabase + Groq v2.
    Usa algoritmo diferenciado: scores 45-95% según hábitos reales.
    """
    responses_text = " ".join(request.responses).lower()
    normalized_responses_text = _normalize_text(responses_text)
    user_h         = request.habits

    print(f"\n{'='*60}")
    print(f"🔍 RECOMMEND v2 | user_id={request.user_id}")
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
    normalized_wants_dept = any(w in normalized_responses_text for w in [
        "departamento", "departamentos", "apartamento", "apartamentos",
        "renta", "arrendar", "alquilar", "alojamiento", "vivienda",
        "mostrar departamentos", "si mostrar departamentos",
    ])
    normalized_wants_roommate = any(w in normalized_responses_text for w in [
        "companero", "companera", "habitacion", "compartir",
        "roommate", "mostrar companeros", "si mostrar companeros",
    ])
    if normalized_wants_dept:
        is_dept = True
        is_roommate = False
    elif normalized_wants_roommate:
        is_roommate = True

    recommendations = []
    discarded = []

    # ── COMPAÑERO DE CUARTO ──────────────────────────────────────────────────
    if is_roommate:
        all_habits = get_all_habits(request.user_id)
        print(f"👥 Candidatos encontrados en Supabase: {len(all_habits)}")
        for row in all_habits:
            try:
                cuid = row.get("user_id")
                if not cuid:
                    continue
                candidate_h = _normalize_habits(row)
                score, breakdown, penalties = calculate_roommate_compatibility(user_h, candidate_h)

                nivel = "🟢" if score>=0.85 else "🟡" if score>=0.75 else "🟠" if score>=0.60 else "🔴"
                print(f"  {nivel} {cuid[:8]}... {int(score*100)}%")
                print(f"     breakdown: limpieza={breakdown.get('limpieza')}% resp={breakdown.get('responsabilidad')}% ruido={breakdown.get('ruido')}% sueño={breakdown.get('suenio')}% fiestas={breakdown.get('fiestas')}%")
                if penalties:
                    print(f"     ⚠️ penalizaciones: {penalties}")

                if score < 0.45:
                    discarded.append(f"{cuid[:8]} ({int(score*100)}%) — score bajo")
                    continue

                profile = get_user_profile(cuid)
                name    = profile.get("full_name") or profile.get("name") or "Usuario"
                avatar  = profile.get("profile_image_url") or profile.get("avatar_url")
                bio     = profile.get("bio") or ""
                lat = profile.get("latitude") or profile.get("lat")
                lng = profile.get("longitude") or profile.get("lng")
                prop_location = {"lat": float(lat), "lng": float(lng), "address": profile.get("address") or profile.get("city") or ""} if lat and lng else None

                strong = [k for k, v in breakdown.items() if v >= 80]
                weak   = [k for k, v in breakdown.items() if v < 60]
                content = groq_describe_roommate_v2(name, bio, score, breakdown, strong, weak, penalties)

                recommendations.append({
                    "content": content, "matched_user_id": cuid,
                    "matched_user_name": name, "matched_user_avatar": avatar,
                    "compatibility_score": score, "property_location": prop_location,
                })
            except Exception as e:
                print(f"  ⚠️ Error candidato: {e}")

    # ── DEPARTAMENTO ─────────────────────────────────────────────────────────
    elif is_dept:
        props = get_available_properties(request.user_id, "departamento")
        print(f"🏠 Propiedades disponibles en Supabase: {len(props)}")
        for prop in props:
            try:
                prop_id  = prop.get("id")
                owner_id = prop.get("owner_id") or prop.get("user_id")
                owner_h_raw = get_user_habits(owner_id) if owner_id else {}
                owner_h     = _normalize_habits(owner_h_raw) if owner_h_raw else {}

                score, breakdown, penalties = calculate_property_compatibility(
                    user_h, prop, owner_h or None, responses_text
                )
                prop_title = (prop.get("title") or "?")[:30]
                nivel = "🟢" if score>=0.85 else "🟡" if score>=0.75 else "🟠" if score>=0.60 else "🔴"
                print(f"  {nivel} {prop_title} {int(score*100)}%")
                print(f"     breakdown: precio={breakdown.get('presupuesto')}% ubicacion={breakdown.get('ubicacion')}% habitaciones={breakdown.get('habitaciones')}% disponibilidad={breakdown.get('disponibilidad')}%")
                if penalties:
                    print(f"     ⚠️ penalizaciones: {penalties}")

                if score == 0.0:
                    discarded.append(f"{prop_title} — {penalties[0] if penalties else 'descartado'}")
                    continue
                if score < 0.45:
                    discarded.append(f"{prop_title} ({int(score*100)}%) — score bajo")
                    continue

                owner_profile = get_user_profile(owner_id) if owner_id else {}
                name  = owner_profile.get("full_name") or owner_profile.get("name") or "Propietario"
                avatar = prop.get("main_image_url") or prop.get("image_url") or owner_profile.get("profile_image_url")
                title   = prop.get("title") or "Departamento"
                address = prop.get("address") or prop.get("location") or ""
                price   = prop.get("price") or prop.get("rent_amount") or prop.get("budget")
                features = {
                    "bedrooms": prop.get("bedrooms"), "bathrooms": prop.get("bathrooms"),
                    "furnished": prop.get("furnished") or prop.get("is_furnished", False),
                    "pets_allowed": prop.get("pets_allowed", False),
                    "aliquot_included": prop.get("aliquot_included", False),
                }
                lat = prop.get("latitude") or prop.get("lat")
                lng = prop.get("longitude") or prop.get("lng")
                prop_location = {"lat": float(lat), "lng": float(lng), "address": address} if lat and lng else None

                content = groq_describe_property_v2(title, address, price, score, features, breakdown, penalties)
                recommendations.append({
                    "content": content, "matched_user_id": owner_id or prop_id,
                    "matched_user_name": name, "matched_user_avatar": avatar,
                    "compatibility_score": score, "property_location": prop_location,
                })
            except Exception as e:
                print(f"  ⚠️ Error propiedad: {e}")

    # ── Ordenar, limitar a top 3 y loguear ───────────────────────────────────
    if is_dept and not recommendations:
        fallback_props = props if 'props' in locals() else get_available_properties(request.user_id, "departamento")
        print(f"🏠 Fallback de sugerencias disponibles por score bajo/excepciones: {len(fallback_props)} props")
        for prop in fallback_props[:3]:
            try:
                prop_id  = prop.get("id")
                owner_id = prop.get("owner_id") or prop.get("user_id")
                owner_profile = get_user_profile(owner_id) if owner_id else {}
                name  = owner_profile.get("full_name") or owner_profile.get("name") or "Propietario"
                avatar = prop.get("main_image_url") or prop.get("image_url") or owner_profile.get("profile_image_url")
                title   = prop.get("title") or "Departamento"
                address = prop.get("address") or prop.get("location") or ""
                price   = prop.get("price") or prop.get("rent_amount") or prop.get("budget")
                lat = prop.get("latitude") or prop.get("lat")
                lng = prop.get("longitude") or prop.get("lng")
                prop_location = {"lat": float(lat), "lng": float(lng), "address": address} if lat and lng else None
                content = (
                    f"Hay una propiedad disponible que podrías revisar: {title}"
                    f"{' en ' + address if address else ''}"
                    f"{' por $' + str(int(float(price))) + '/mes' if price else ''}."
                    " No coincide al 100% con todos tus criterios, pero está publicada y disponible."
                )
                recommendations.append({
                    "content": content, "matched_user_id": owner_id or prop_id,
                    "matched_user_name": name, "matched_user_avatar": avatar,
                    "compatibility_score": 0.55, "property_location": prop_location,
                })
            except Exception as e:
                print(f"  Error fallback propiedad: {e}")

    recommendations.sort(key=lambda x: x["compatibility_score"], reverse=True)
    top3 = recommendations[:3]

    print(f"\n✅ Top {len(top3)} recomendaciones:")
    for r in top3:
        nivel = "🟢 Excelente" if r["compatibility_score"]>=0.85 else \
                "🟡 Muy bueno" if r["compatibility_score"]>=0.75 else \
                "🟠 Bueno"     if r["compatibility_score"]>=0.60 else "🔴 Regular"
        print(f"  {nivel} | {r['matched_user_name']} → {int(r['compatibility_score']*100)}%")
    if discarded:
        print(f"🗑️  Descartados ({len(discarded)}): {discarded}")
    print(f"{'='*60}\n")

    if top3:
        return JSONResponse({"type": "suggestions_batch", "recommendations": top3, "count": len(top3)})

    search_type = "departamento" if is_dept else "compañero/a de cuarto"
    return JSONResponse({
        "type": "assistant",
        "content": f"😔 Lo siento, no encontramos ningún {search_type} compatible en este momento.\n\nPuedes ajustar tus preferencias o intentarlo más tarde.",
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
