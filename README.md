# Royal — Frontend Flutter, paso a paso

Este paquete trae la estructura del frontend ya armada. No pude correr `flutter create`
ni compilar nada en este entorno (no tiene el SDK de Flutter instalado), así que estos
son los archivos fuente listos para meter en tu proyecto local.

## Pasos para integrarlo

1. **Instalá Flutter** (si no lo tenés): flutter.dev → descargar → agregar al PATH →
   correr `flutter doctor` para confirmar que todo está OK.

2. **Creá el proyecto base:**
   ```
   flutter create royal_app
   cd royal_app
   ```

3. **Reemplazá `pubspec.yaml`** por el que está en este paquete (agrega Firebase,
   provider, url_launcher y cached_network_image).
   ```
   flutter pub get
   ```

4. **Copiá la carpeta `lib/`** de este paquete sobre la `lib/` que generó `flutter create`
   (vas a pisar el `main.dart` de ejemplo, es lo esperado).

5. **Conectá Firebase** (todavía no lo hicimos, porque necesita tu cuenta):
   ```
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Esto genera automáticamente `lib/firebase_options.dart`, que es el que
   importa `main.dart`. Sin este paso la app no va a compilar.

6. **Creá las colecciones en Firestore** (`productos`, `categorias`, `modelos`,
   `cupones`, `faq`) siguiendo la estructura de `models/producto.dart` y
   `models/cupon.dart` — los nombres de campo tienen que coincidir exactamente.

7. **Poné tu número de WhatsApp real** en
   `lib/screens/checkout_screen.dart`, constante `kWhatsappNumeroRoyal`
   (formato internacional sin '+', ej. `595981234567`).

8. **Corré la app:**
   ```
   flutter run
   ```

## Qué incluye cada archivo

| Archivo | Qué hace |
|---|---|
| `theme/app_theme.dart` | Colores dorado/azul, tipografía y estilos de botones/inputs de toda la app |
| `models/producto.dart` | Modelo de datos de una funda + formateo de precio en Gs |
| `models/cupon.dart` | Modelo de cupón + validación de vigencia y cálculo de descuento |
| `providers/carrito_provider.dart` | Estado global del carrito (agregar, quitar, cupón, totales) |
| `widgets/producto_card.dart` | Tarjeta de producto usada en la grilla del catálogo |
| `screens/catalogo_screen.dart` | Pantalla principal: grilla de productos + filtros de categoría y modelo |
| `screens/producto_detalle_screen.dart` | Ficha de producto con botón "Agregar al carrito" |
| `screens/carrito_screen.dart` | Carrito con cantidades, campo de cupón y resumen de totales |
| `screens/checkout_screen.dart` | Formulario de nombre/forma de pago → abre WhatsApp con el pedido armado |
| `screens/faq_screen.dart` | Lista expandible de preguntas frecuentes desde Firestore |

## Lo que falta después de esto

- Conectar Firebase real (paso 5) y cargar productos de prueba en Firestore para ver
  la grilla funcionando.
- Pantalla de login/admin si en algún momento vas a cargar productos desde la app
  en vez de manualmente en Firestore Console.
- Ajustar el diseño fino (logo, íconos propios, splash screen) una vez que tengas
  el nombre y las fotos definitivas.
- Build de producción: `flutter build web` (para Hosting) y `flutter build appbundle`
  (para Google Play).
