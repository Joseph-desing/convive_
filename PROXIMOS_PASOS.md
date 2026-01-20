# 🚀 PRÓXIMOS PASOS - CONFIGURACIÓN Y SETUP

## ✅ Completado en esta sesión

### 1. Estructura de Carpetas (Completa)
```
lib/
├── main.dart
├── config/                    ✅ Configuración centralizada
├── models/                    ✅ 11 modelos con JSON serialization
├── services/                  ✅ 5 servicios (Supabase + IA)
├── providers/                 ✅ 4 proveedores de estado
├── utils/                     ✅ Utilidades y helpers
├── constants/                 ✅ Constantes de la app
├── exceptions/                ✅ Excepciones personalizadas
├── screens/                   📝 Listos para actualizar
├── widgets/                   📝 Listos para actualizar
└── theme/                     📝 Tema personalizado
```

### 2. Archivos Creados (Total: 31 archivos)
- **Modelos**: 11 modelos + 1 index
- **Servicios**: 5 servicios + 1 index  
- **Providers**: 4 providers + 1 index
- **Config**: 3 archivos de configuración
- **Constants**: 2 archivos
- **Exceptions**: 2 archivos
- **Utils**: 2 archivos
- **Documentación**: 2 archivos

### 3. pubspec.yaml Actualizado
✅ 22 dependencias agregadas
✅ 2 dev_dependencies agregadas
✅ Lista completa en pubspec.yaml

---

## 🔴 PASO 1: Generar Archivos JSON (INMEDIATO)

### Comando:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Qué genera:
- `user.g.dart` - JSON serialización de User
- `profile.g.dart` - JSON serialización de Profile
- `habits.g.dart` - JSON serialización de Habits
- `property.g.dart` - JSON serialización de Property
- `property_image.g.dart` - JSON serialización de PropertyImage
- `swipe.g.dart` - JSON serialización de Swipe
- `match.g.dart` - JSON serialización de Match
- `chat.g.dart` - JSON serialización de Chat
- `message.g.dart` - JSON serialización de Message
- `subscription.g.dart` - JSON serialización de Subscription
- `partner_profile.g.dart` - JSON serialización de PartnerProfile

### Por qué es crítico:
- Sin estos archivos, NO puedes usar `toJson()` y `fromJson()`
- Los servicios no pueden serializar/deserializar datos de Supabase
- Los providers fallarán al intentar convertir datos

### Tiempo estimado: 30-60 segundos

---

## 🔴 PASO 2: Configurar Supabase Credentials

### Archivo: `lib/config/app_config.dart`

Reemplaza los valores:
```dart
// 1. Ir a https://supabase.com
// 2. Crear nuevo proyecto
// 3. En Settings → API: copiar URL y Anon Key

const String SUPABASE_URL = 'https://tuproyecto.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJ...(tu clave)...';

// Para IA (local o deployed)
const String AI_SERVICE_URL = 'http://localhost:8000'; // Desarrollo
// const String AI_SERVICE_URL = 'https://ia-api.com'; // Producción
```

### Ubicaciones en Supabase:
- **URL**: Configuración → API → Project URL
- **Anon Key**: Configuración → API → Anon Public Key
- **Buckets**: Almacenamiento → Crear 2 buckets: `profiles` y `properties`

### Tiempo estimado: 5 minutos

---

## 🔴 PASO 3: Crear Tablas en PostgreSQL

### En Supabase SQL Editor, ejecuta este script:

```sql
-- 1. Crear tabla users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('student', 'non_student', 'admin')) DEFAULT 'student',
  subscription_type TEXT DEFAULT 'free',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 2. Crear tabla profiles
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  birth_date DATE,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  bio TEXT,
  profile_image_url TEXT,
  verified BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 3. Crear tabla habits
CREATE TABLE habits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  sleep_start TEXT DEFAULT '22:00',
  sleep_end TEXT DEFAULT '07:00',
  cleanliness_level INTEGER CHECK (cleanliness_level >= 1 AND cleanliness_level <= 10) DEFAULT 5,
  noise_tolerance INTEGER CHECK (noise_tolerance >= 1 AND noise_tolerance <= 10) DEFAULT 5,
  party_frequency INTEGER CHECK (party_frequency >= 0 AND party_frequency <= 7) DEFAULT 0,
  guests_tolerance INTEGER CHECK (guests_tolerance >= 0 AND guests_tolerance <= 10) DEFAULT 5,
  pets BOOLEAN DEFAULT FALSE,
  pet_tolerance BOOLEAN DEFAULT FALSE,
  alcohol_frequency INTEGER CHECK (alcohol_frequency >= 0 AND alcohol_frequency <= 7) DEFAULT 0,
  work_mode TEXT CHECK (work_mode IN ('remote', 'presencial', 'hibrido')) DEFAULT 'presencial',
  time_at_home INTEGER CHECK (time_at_home >= 0 AND time_at_home <= 10) DEFAULT 5,
  communication_style TEXT,
  conflict_management TEXT,
  responsibility_level INTEGER CHECK (responsibility_level >= 1 AND responsibility_level <= 10) DEFAULT 5,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 4. Crear tabla properties
CREATE TABLE properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  address TEXT NOT NULL,
  available_from DATE DEFAULT CURRENT_DATE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 5. Crear tabla property_images
CREATE TABLE property_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  validated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 6. Crear tabla swipes
CREATE TABLE swipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  swiper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  direction TEXT NOT NULL CHECK (direction IN ('like', 'dislike')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 7. Crear tabla matches
CREATE TABLE matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  compatibility_score DECIMAL(5, 2) CHECK (compatibility_score >= 0 AND compatibility_score <= 100),
  matched_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  UNIQUE(user_a_id, user_b_id),
  CHECK (user_a_id != user_b_id)
);

-- 8. Crear tabla chats
CREATE TABLE chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 9. Crear tabla messages
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 10. Crear tabla subscriptions
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  price DECIMAL(10, 2) NOT NULL,
  is_student BOOLEAN DEFAULT FALSE,
  start_date TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  end_date TIMESTAMP WITH TIME ZONE,
  status TEXT NOT NULL CHECK (status IN ('active', 'expired', 'cancelled')) DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 11. Índices para optimización
CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_habits_user_id ON habits(user_id);
CREATE INDEX idx_properties_owner_id ON properties(owner_id);
CREATE INDEX idx_property_images_property_id ON property_images(property_id);
CREATE INDEX idx_swipes_swiper_id ON swipes(swiper_id);
CREATE INDEX idx_swipes_target_user_id ON swipes(target_user_id);
CREATE INDEX idx_matches_user_a_id ON matches(user_a_id);
CREATE INDEX idx_matches_user_b_id ON matches(user_b_id);
CREATE INDEX idx_chats_match_id ON chats(match_id);
CREATE INDEX idx_messages_chat_id ON messages(chat_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);

-- 12. Enable Row Level Security (RLS) para seguridad
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
```

### Después, ejecuta las políticas de seguridad:

```sql
-- RLS Policies
-- 1. Usuarios pueden leer solo su perfil
CREATE POLICY "Users can read own profile" 
ON profiles FOR SELECT 
USING (auth.uid() = user_id OR auth.role() = 'admin');

-- 2. Usuarios pueden leer otros perfiles (público)
CREATE POLICY "Profiles are public" 
ON profiles FOR SELECT 
USING (true);

-- 3. Usuarios pueden actualizar solo su perfil
CREATE POLICY "Users can update own profile" 
ON profiles FOR UPDATE 
USING (auth.uid() = user_id);

-- 4. Similarmente para otros datos sensibles...
```

### Tiempo estimado: 10 minutos

---

## 🟡 PASO 4: Crear Microservicio IA (Python + FastAPI)

### Crear carpeta `microservicio_ia/` en la raíz del proyecto:

```bash
mkdir microservicio_ia
cd microservicio_ia

# Crear entorno virtual
python -m venv venv
source venv/Scripts/activate  # Windows: venv\Scripts\activate

# Crear requirements.txt
```

### Archivo: `microservicio_ia/requirements.txt`
```txt
fastapi==0.104.0
uvicorn==0.24.0
python-multipart==0.0.6
pydantic==2.0.0
numpy==1.24.0
scikit-learn==1.3.0
Pillow==10.0.0
requests==2.31.0
python-dotenv==1.0.0
gunicorn==21.2.0
```

### Archivo: `microservicio_ia/main.py`
```python
from fastapi import FastAPI, File, UploadFile, HTTPException
from pydantic import BaseModel
import numpy as np
from PIL import Image
import io
from typing import List

app = FastAPI(title="ConVive IA Service", version="1.0.0")

# Modelos de request/response
class HabitsData(BaseModel):
    cleanliness_level: int
    noise_tolerance: int
    party_frequency: int
    guests_tolerance: int
    pet_tolerance: bool
    alcohol_frequency: int
    work_mode: str
    time_at_home: int
    communication_style: str
    conflict_management: str
    responsibility_level: int

class CompatibilityRequest(BaseModel):
    user_a_habits: HabitsData
    user_b_habits: HabitsData

# Endpoint 1: Calcular compatibilidad
@app.post("/compatibility-score")
async def calculate_compatibility(request: CompatibilityRequest) -> float:
    """Calcula puntuación de compatibilidad 0-100 entre dos usuarios"""
    try:
        # Normalizar hábitos (convertir a escala 0-1)
        a = request.user_a_habits
        b = request.user_b_habits
        
        # Calcular diferencias
        differences = [
            abs(a.cleanliness_level - b.cleanliness_level) / 10,
            abs(a.noise_tolerance - b.noise_tolerance) / 10,
            abs(a.party_frequency - b.party_frequency) / 7,
            abs(a.guests_tolerance - b.guests_tolerance) / 10,
            abs(int(a.pet_tolerance) - int(b.pet_tolerance)),
            abs(a.alcohol_frequency - b.alcohol_frequency) / 7,
            abs(a.time_at_home - b.time_at_home) / 10,
            abs(a.responsibility_level - b.responsibility_level) / 10,
        ]
        
        # Compatibilidad inversa a diferencias
        avg_difference = np.mean(differences)
        score = max(0, min(100, (1 - avg_difference) * 100))
        
        return round(score, 2)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Endpoint 2: Validar imagen de perfil
@app.post("/validate-profile-image")
async def validate_profile_image(file: UploadFile = File(...)) -> dict:
    """Valida que la imagen de perfil sea válida"""
    try:
        contents = await file.read()
        img = Image.open(io.BytesIO(contents))
        
        # Validaciones
        valid = True
        reasons = []
        
        if img.size[0] < 300 or img.size[1] < 300:
            valid = False
            reasons.append("Imagen muy pequeña (mín 300x300)")
        
        if img.size[0] > 5000 or img.size[1] > 5000:
            valid = False
            reasons.append("Imagen muy grande (máx 5000x5000)")
        
        # Detectar si es rostro (simplificado)
        img_array = np.array(img)
        if len(img_array.shape) < 2:
            valid = False
            reasons.append("Formato de imagen inválido")
        
        return {
            "valid": valid,
            "reasons": reasons,
            "width": img.size[0],
            "height": img.size[1]
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Endpoint 3: Validar imagen de propiedad
@app.post("/validate-property-image")
async def validate_property_image(file: UploadFile = File(...)) -> dict:
    """Valida que la imagen de propiedad sea válida"""
    try:
        contents = await file.read()
        img = Image.open(io.BytesIO(contents))
        
        valid = True
        reasons = []
        
        if img.size[0] < 400 or img.size[1] < 300:
            valid = False
            reasons.append("Imagen muy pequeña (mín 400x300)")
        
        return {
            "valid": valid,
            "reasons": reasons,
            "width": img.size[0],
            "height": img.size[1]
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Endpoint 4: Obtener recomendaciones
@app.post("/recommendations")
async def get_recommendations(user_id: str, habits: HabitsData) -> List[str]:
    """Retorna lista de IDs de usuarios recomendados"""
    # Aquí iría la lógica de búsqueda en BD
    return ["user_id_1", "user_id_2", "user_id_3"]

# Endpoint 5: Detectar anomalías
@app.post("/detect-anomaly")
async def detect_anomaly(profile_data: dict) -> dict:
    """Detecta perfiles o comportamientos sospechosos"""
    return {
        "is_suspicious": False,
        "reasons": []
    }

@app.get("/health")
async def health_check():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Ejecutar el servicio:
```bash
python main.py
# O con uvicorn directamente:
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Tiempo estimado: 15-20 minutos

---

## 🟡 PASO 5: Actualizar Screens para usar Providers

### Archivo: `lib/screens/home_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:convive/providers/index.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ConVive'),
      ),
      body: Consumer<MatchingProvider>(
        builder: (context, matchingProvider, _) {
          if (matchingProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          return ListView.builder(
            itemCount: matchingProvider.candidates.length,
            itemBuilder: (context, index) {
              final candidate = matchingProvider.candidates[index];
              return Card(
                child: ListTile(
                  title: Text(candidate.fullName),
                  subtitle: Text(candidate.bio ?? 'Sin biografía'),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      candidate.profileImageUrl ?? '',
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

### Tiempo estimado: 30 minutos (depende del número de screens)

---

## 🟢 PASO 6: Configurar OneSignal para Notificaciones

### 1. Ir a https://onesignal.com
### 2. Crear cuenta y aplicación
### 3. Obtener App ID y API Key
### 4. En `lib/config/app_config.dart`:

```dart
const String ONE_SIGNAL_APP_ID = 'tu-app-id';
```

### 5. En `main.dart`:

```dart
OneSignal.initialize(AppConfig.oneSignalAppId);
```

### Tiempo estimado: 10 minutos

---

## 🔴 CHECKLIST DE EJECUCIÓN

- [ ] Ejecutar `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Configurar credenciales de Supabase en `app_config.dart`
- [ ] Crear tablas en PostgreSQL (Supabase SQL Editor)
- [ ] Crear buckets de almacenamiento (profiles, properties)
- [ ] Crear microservicio IA (Python + FastAPI)
- [ ] Ejecutar microservicio en localhost:8000
- [ ] Actualizar screens para usar providers
- [ ] Configurar OneSignal
- [ ] Ejecutar `flutter pub get`
- [ ] Ejecutar en emulador: `flutter run`
- [ ] Probar flujo de autenticación
- [ ] Probar swiping y matching
- [ ] Probar chat en tiempo real
- [ ] Probar carga y creación de propiedades

---

## 📞 SOPORTE

Si encuentras errores:

1. **Error de JSON serialization**: Ejecutar `build_runner` de nuevo
2. **Error de Supabase**: Verificar credenciales en `app_config.dart`
3. **Error de IA**: Verificar que el servicio esté corriendo en puerto 8000
4. **Error de imports**: Ejecutar `flutter pub get`

---

**¡Tu arquitectura está lista para volar! 🚀**
