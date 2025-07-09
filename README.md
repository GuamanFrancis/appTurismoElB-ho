UsuariosElBuho – App de Turismo en Ecuador


UsuariosElBuho es una aplicación móvil desarrollada en Flutter que promueve el turismo local en Ecuador. La app permite a los usuarios explorar sitios turísticos, compartir reseñas e imágenes, y participar como visitantes o publicadores, todo respaldado por Firebase para autenticación y almacenamiento de datos.

📱 Funcionalidades Principales
🔐 Autenticación con roles

Registro e inicio de sesión con Firebase Auth

Roles: Visitante y Publicador

Cada rol accede a funciones específicas

🌍 Gestión de Sitios Turísticos

Publicación de sitios con nombre, ubicación, descripción e imagen en formato base64

Edición y eliminación de sitios solo por el publicador correspondiente

Visualización de todos los sitios disponibles

📝 Sistema de Reseñas

Visitantes pueden dejar reseñas en los sitios

Publicadores pueden responder a las reseñas recibidas

🔎 Filtros y Navegación

Filtro por creador de contenido

Ocultación de funciones según el rol del usuario

Navegación clara entre páginas: Inicio, Sitios, Perfil, Publicar, etc.

📦 Almacenamiento Eficiente

Las imágenes se almacenan como texto base64 para evitar el uso de Firebase Storage y mantener el plan gratuito

🧱 Estructura del Proyecto

/lib
├── main.dart
├── pages/
│   ├── home_visitante.dart
│   ├── home_publicador.dart
│   ├── detalle_sitio.dart
│   ├── crear_sitio.dart
│   └── login_register/
│       ├── login.dart
│       └── register.dart
├── models/
│   ├── sitio_model.dart
│   └── reseña_model.dart
├── services/
│   ├── auth_service.dart
│   ├── sitios_service.dart
│   └── firebase_options.dart
└── widgets/
    ├── sitio_card.dart
    └── reseña_widget.dart

