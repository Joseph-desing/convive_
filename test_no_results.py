#!/usr/bin/env python3
"""
Test para verificar que el endpoint /chatbot/recommend 
devuelve el mensaje "no hay resultados" cuando no hay coincidencias
"""

import requests
import json

BASE_URL = "http://localhost:8000"

def test_no_results():
    """Enviar respuestas que NO tengan coincidencias en la BD"""
    
    # Criterios muy específicos que probablemente NO haya en la BD
    payload = {
        "user_id": "test-user-123",
        "responses": [
            "Compañero de cuarto",  # Tipo de búsqueda
            "Madrugador",           # Duerme muy de mañana
            "Obsesionado limpieza",  # Nivel muy alto de limpieza
            "Silencio total",        # No tolera ruido
            "Sin fiestas nunca",     # Nunca quiere fiestas
            "Sin invitados",         # No quiere invitados
            "Alcohólico",            # No tolera alcohol
            "Siempre en casa",       # Siempre en casa
        ],
        "habits": {
            "sleep_start": 3,        # Se duerme a las 3 AM (muy tarde)
            "sleep_end": 10,         # Se despierta a las 10 AM
            "cleanliness": 10,       # Muy limpio
            "noise_level": 1,        # No tolera nada de ruido
            "party_frequency": 1,    # Nada de fiestas
            "guests_frequency": 1,   # No quiere invitados
            "alcohol_frequency": 1,  # Nada de alcohol
            "home_time": 10,         # Siempre en casa
            "has_pets": False,
            "pets_tolerance": 1,     # No tolera mascotas
        }
    }
    
    print("=" * 60)
    print("🧪 TEST: Enviando criterios MUY específicos (sin coincidencias)")
    print("=" * 60)
    print(f"URL: {BASE_URL}/chatbot/recommend")
    print(f"\nPayload: {json.dumps(payload, indent=2)}")
    
    try:
        response = requests.post(
            f"{BASE_URL}/chatbot/recommend",
            json=payload,
            timeout=10
        )
        
        print(f"\n✅ Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"\n📦 Response:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
            
            # Verificar que sea mensaje de "no resultados"
            if 'content' in data:
                content = data['content']
                if 'Lo siento' in content and 'no hay' in content:
                    print("\n✅ ¡EXITO! El endpoint devolvió correctamente el mensaje de 'no hay resultados'")
                    return True
                else:
                    print(f"\n⚠️ El mensaje no contiene el texto esperado: {content}")
            
            # Verificar si devolvió recomendaciones
            if 'recommendations' in data:
                rec_count = len(data['recommendations'])
                if rec_count == 0:
                    print(f"\n✅ ¡EXITO! El endpoint devolvió 0 recomendaciones (no hay coincidencias)")
                    return True
                else:
                    print(f"\n❌ FALLO: Se esperaba 0 recomendaciones, obtuvimos {rec_count}")
        else:
            print(f"\n❌ Error HTTP: {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"\n❌ Error de conexión: {e}")
        return False

if __name__ == "__main__":
    success = test_no_results()
    exit(0 if success else 1)
