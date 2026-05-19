# Topicos Mobile - AI Agent Router

## Visión General
Topicos Mobile es una aplicación Flutter que funciona como un **Agente de Inteligencia Artificial (IA) móvil**. Es capaz de interpretar lenguaje natural y ejecutar llamadas a APIs de forma autónoma. Se destaca por utilizar un modelo Llama local (Gemma) ejecutándose directamente en el dispositivo, garantizando privacidad y razonamiento offline.

## Características y Capacidades
*   **Inferencia LLM Local:** Impulsado por `llamadart`, ejecutando el modelo Gemma-2 (2B) de Google completamente en el dispositivo sin requerir internet para la etapa de "razonamiento".
*   **Patrón ReAct (Reasoning and Acting):** La IA opera de forma autónoma. Descompone instrucciones complejas del usuario, decide qué herramientas de API usar, las ejecuta en segundo plano y lee los resultados para formular el siguiente paso.
*   **Memoria Conversacional (Sliding Window):** Mantiene una ventana de contexto de las últimas 3 interacciones. Esto permite a la IA comprender referencias (ej. *"ahora elimínalo"*) sin exceder las restricciones de hardware móvil (límite de 1280 tokens y RAM).
*   **Enrutamiento Dinámico de Herramientas (Tools):** Lee las herramientas disponibles desde una especificación OpenAPI (`openapi.yaml`) y mapea dinámicamente las intenciones del usuario a métodos REST (GET, POST, PUT, DELETE).
*   **Resúmenes Automáticos:** Las respuestas largas del backend se resumen en texto corto ("Observation") antes de volver al LLM, ahorrando drásticamente recursos y tokens.
*   **Voz a Texto:** Reconocimiento de voz integrado para una experiencia de asistente manos libres.

## Stack Tecnológico
*   **Framework:** Flutter / Dart
*   **Motor AI Local:** `llamadart` (Wrapper de Llama.cpp para Dart)
*   **Modelo Recomendado:** `gemma-2-2b-it-Q4_K_M.gguf`
*   **Redes:** Paquete `http` apuntando a un Serverless API Gateway
*   **Arquitectura:** Clean Architecture / Feature-First

## Arquitectura (Feature-First)
El proyecto sigue estrictamente una **Arquitectura Feature-First** (por características), separando la infraestructura central de la lógica de negocio y la interfaz de usuario.

```text
lib/
├── core/
│   ├── ai/
│   │   └── local_llama_service.dart     # Wrapper del motor LLM (llamadart)
│   ├── network/
│   │   └── action_executor.dart         # Abstracción HTTP y resumidor de respuestas
│   └── utils/
│       └── openapi_parser.dart          # Parseador de herramientas YAML
│
├── features/
│   └── chat/
│       ├── domain/
│       │   └── models/
│       │       ├── chat_message.dart    # Modelo para la UI (burbujas)
│       │       └── memory_message.dart  # Modelo interno para el contexto de ReAct
│       │
│       ├── data/
│       │   ├── repositories/
│       │   │   └── sliding_window_memory.dart # Limitador de contexto (previene crashes OOM)
│       │   └── services/
│       │       └── react_ai_service.dart      # Orquestador del ciclo ReAct
│       │
│       └── presentation/
│           ├── screens/
│           │   └── chat_screen.dart     # Pantalla principal del Chat
│           └── widgets/
│               ├── message_bubble.dart  # Interfaz de mensajes (Markdown)
│               └── action_card.dart     # Visualización de las APIs ejecutadas
│
└── main.dart                            # Punto de entrada de la app
```

### ¿Cómo funciona el ciclo ReAct interno?
1. **Input del Usuario:** El usuario escribe o habla una instrucción (ej. *"Crea un cliente llamado Juan y regístrale una venta de 50 Bs"*).
2. **Inyección de Contexto:** El `ReactAiService` recupera el historial reciente de la `SlidingWindowMemory` y lo combina con la lista de herramientas de OpenAPI.
3. **Generación (Pensamiento):** El modelo Gemma local evalúa el contexto y genera un JSON representando las acciones API necesarias.
4. **Ejecución (Acción):** El `ActionExecutor` parsea el JSON, ejecuta las peticiones HTTP REST reales contra el backend y resume las respuestas.
5. **Observación y Recursión:** El resumen de la respuesta de la API vuelve a ingresar a la `SlidingWindowMemory` como una *Observación*. El LLM lee esta observación y decide si debe ejecutar más herramientas o devolver una respuesta final al usuario.

## Instalación y Ejecución
1. Clona este repositorio.
2. Descarga el modelo `gemma-2-2b-it-Q4_K_M.gguf` y colócalo en tu dispositivo Android en el directorio `/storage/emulated/0/Download/models/`.
3. Asegúrate de conceder el permiso **"Administrar todos los archivos"** (Manage External Storage) cuando la app lo solicite, requisito de Android 11+ para acceder al modelo en la carpeta de descargas.
4. Ejecuta `flutter pub get` seguido de `flutter run`.
