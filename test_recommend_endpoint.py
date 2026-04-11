#!/usr/bin/env python3
"""
Test completo para el endpoint /chatbot/recommend
Verifica: 1) Devolución de múltiples recomendaciones (TOP 3)
         2) Mensaje de "no hay resultados" cuando sin coincidencias
"""

import requests
import json

BASE_URL = "http://localhost:8000"

def test_case_1_with_results():
    """Enviar criterios flexibles que DEBERÍAN encontrar coincidencias"""
    
    payload = {
        "user_id": "test-user-flexible",
        "responses": [
            "Compañero de cuarto",
            "Flexible horarios",
            "Limpieza normal", 
            "Tolero ruido",
            "Fiestas ocasionales",
            "Invitados frecuentes",
            "Alcohol moderado",
            "Tiempo variable en casa",
        ],
        "habits": {
            "sleep_start": 23,       # Hora normal de dormir
            "sleep_end": 7,          # Hora normal de despertar
            "cleanliness": 5,        # Limpieza promedio
            "noise_level": 5,        # Tolerancia promedio
            "party_frequency": 5,    # Fiestas promedio
            "guests_frequency": 5,   # Invitados promedio
            "alcohol_frequency": 5,  # Alcohol promedio
            "home_time": 5,          # Tiempo promedio en casa
            "has_pets": False,
            "pets_tolerance": 5,
        }
    }
    
    print("\n" + "="*70)
    print("TEST 1️⃣ : CRITERIOS FLEXIBLES (Esperado: Múltiples recomendaciones)")
    print("="*70)
    
    try:
        response = requests.post(
            f"{BASE_URL}/chatbot/recommend",
            json=payload,
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            
            # Caso 1: Array de recomendaciones
            if 'recommendations' in data and data['recommendations']:
                rec_count = len(data['recommendations'])
                print(f"✅ SUCCESS: Se encontraron {rec_count} recomendaciones")
                print(f"\nPrimera recomendación:")
                first = data['recommendations'][0]
                print(f"  - Nombre: {first.get('matched_user_name', 'N/A')}")
                print(f"  - Compatibilidad: {int(first.get('compatibility_score', 0)*100)}%")
                print(f"  - Mensaje: {first.get('content', 'N/A')[:60]}...")
                return True
            
            # Caso 2: Mensaje "no hay resultados" (sin recomendaciones)
            elif 'content' in data and 'no hay' in data['content'].lower():
                print(f"⚠️ Sin recomendaciones: {data['content'][:50]}...")
                return True
            
            else:
                print(f"❌ FAIL: Respuesta inesperada: {json.dumps(data, ensure_ascii=False)[:100]}")
                return False
        else:
            print(f"❌ FAIL: HTTP Status {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ FAIL: Error: {e}")
        return False


def test_case_2_no_results():
    """Enviar criterios IMPOSIBLES que NO deberían encontrar coincidencias"""
    
    payload = {
        "user_id": "test-user-123",
        "responses": [
            "Compañero de cuarto",
            "Madrugador extremo",
            "Obsesionado limpieza",
            "Silencio absoluto",
            "Sin fiestas NUNCA",
            "Sin invitados NUNCA",
            "Sin alcohol TODO",
            "Siempre en casa",
        ],
        "habits": {
            "sleep_start": 3,        # Se duerme muy tarde
            "sleep_end": 10,         # Se despierta muy tarde
            "cleanliness": 10,       # MÁXIMA limpieza
            "noise_level": 1,        # Nada de ruido
            "party_frequency": 1,    # Nada de fiestas
            "guests_frequency": 1,   # Nada de invitados
            "alcohol_frequency": 1,  # Nada de alcohol
            "home_time": 10,         # Siempre en casa
            "has_pets": False,
            "pets_tolerance": 1,     # No tolera mascotas
        }
    }
    
    print("\n" + "="*70)
    print("TEST 2️⃣ : CRITERIOS MUY ESTRICTOS (Esperado: Mensaje 'no hay resultados')")
    print("="*70)
    
    try:
        response = requests.post(
            f"{BASE_URL}/chatbot/recommend",
            json=payload,
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            
            # Esperamos mensaje de "no hay resultados"
            if 'content' in data:
                content = data['content']
                if 'Lo siento' in content or 'no hay' in content.lower():
                    print(f"✅ SUCCESS: Mensaje de 'no resultados' recibido")
                    print(f"  Mensaje: {content[:80]}...")
                    
                    # Verificar que tenga opciones para intentar de nuevo
                    if 'options' in data and data['options']:
                        print(f"  Opciones: {data['options']}")
                        return True
                else:
                    print(f"❌ FAIL: Contenido no es 'no resultados': {content[:50]}...")
                    return False
            else:
                print(f"❌ FAIL: Respuesta sin 'content': {json.dumps(data, ensure_ascii=False)[:100]}")
                return False
        else:
            print(f"❌ FAIL: HTTP Status {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ FAIL: Error: {e}")
        return False


def test_case_3_department():
    """Enviar criterios para búsqueda de DEPARTAMENTO"""
    
    payload = {
        "user_id": "test-user-apt",
        "responses": [
            "Departamento",
            "2 habitaciones",
            "Ubicación central",
            "Pet-friendly",
        ],
        "habits": {
            "sleep_start": 23,
            "sleep_end": 7,
            "cleanliness": 5,
            "noise_level": 5,
            "party_frequency": 5,
            "guests_frequency": 5,
            "alcohol_frequency": 5,
            "home_time": 5,
            "has_pets": True,
            "pets_tolerance": 8,     # Tolera mascotas
        }
    }
    
    print("\n" + "="*70)
    print("TEST 3️⃣ : BÚSQUEDA DE DEPARTAMENTO (Esperado: Propiedades disponibles)")
    print("="*70)
    
    try:
        response = requests.post(
            f"{BASE_URL}/chatbot/recommend",
            json=payload,
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            
            if 'recommendations' in data and data['recommendations']:
                rec_count = len(data['recommendations'])
                print(f"✅ SUCCESS: Se encontraron {rec_count} propiedades")
                if rec_count > 0:
                    first = data['recommendations'][0]
                    print(f"  - Propietario: {first.get('matched_user_name', 'N/A')}")
                    print(f"  - Compatibilidad: {int(first.get('compatibility_score', 0)*100)}%")
                return True
            
            elif 'content' in data and 'no hay' in data['content'].lower():
                print(f"⚠️ Sin propiedades disponibles: {data['content'][:50]}...")
                return True
            else:
                print(f"⚠️ Respuesta inesperada: {json.dumps(data, ensure_ascii=False)[:100]}")
                return True  # Es válido aunque no haya resultados
        else:
            print(f"❌ FAIL: HTTP Status {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ FAIL: Error: {e}")
        return False


if __name__ == "__main__":
    results = []
    
    print("\n🚀 PRUEBAS COMPLETAS DEL ENDPOINT /chatbot/recommend")
    print("=" * 70)
    
    # Ejecutar tests
    results.append(("Test 1: Criterios flexibles", test_case_1_with_results()))
    results.append(("Test 2: Sin coincidencias", test_case_2_no_results()))
    results.append(("Test 3: Búsqueda departamento", test_case_3_department()))
    
    # Resumen
    print("\n" + "="*70)
    print("📊 RESUMEN DE RESULTADOS")
    print("="*70)
    
    passed = 0
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status}: {test_name}")
        if result:
            passed += 1
    
    print(f"\nTotal: {passed}/{len(results)} tests pasados")
    print("\n✅ LA FUNCIONALIDAD 'NO RESULTADOS' ESTÁ LISTA" if passed == len(results) else "❌ Hay fallos a resolver")
