"""
ConVive Backend - Proxy para Groq API
Evita CORS y protege API Key
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from contextlib import asynccontextmanager
import httpx
import os
import logging
from dotenv import load_dotenv

# Cargar variables de entorno desde .env
load_dotenv()

# Configuración
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Cliente HTTP (global)
client = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestionar ciclo de vida de la aplicación"""
    # Startup
    global client
    client = httpx.AsyncClient(timeout=30.0)
    logger.info("✅ Cliente HTTP inicializado")
    yield
    # Shutdown
    if client:
        await client.aclose()
    logger.info("✅ Cliente HTTP cerrado")

app = FastAPI(
    title="ConVive Backend",
    version="1.0.0",
    lifespan=lifespan
)

# CORS - Permitir Flutter Web (ajusta según tu dominio)
# En desarrollo: permite todos los puertos de localhost
# En producción: especifica solo tus dominios
import re

def is_localhost(origin: str) -> bool:
    """Permitir cualquier puerto de localhost en desarrollo"""
    return bool(re.match(r'http://(localhost|127\.0\.0\.1)(:\d+)?$', origin))

origins = [
    "http://localhost:5173",  # Flutter dev (puerto fijo)
    "http://localhost:5174",
    "http://localhost:8000",
    "http://127.0.0.1:5173",
    "http://127.0.0.1:5174",
    # En producción, añade tu dominio real:
    # "https://convive.com",
    # "https://app.convive.com",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Modelos
class Message(BaseModel):
    role: str  # "user", "assistant", "system"
    content: str

class ChatRequest(BaseModel):
    user_message: str
    chat_history: Optional[List[Message]] = None
    system_prompt: Optional[str] = None
    user_id: Optional[str] = None
    user_profile: Optional[dict] = None
    user_habits: Optional[dict] = None

class ChatResponse(BaseModel):
    content: str
    usage: Optional[dict] = None

# Configuración de Groq
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GROQ_MODEL = os.getenv("GROQ_MODEL", "llama-3.1-70b-versatile")
GROQ_BASE_URL = "https://api.groq.com/openai/v1"

if not GROQ_API_KEY:
    logger.warning("⚠️ GROQ_API_KEY no configurada. Configura la variable de entorno.")

def build_system_prompt(user_profile: Optional[dict], user_habits: Optional[dict]) -> str:
    """Construir prompt de sistema con contexto del usuario"""
    if not user_profile and not user_habits:
        return ""
    
    profile = user_profile or {}
    habits = user_habits or {}
    
    return f"""Eres un asistente amable y útil de ConVive, una plataforma para encontrar compañeros de habitación compatibles.

Información del usuario:
- Email: {profile.get('email', 'N/A')}
- Tipo de suscripción: {profile.get('subscription_type', 'N/A')}

Hábitos del usuario:
- Nivel de limpieza: {habits.get('cleanliness', 'N/A')}/10
- Tolerancia al ruido: {habits.get('noise_level', 'N/A')}/10
- Frecuencia de fiestas: {habits.get('party_frequency', 'N/A')}/10
- Tolerancia a invitados: {habits.get('guests_frequency', 'N/A')}/10

Tu rol es:
1. Ayudar al usuario a encontrar compañeros de habitación compatibles
2. Responder preguntas sobre ConVive
3. Proporcionar recomendaciones basadas en sus hábitos
4. Mantener una conversación natural y amigable

Responde siempre en español y de manera concisa."""

@app.get("/health")
async def health_check():
    """Verificar que el backend está funcionando"""
    return {
        "status": "ok",
        "service": "ConVive Backend",
        "groq_configured": bool(GROQ_API_KEY)
    }

@app.post("/api/chat", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    """
    Endpoint principal del chatbot
    Recibe: mensaje del usuario + historial + contexto
    Retorna: respuesta de Groq
    """
    
    if not GROQ_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="Groq API Key no configurada en el servidor"
        )
    
    try:
        # Construir mensajes para Groq
        messages = []
        
        # Añadir prompt de sistema si existe
        system_prompt = request.system_prompt or build_system_prompt(
            request.user_profile,
            request.user_habits
        )
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        
        # Añadir historial
        if request.chat_history:
            for msg in request.chat_history:
                messages.append({
                    "role": msg.role,
                    "content": msg.content
                })
        
        # Añadir mensaje del usuario
        messages.append({"role": "user", "content": request.user_message})
        
        logger.info(f"📨 Enviando a Groq: {len(messages)} mensajes")
        logger.info(f"👤 Usuario: {request.user_id or 'desconocido'}")
        
        # Llamar a Groq (desde servidor, sin CORS)
        response = await client.post(
            f"{GROQ_BASE_URL}/chat/completions",
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {GROQ_API_KEY}",
            },
            json={
                "model": GROQ_MODEL,
                "messages": messages,
                "temperature": 0.7,
                "max_tokens": 1024,
                "top_p": 1,
            }
        )
        
        if response.status_code != 200:
            error_text = response.text
            logger.error(f"❌ Groq Error {response.status_code}: {error_text}")
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Error de Groq API: {error_text}"
            )
        
        data = response.json()
        content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
        
        if not content:
            raise HTTPException(
                status_code=500,
                detail="Groq no retornó contenido"
            )
        
        logger.info(f"✅ Respuesta de Groq recibida ({len(content)} caracteres)")
        
        return ChatResponse(
            content=content,
            usage=data.get("usage", {})
        )
    
    except httpx.TimeoutException:
        logger.error("⏱️ Timeout conectando a Groq")
        raise HTTPException(
            status_code=504,
            detail="Timeout conectando a Groq API"
        )
    
    except Exception as e:
        logger.error(f"🔴 Error en /api/chat: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error procesando chatbot: {str(e)}"
        )

@app.post("/api/recommendations")
async def get_recommendations(request: ChatRequest) -> ChatResponse:
    """
    Obtener recomendaciones de compatibilidad
    """
    
    if not GROQ_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="Groq API Key no configurada"
        )
    
    try:
        prompt = f"""Basándote en las siguientes respuestas del usuario y sus hábitos, proporciona 3 recomendaciones de tipos de compañeros ideales:

Respuestas del usuario: {request.user_message}
Hábitos: {request.user_habits or {}}

Proporciona recomendaciones claras y útiles en formato de lista numerada."""
        
        response = await client.post(
            f"{GROQ_BASE_URL}/chat/completions",
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {GROQ_API_KEY}",
            },
            json={
                "model": GROQ_MODEL,
                "messages": [{"role": "user", "content": prompt}],
                "temperature": 0.7,
                "max_tokens": 1024,
                "top_p": 1,
            }
        )
        
        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Error de Groq API"
            )
        
        data = response.json()
        content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
        
        return ChatResponse(content=content)
    
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error obteniendo recomendaciones: {str(e)}"
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
