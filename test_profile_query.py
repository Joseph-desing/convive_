import requests
import json

# Test para verificar si existe el perfil en Supabase
SUPABASE_URL = "https://jgksvxwgvfzylgpwbyfj.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impna3N2eHdndmZ6eWxncHdieWZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTczNTgzNzksImV4cCI6MjAzMjkzNDM3OX0.rz8DLY-9ELvdxm9RngDm6VC7OhQpSQjA0UTm4b8eGOE"

user_id = "decc0fe0-7ed1-4549-9ef2-7b3bf557ec1c"

# Verificar si existe en profiles
url = f"{SUPABASE_URL}/rest/v1/profiles?user_id=eq.{user_id}&select=user_id,full_name,profile_image_url"
headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}"
}

response = requests.get(url, headers=headers)
print(f"Status: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2)}")

if response.status_code == 200 and response.json():
    print("\n✅ PERFIL ENCONTRADO:")
    print(json.dumps(response.json(), indent=2))
else:
    print("\n❌ PERFIL NO ENCONTRADO")
    
    # Intentar listar todos los profiles para ver qué hay
    print("\nTodos los perfiles en la tabla:")
    url2 = f"{SUPABASE_URL}/rest/v1/profiles?select=user_id,full_name"
    response2 = requests.get(url2, headers=headers)
    print(f"Total perfiles: {len(response2.json())}")
    for profile in response2.json()[:5]:
        print(f"  - {profile['user_id']}: {profile['full_name']}")
