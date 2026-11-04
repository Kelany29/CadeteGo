# CadeteGO 🛵
**Proyecto Final - Evaluación Integradora Unidad 4 (Desarrollo de Software)**

CadeteGO es una aplicación móvil desarrollada como Producto Mínimo Viable (MVP) para optimizar la logística de entregas de comercios locales. Permite a los repartidores visualizar sus rutas, cambiar el estado de los pedidos y gestionar sus despachos sin depender de mensajería informal.

## 📌 Avances - Hito 1 y 2 (04/11)

Durante esta etapa se establecieron las bases tecnológicas, la arquitectura de la interfaz y la conexión al backend remoto:

- ✅ **Elección Tecnológica y Entorno:** Configuración inicial del proyecto multiplataforma utilizando **Flutter (Dart)**.
- ✅ **Arquitectura de Interfaz:** Modularización del código base implementando buenas prácticas (separación de la lógica y la UI en la carpeta `/screens`).
- ✅ **Desarrollo UI (Primeras Pantallas):** 
  - `LoginScreen` y `RegisterScreen` (con validación de formularios mediante `FormState`).
  - `HomeScreen` (Dashboard simulado de pedidos).
  - `DetalleScreen` (Vista profunda de la orden).
  - `PerfilScreen` (Gestión de sesión).
- ✅ **Integración de Backend y Base de Datos:**
  - Configuración inicial de **Supabase** (PostgreSQL).
  - Implementación del paquete `supabase_flutter`.
  - Conexión exitosa del servicio de Autenticación (`auth.signUp` y `auth.signInWithPassword`), incluyendo el envío de correos de confirmación.

## 🛠️ Tecnologías utilizadas hasta el momento
* **Frontend:** Flutter & Dart
* **Backend as a Service:** Supabase
* **Control de Versiones:** Git & GitHub

## 🚀 Cómo ejecutar el proyecto
1. Clonar el repositorio: `git clone https://github.com/Kelany29/CadeteGo.git`
2. Instalar las dependencias: `flutter pub get`
3. Ejecutar en emulador o Chrome: `flutter run`
