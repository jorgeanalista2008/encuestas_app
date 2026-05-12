# 🌟 Encuestas App

**Encuestas App** es una aplicación móvil desarrollada en **Flutter** que permite a los usuarios **crear, responder y gestionar encuestas** de manera local. La aplicación está diseñada para ser **intuitiva y eficiente**, con soporte para **exportar datos** y almacenar respuestas de usuarios.

---

## 🚀 Características

- 📝 **Creación de encuestas**: Los usuarios pueden crear encuestas personalizadas con preguntas de diferentes tipos (texto, opción múltiple, etc.).
- 📊 **Gestión de respuestas**: Almacena respuestas de usuarios con detalles como fecha y nombre.
- 📤 **Exportación de datos**: Exporta encuestas y respuestas en formato CSV.
- 🎨 **Interfaz moderna**: Diseñada con colores corporativos y componentes visuales atractivos.

---

## 🛠️ Tecnologías utilizadas

- **Flutter**: Framework principal para el desarrollo de la aplicación.
- **Sqflite**: Base de datos local para almacenar encuestas y respuestas.
- **Path Provider**: Para gestionar rutas de almacenamiento.
- **Share Plus**: Para compartir archivos exportados.
- **Intl**: Para la gestión de fechas y localización.

---

## 📂 Estructura del proyecto

- **lib/**: Contiene el código fuente principal.
  - **main.dart**: Punto de entrada de la aplicación.
  - **screens/**: Pantallas principales como Home, Crear Encuesta, Responder Encuesta, etc.
  - **database/**: Lógica para la gestión de la base de datos local.
  - **models/**: Modelos de datos como `Encuesta` y `Pregunta`.
  - **services/**: Servicios auxiliares como exportación de datos.
- **assets/**: Recursos estáticos como imágenes e íconos.

---

## ⚙️ Instalación y configuración

1. **Clona este repositorio:**

   ```bash
   git clone https://github.com/tu_usuario/encuestas_app.git
   ```

2. **Navega al directorio del proyecto:**

   ```bash
   cd encuestas_app
   ```

3. **Instala las dependencias:**

   ```bash
   flutter pub get
   ```

4. **Ejecuta la aplicación:**

   ```bash
   flutter run
   ```

---

## 📸 Capturas de pantalla

_Agrega aquí capturas de pantalla de la aplicación._

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Si deseas contribuir, por favor sigue los siguientes pasos:

1. Haz un **fork** del proyecto.
2. Crea una rama para tu función (`git checkout -b feature/nueva-funcion`).
3. Realiza tus cambios y haz commit (`git commit -m 'Agrega nueva función'`).
4. Sube tus cambios (`git push origin feature/nueva-funcion`).
5. Abre un **Pull Request**.

---

## 📜 Licencia

Este proyecto está bajo la licencia **MIT**. Consulta el archivo `LICENSE` para más detalles.
