# 📖 Video Publishing Pipeline - Runbook

Guía completa para configurar, desplegar y mantener el sistema de publicación automática de vídeos.

## 📑 Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Instalación Inicial](#instalación-inicial)
3. [Configuración de APIs](#configuración-de-apis)
4. [Configuración de Google Drive](#configuración-de-google-drive)
5. [Configuración de n8n](#configuración-de-n8n)
6. [Personalización de Branding](#personalización-de-branding)
7. [Despliegue en Raspberry Pi](#despliegue-en-raspberry-pi)
8. [Uso del Sistema](#uso-del-sistema)
9. [Troubleshooting](#troubleshooting)
10. [Mantenimiento](#mantenimiento)

---

## Requisitos Previos

### Software necesario:
- Docker y Docker Compose
- Git
- Cuenta de Google con Google Drive
- Cuenta de YouTube
- Cuenta de TikTok Business

### Hardware recomendado:
- **PC/Laptop**: 8GB RAM, 50GB espacio libre
- **Raspberry Pi**: Modelo 4/5, 4GB RAM mínimo, 64GB SD Card

---

## Instalación Inicial

### 1. Clonar o crear el proyecto

```bash
cd ~/proyectos
mkdir autoVideos
cd autoVideos
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env
nano .env  # o usa tu editor favorito
```

Completa todas las variables (las configuraremos en las siguientes secciones).

### 3. Crear directorios necesarios

```bash
mkdir -p output temp
```

---

## Configuración de APIs

### 🎥 YouTube Data API v3

#### Paso 1: Crear proyecto en Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Nombre sugerido: "Video Publishing Pipeline"

#### Paso 2: Habilitar YouTube Data API v3

1. En el menú lateral, ve a **APIs & Services** > **Library**
2. Busca "YouTube Data API v3"
3. Haz clic en **Enable**

#### Paso 3: Crear credenciales OAuth 2.0

1. Ve a **APIs & Services** > **Credentials**
2. Haz clic en **Create Credentials** > **OAuth client ID**
3. Si es tu primera vez, configura la pantalla de consentimiento:
   - User Type: **External**
   - App name: "Video Pipeline"
   - Support email: tu email
   - Developer contact: tu email
4. Añade scopes:
   - `https://www.googleapis.com/auth/youtube.upload`
   - `https://www.googleapis.com/auth/youtube`
5. Crear OAuth client ID:
   - Application type: **Desktop app**
   - Name: "Video Uploader"
6. Descarga el JSON o copia Client ID y Client Secret

#### Paso 4: Obtener Refresh Token

Opción A - Usar OAuth Playground:

1. Ve a [OAuth 2.0 Playground](https://developers.google.com/oauthplayground/)
2. Haz clic en el ⚙️ (settings) arriba a la derecha
3. Marca "Use your own OAuth credentials"
4. Pega tu Client ID y Client Secret
5. En el panel izquierdo, busca "YouTube Data API v3"
6. Selecciona los scopes necesarios
7. Haz clic en "Authorize APIs"
8. Inicia sesión con tu cuenta de YouTube
9. En "Step 2", haz clic en "Exchange authorization code for tokens"
10. Copia el **Refresh Token**

Opción B - Usar script Node.js:

```bash
cd scripts
npm install
node get-youtube-token.js
```

#### Paso 5: Añadir credenciales al .env

```bash
YOUTUBE_CLIENT_ID=tu_client_id_aqui
YOUTUBE_CLIENT_SECRET=tu_client_secret_aqui
YOUTUBE_REFRESH_TOKEN=tu_refresh_token_aqui
```

### 📱 TikTok Content Posting API

#### Paso 1: Crear aplicación TikTok

1. Ve a [TikTok for Developers](https://developers.tiktok.com/)
2. Inicia sesión con tu cuenta TikTok Business
3. Haz clic en **Create App** o **Manage Apps**
4. Completa la información:
   - App name: "Video Auto Publisher"
   - App description: "Automated video publishing"
   - Category: Content Creation

#### Paso 2: Solicitar acceso a Content Posting API

1. En tu aplicación, ve a **Add Products**
2. Busca "Content Posting API"
3. Solicita acceso (puede tardar varios días en ser aprobado)
4. **Nota**: Mientras esperas aprobación, los vídeos se crearán como borradores

#### Paso 3: Configurar credenciales

1. En tu app, ve a **Basic Information**
2. Copia **Client Key** y **Client Secret**
3. Ve a **Authorization** para generar Access Token

#### Paso 4: Generar Access Token

TikTok usa OAuth 2.0. Necesitas implementar el flujo de autorización:

1. URL de autorización:
```
https://www.tiktok.com/v2/auth/authorize/
?client_key=YOUR_CLIENT_KEY
&scope=video.upload,video.publish
&response_type=code
&redirect_uri=YOUR_REDIRECT_URI
```

2. Después de autorizar, obtendrás un código
3. Intercambia el código por access token:

```bash
curl -X POST https://open.tiktokapis.com/v2/oauth/token/ \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_key=YOUR_CLIENT_KEY" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "code=YOUR_AUTH_CODE" \
  -d "grant_type=authorization_code"
```

#### Paso 5: Añadir credenciales al .env

```bash
TIKTOK_CLIENT_KEY=tu_client_key_aqui
TIKTOK_CLIENT_SECRET=tu_client_secret_aqui
TIKTOK_ACCESS_TOKEN=tu_access_token_aqui
```

**⚠️ Importante**: Los tokens de TikTok expiran. Implementa un refresh mechanism o actualízalos manualmente cuando sea necesario.

---

## Configuración de Google Drive

### Paso 1: Crear carpeta específica

1. Abre [Google Drive](https://drive.google.com)
2. Crea una carpeta: **NotebookLM** > **exports**
3. Copia el ID de la carpeta desde la URL:
   - URL: `https://drive.google.com/drive/folders/FOLDER_ID_HERE`
   - Ejemplo: `1aBcDeFgHiJkLmNoPqRsTuVwXyZ`

### Paso 2: Configurar OAuth para Google Drive

Si aún no lo has hecho en la configuración de YouTube:

1. En Google Cloud Console, habilita **Google Drive API**
2. Usa las mismas credenciales OAuth que creaste para YouTube
3. Asegúrate de añadir el scope:
   - `https://www.googleapis.com/auth/drive.readonly`

### Paso 3: Añadir ID de carpeta al .env

```bash
GOOGLE_DRIVE_FOLDER_ID=tu_folder_id_aqui
GOOGLE_CLIENT_ID=tu_google_client_id
GOOGLE_CLIENT_SECRET=tu_google_client_secret
GOOGLE_REFRESH_TOKEN=tu_google_refresh_token
```

---

## Configuración de n8n

### Paso 1: Iniciar n8n por primera vez

```bash
docker-compose up -d n8n
```

### Paso 2: Acceder a la interfaz web

1. Abre tu navegador en: http://localhost:5678
2. Crea una cuenta (usuario y contraseña que definiste en .env)

### Paso 3: Importar el flujo

1. En n8n, haz clic en el menú **Workflows**
2. Selecciona **Import from File**
3. Selecciona el archivo: `n8n/video-pipeline-flow.json`
4. El flujo se cargará con todos los nodos configurados

### Paso 4: Configurar credenciales

#### Google Drive:

1. Haz clic en el nodo **Google Drive Trigger**
2. Clic en **Create New Credential**
3. Selecciona **OAuth2**
4. Pega tu Client ID, Client Secret y Refresh Token
5. Haz clic en **Connect my account**
6. Autoriza el acceso

#### Discord (opcional):

1. Crea un webhook en tu servidor Discord:
   - Settings > Integrations > Webhooks > New Webhook
2. Copia la URL del webhook
3. En n8n, configura el credential con esta URL

#### Telegram (opcional):

1. Habla con [@BotFather](https://t.me/botfather) en Telegram
2. Crea un nuevo bot con `/newbot`
3. Copia el token que te da
4. Obtén tu Chat ID:
   - Envía un mensaje a tu bot
   - Visita: `https://api.telegram.org/botTOKEN/getUpdates`
   - Busca tu "chat": {"id": 123456}

### Paso 5: Activar el workflow

1. En el flujo importado, haz clic en el toggle **Inactive/Active** arriba a la derecha
2. El flujo ahora estará escuchando cambios en Google Drive

---

## Personalización de Branding

### Crear intro y outro

1. Usa tu editor de vídeo favorito (Premiere, DaVinci Resolve, CapCut, etc.)
2. Crea vídeos de 3-5 segundos:
   - **intro.mp4**: Logo animado, texto de bienvenida
   - **outro.mp4**: Call-to-action, enlaces, suscripción
3. Especificaciones:
   - Resolución: 1920x1080
   - FPS: 30
   - Codec: H.264
   - Audio: AAC, 192kbps

### Colocar archivos en templates/

```bash
cp mi_intro.mp4 templates/intro.mp4
cp mi_outro.mp4 templates/outro.mp4
```

### Configurar metadatos

Edita `templates/metadata.json`:

```json
{
  "title": "Tu título predeterminado",
  "description": "Tu descripción con enlaces y timestamps",
  "tags": ["tus", "tags", "aquí"],
  "categoryId": "22",
  "privacyStatus": "public"
}
```

**Categorías de YouTube comunes:**
- 22: People & Blogs
- 24: Entertainment
- 27: Education
- 28: Science & Technology

### Crear miniatura personalizada

1. Diseña una miniatura 1280x720 en Canva, Photoshop, etc.
2. Guárdala como `templates/thumbnail.jpg`
3. Asegúrate de referenciarla en metadata.json

---

## Despliegue en Raspberry Pi

### Preparación de la Raspberry Pi

#### Paso 1: Instalar Raspberry Pi OS (64-bit)

1. Descarga [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Selecciona **Raspberry Pi OS Lite (64-bit)**
3. Configura SSH y WiFi en las opciones avanzadas
4. Graba la imagen en la SD Card

#### Paso 2: Actualizar el sistema

```bash
ssh pi@raspberrypi.local
sudo apt update && sudo apt upgrade -y
```

#### Paso 3: Instalar Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

Cierra sesión y vuelve a conectar para que los cambios surtan efecto.

#### Paso 4: Instalar Docker Compose

```bash
sudo apt install docker-compose -y
```

### Transferir el proyecto

#### Opción A: Usar Git

```bash
git clone https://github.com/tu-usuario/autoVideos.git
cd autoVideos
```

#### Opción B: Transferir vía SCP

Desde tu PC:

```bash
scp -r autoVideos pi@raspberrypi.local:~/
```

### Configurar para ARM64

Edita `docker-compose.yml`:

```yaml
# Cambiar:
platform: linux/amd64

# Por:
platform: linux/arm64
```

O usa esta variable de entorno:

```bash
export DOCKER_DEFAULT_PLATFORM=linux/arm64
```

### Ajustar recursos

La Raspberry Pi tiene menos recursos. Edita `.env`:

```bash
# Reducir calidad de vídeo si es necesario
VIDEO_BITRATE=3000k  # En lugar de 5000k
```

### Iniciar servicios

```bash
cp .env.example .env
nano .env  # Configura tus credenciales

# Construir imágenes (primera vez, tarda más en ARM)
docker-compose build

# Iniciar servicios
docker-compose up -d
```

### Verificar estado

```bash
docker-compose ps
docker-compose logs -f
```

### Configurar inicio automático

```bash
sudo nano /etc/systemd/system/video-pipeline.service
```

Contenido:

```ini
[Unit]
Description=Video Publishing Pipeline
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/pi/autoVideos
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
User=pi

[Install]
WantedBy=multi-user.target
```

Habilitar:

```bash
sudo systemctl enable video-pipeline.service
sudo systemctl start video-pipeline.service
```

---

## Uso del Sistema

### Flujo de trabajo normal

1. **Genera tu vídeo en NotebookLM**
   - Crea tu contenido en NotebookLM
   - Genera el audio/vídeo

2. **Sube el vídeo a Google Drive**
   - Ve a Google Drive > NotebookLM > exports
   - Arrastra y suelta el archivo .mp4
   - Opcionalmente, sube un archivo .srt con subtítulos (mismo nombre)

3. **El sistema detecta automáticamente**
   - n8n detecta el nuevo archivo
   - Descarga el vídeo
   - Procesa con FFmpeg (intro + vídeo + outro)
   - Genera versión YouTube (16:9)
   - Genera versión TikTok (9:16)
   - Sube a ambas plataformas
   - Te notifica el resultado

4. **Recibe notificaciones**
   - Discord y/o Telegram te informarán del éxito
   - Incluye enlaces a los vídeos publicados

### Monitorear el progreso

#### Ver logs en tiempo real:

```bash
docker-compose logs -f
```

#### Ver logs de un servicio específico:

```bash
docker-compose logs -f n8n
docker-compose logs -f ffmpeg-processor
docker-compose logs -f node-scripts
```

#### Ver ejecuciones en n8n:

1. Abre http://localhost:5678
2. Ve a **Executions** en el menú lateral
3. Revisa el historial de ejecuciones

---

## Troubleshooting

### Problema: n8n no detecta nuevos archivos

**Solución:**
1. Verifica que el workflow esté activo (toggle verde)
2. Revisa las credenciales de Google Drive
3. Confirma que el FOLDER_ID sea correcto
4. Verifica logs: `docker-compose logs n8n`

### Problema: FFmpeg falla al procesar

**Síntomas:** Error en logs de ffmpeg-processor

**Soluciones:**
- Verifica que intro.mp4 y outro.mp4 existan (o bórralos si no quieres usarlos)
- Confirma que el vídeo de entrada sea válido
- Revisa espacio en disco: `df -h`
- Logs detallados: `docker-compose logs ffmpeg-processor`

### Problema: Upload a YouTube falla

**Causas comunes:**
- Refresh token expirado → Genera uno nuevo
- Cuota API excedida → Espera 24 horas
- Vídeo muy grande → Verifica tamaño (< 256GB)
- Copyright claim → Revisa contenido

**Solución:**
```bash
docker-compose logs node-scripts
# Busca el error específico de YouTube API
```

### Problema: Upload a TikTok falla o crea draft

**Nota:** Esto es normal si no tienes Content Posting API aprobada.

**Soluciones:**
- Verifica que tu app tenga Content Posting API aprobada
- Actualiza access token si expiró
- El sistema creará drafts que puedes publicar manualmente

### Problema: Contenedores no inician en Raspberry Pi

**Soluciones:**
1. Verifica arquitectura: `docker-compose config`
2. Cambia platform a `linux/arm64`
3. Reduce recursos en .env
4. Verifica espacio: `df -h`

### Problema: Memoria insuficiente

**Síntomas:** Contenedores se cierran inesperadamente

**Soluciones:**
```bash
# Ver uso de memoria
docker stats

# Reducir calidad de vídeo en .env
VIDEO_BITRATE=2000k

# Procesar un vídeo a la vez
# (Modificar n8n flow para no procesar en paralelo)
```

---

## Mantenimiento

### Actualizaciones regulares

```bash
# Actualizar imágenes Docker
docker-compose pull

# Reconstruir con cambios
docker-compose build --no-cache

# Reiniciar servicios
docker-compose down
docker-compose up -d
```

### Limpieza de archivos temporales

```bash
# Limpiar archivos procesados (más de 7 días)
find output/ -name "*.mp4" -mtime +7 -delete
find temp/ -type f -mtime +1 -delete

# Limpiar imágenes Docker no usadas
docker system prune -a
```

### Backup de configuración

```bash
# Backup completo
tar -czf backup-video-pipeline-$(date +%Y%m%d).tar.gz \
  .env \
  templates/ \
  n8n/

# Restaurar
tar -xzf backup-video-pipeline-YYYYMMDD.tar.gz
```

### Monitoreo de cuotas API

- **YouTube**: 10,000 unidades/día
  - Upload = 1600 unidades
  - ~6 vídeos/día máximo

- **TikTok**: Depende de tu plan y aprobación

### Renovar tokens

Los tokens expiran. Configura recordatorios:

- **YouTube Refresh Token**: No expira (pero puede revocarse)
- **TikTok Access Token**: Expira cada 24 horas (implementa refresh)
- **Google Drive**: Similar a YouTube

---

## Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────┐
│                     Google Drive                         │
│                 NotebookLM/exports/*.mp4                │
└───────────────────────┬─────────────────────────────────┘
                        │ Webhook/Trigger
                        ▼
┌─────────────────────────────────────────────────────────┐
│                        n8n                               │
│  ┌──────────┬─────────┬──────────┬──────────────────┐  │
│  │ Detect   │Download │ Process  │ Upload & Notify  │  │
│  │ New File │ Video   │ Metadata │ to Platforms     │  │
│  └──────────┴─────────┴──────────┴──────────────────┘  │
└──────┬────────────────────────┬────────────────────┬───┘
       │                        │                    │
       ▼                        ▼                    ▼
┌──────────────┐    ┌──────────────────┐   ┌──────────────┐
│   FFmpeg     │    │  Node Scripts    │   │Notifications │
│  Processor   │    │  - YouTube       │   │ - Discord    │
│              │    │  - TikTok        │   │ - Telegram   │
│ • Normalize  │    │                  │   │              │
│ • Add intro  │    │ TypeScript       │   └──────────────┘
│ • Add outro  │    │ Upload Scripts   │
│ • 16:9 vers  │    │                  │
│ • 9:16 vers  │    └──────────────────┘
└──────────────┘
```

---

## Soporte y Contribuciones

### Obtener ayuda

1. Revisa primero esta documentación
2. Verifica logs: `docker-compose logs -f`
3. Busca en issues de GitHub (si es open source)

### Mejoras futuras

- [ ] Generación automática de miniaturas con IA
- [ ] Integración con Instagram Reels
- [ ] Análisis de rendimiento de vídeos
- [ ] Programación de publicaciones
- [ ] Multi-cuenta support

---

**¡Tu pipeline está listo! 🎉**

Ahora solo sube tus vídeos de NotebookLM a Google Drive y deja que el sistema haga el resto.
