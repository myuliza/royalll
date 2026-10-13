# Funciones actuales de la app Royal

Lista de verificación levantada en la Fase 0 (rama `rediseno-app`, a partir de `dev` @ 894810b).
Al final del rediseño, cada punto tiene que seguir funcionando igual.

## Arranque y estructura
- [ ] Inicializa Firebase (web, Android, iOS, macOS y Windows; Linux no soportado).
- [ ] Al arrancar ejecuta `CatalogoSeeder.sincronizarFotosYNomenclatura()` en segundo plano (ver "Avisos").
- [ ] Estado global del carrito con `provider` (`CarritoProvider`).
- [ ] Navegación con `Navigator` (sin router con nombre); `HomeScreen` con barra inferior de 4 pestañas en `IndexedStack`: Inicio, Catálogo, Carrito y FAQ.
- [ ] Tema Material 3 claro con colores de marca (`AppColors`: negro `#0D1117` + cyan `#00B4D8`).

## Inicio (`home_screen.dart`)
- [ ] Barra superior con logo (`assets/logo royal.png`, más grande en pantallas ≥ 800 px).
- [ ] Botón candado → pantalla "Acceso empleado".
- [ ] Banner "Nueva colección / Colección para iPhone" con imagen `assets/hero_case.jpg` y botón "Ver colección" → Catálogo.
- [ ] Sección "Categorías": Clásicas, Diseños, Transparente y Ver todo (hoy todas llevan al Catálogo sin aplicar el filtro).
- [ ] "Ver todas →" en Categorías y en Más populares → Catálogo.
- [ ] "Más populares": 4 productos de Firestore en grilla de 2/3/4 columnas, con estados de error, carga y vacío ("Próximamente los productos").
- [ ] Tocar un producto abre el popup de detalle (`mostrarModalProductoDetalle`).

## Catálogo (`catalogo_screen.dart`)
- [ ] Lista en tiempo real de la colección `productos`.
- [ ] Barra superior con logo, acceso a FAQ y al Carrito.
- [ ] Buscador por nombre, código de color, hex, nombre de color, modelo y categoría, más búsqueda por familias (titanio, dorado, azul, neón, etc.). Botón para borrar la búsqueda.
- [ ] Chips de categoría: Todas, Sólido, Silicona, Transparente, Cuero, DualTek y MagSafe.
- [ ] Botón Filtros (con contador de filtros activos) → bottom sheet con modelo de iPhone (11 a 18 Pro Max), colores con selección múltiple y contador por color, "Limpiar filtros" y "Ver resultados".
- [ ] Grilla de 2/3/4 columnas (ancho máximo de 1200 px) y estado vacío "No hay fundas disponibles para estos filtros".
- [ ] Popup de detalle: categoría y color, imagen, nombre, precio con descuento (tachado y % OFF), color, stock/Agotado, "Agregar al carrito" (cierra el popup y muestra un SnackBar; respeta el stock) y "Ver detalle completo".

## Tarjeta de producto (`producto_card.dart`)
- [ ] Imagen sobre fondo suave, badge "-X% OFF", badge de personalizable (pincel), punto de color, categoría y color, nombre y precio (con el original tachado si hay descuento).

## Detalle de producto (`producto_detalle_screen.dart`)
- [ ] Imagen grande, categoría, color, stock, nombre y precios con descuento.
- [ ] Color con muestra y nombre legible.
- [ ] Chips de modelos compatibles.
- [ ] Aviso de "personalizable" (se coordina por WhatsApp).
- [ ] Botón fijo "Agregar al carrito": vibración, cierra la pantalla y muestra un SnackBar con "Ver carrito". Si se alcanzó el stock máximo, muestra un aviso naranja. Deshabilitado si está agotado.

## Imágenes (`app_product_image.dart`)
- [ ] Soporta assets locales (`assets/…`; corrige `.png` a `.jpg`) y URLs http/https.
- [ ] Indicador de carga con porcentaje y, si falla o la URL no es válida, un placeholder con ícono de iPhone.

## Carrito (`carrito_screen.dart` + `carrito_provider.dart`)
- [ ] Lista de ítems con − / cantidad / +, sin superar el stock (avisa con un SnackBar).
- [ ] Eliminar un ítem con "Deshacer" (restaura la cantidad).
- [ ] Bajar de 1 a 0 elimina el ítem (con Deshacer).
- [ ] Campo "Código promocional" + Aplicar: busca `cupones/{CODIGO}` y valida vigencia (`vigenciaHasta`) y usos (`usosActuales < usosMaximos`). Mensajes: no encontrado, vencido/sin usos, error.
- [ ] Cupón de porcentaje o de monto fijo.
- [ ] Resumen fijo abajo: Subtotal, Descuento (código), Total y "Continuar al pedido".
- [ ] Estado vacío "Tu carrito está vacío".

## Checkout (`checkout_screen.dart`)
- [ ] Formulario: nombre (obligatorio) y forma de pago (Efectivo o Transferencia).
- [ ] Transacción en Firestore: verifica que cada producto exista y tenga stock suficiente, descuenta el stock y suma 1 a `usosActuales` del cupón.
- [ ] Arma el mensaje de WhatsApp (ítems, cupón, total, cliente y pago) y abre `wa.me/595991345198`.
- [ ] Si se abre WhatsApp, vacía el carrito y vuelve al inicio. Muestra errores (stock insuficiente, etc.).
- [ ] Bloquea "atrás" mientras procesa.
- [ ] **No** guarda el pedido ni la venta en Firestore.

## FAQ (`faq_screen.dart`)
- [ ] 5 preguntas estándar (Pagos, Envíos, Garantía, Compatibilidad y Personalización) más las de la colección `faq` de Firestore (sin duplicados).
- [ ] Banner "¿Tenés dudas?" y tarjetas expandibles con ícono, pregunta, categoría y respuesta.
- [ ] Tarjeta "Contactar por WhatsApp".

## Acceso empleado (`empleado_login_screen.dart`)
- [ ] Login con email y contraseña (Firebase Auth); Enter envía.
- [ ] Verifica que `users/{uid}.role` sea `employee` o `admin`; si no, cierra la sesión y muestra "Acceso denegado".
- [ ] Mensajes de error (credenciales incorrectas, etc.) e indicador de carga.
- [ ] Si todo está bien, reemplaza la pantalla por el Panel de empleado.

## Panel de empleado (`empleado_dashboard_screen.dart`)
- [ ] Barra superior: Mantenimiento de datos y Cerrar sesión.
- [ ] FAB "Nueva Funda".
- [ ] Navegación Servicios / Productos: rail en pantallas ≥ 840 px y barra inferior en las más chicas. "Atrás" desde Productos vuelve a Servicios.
- [ ] **Servicios**: 4 tarjetas con contador (Fundas, Sin stock, Stock bajo ≤ 3, En descuento) que llevan a Productos con el filtro aplicado.
- [ ] **Servicios**: 8 accesos rápidos (Nueva funda, Productos, Buscar con foco en el buscador, Sólidas, Transparentes, Personalizadas, Mantenimiento y Cerrar sesión).
- [ ] **Productos**: buscador (nombre, código, hex, categoría y modelo), chips de categoría (Todas, Color sólido, Transparente, Personalizada) y chip removible del filtro especial.
- [ ] **Productos**: tarjeta editable por producto con nombre, código de color y URL de foto. Se guarda al salir del campo, con Enter o con ✓. El nombre se normaliza a "Funda iPhone …".
- [ ] **Productos**: vista previa de la foto en vivo y diálogo "Cambiar Foto" (URL + fotos sugeridas por color; valida http/https).
- [ ] **Productos**: editar stock en un diálogo (no permite menos de 0).
- [ ] **Productos**: switch de descuento y diálogo de porcentaje (atajos 10/15/20/25/30/50 %).
- [ ] **Productos**: estado vacío con "Agregar la primera funda".
- [ ] **Nueva funda** (bottom sheet): modelo, nombre, color de la paleta (autocompleta foto y código), código de color, categoría, precio, stock y URL de foto con vista previa. Valida los datos y crea el producto en `productos`.
- [ ] **Mantenimiento**: "Limpiar duplicados en Firestore".
- [ ] Al cambiar de sección se quita el foco (dispara el guardado de las tarjetas).
- [ ] Cerrar sesión hace signOut y vuelve atrás.

## Firestore (reglas actuales en `firestore.rules`)
- `productos`: lectura pública. Escribe solo un empleado; un cliente solo puede bajar el `stock`.
- `cupones`: lectura pública. Escribe solo un empleado; un cliente solo puede sumar 1 a `usosActuales`.
- `faq`: lectura pública y escritura solo de empleados.
- `users`: cada usuario puede leer su propio perfil; escriben solo los empleados.
- `pedidos`: cualquiera puede crear; leer y gestionar, solo empleados (la app hoy no lo usa).

## Avisos detectados (no son parte del rediseño)
1. **La sincronización al arrancar escribe en Firestore.** `sincronizarFotosYNomenclatura()` pisa `nombre`, `categoria`, `colorHex`, `codigoColor` y `modelosCompatibles` de **todos** los productos con los valores semilla cada vez que se abre la app. Para un cliente sin sesión las reglas lo rechazan; con un empleado logueado (en web la sesión persiste) se ejecuta y **puede deshacer las ediciones del panel**.
2. Las categorías no coinciden entre pantallas: el Catálogo usa solido/silicona/transparente/cuero/dualtek/magsafe, mientras que el panel y el Inicio usan solido/transparente/personalizada.
3. El checkout incrementa los usos del cupón sin volver a validarlo dentro de la transacción.
4. El popup de detalle está duplicado (`catalogo_screen.dart` y `producto_card.dart`).
5. No existe un registro de ventas: el checkout no escribe en `pedidos`.
