# Funciones actuales de la app Royal

Lista de verificación levantada en la Fase 0 (rama `rediseno-app`, a partir de `dev` @ 894810b)
y repasada en la Fase 6.

**Cómo se verificó cada punto**
- ✅ **Test**: cubierto por un test automático (`flutter test`, 133 tests).
- ✅ **Código**: la lógica no cambió; solo se movió o se cambió el aspecto (revisado línea por línea).
- 🔶 **Manual**: depende de Firebase real, WhatsApp o una cuenta de empleado. Hay que probarlo a mano (ver la lista al final).

## Arranque y estructura
- ✅ Código · Inicializa Firebase (web, Android, iOS, macOS y Windows). Compila en web y en Windows.
- ✅ Código · Al arrancar ejecuta `sincronizarFotosYNomenclatura()`, igual que antes. Con `--dart-define=SIN_SYNC=true` se omite (solo para pruebas).
- ✅ Test · Estado global del carrito con `provider`.
- ✅ Test · **Cambio:** las 4 pestañas de la barra inferior ahora son secciones del router, con barra lateral en escritorio y tablet y barra inferior en móvil. Se agregó la sección Empleados.
- ✅ Test · Tema con colores de marca: ahora claro **y oscuro**, con botón sol/luna.

## Inicio
- ✅ Test · Logo en la barra superior (más grande en escritorio).
- ✅ Test · Candado → Acceso empleado (ahora es la sección Empleados).
- ✅ Test · Banner "Nueva colección / Colección para iPhone" con imagen y "Ver colección" → Catálogo (ahora es una tarjeta compacta).
- ✅ Test · Categorías: Clásicas, Transparente, etc., y Ver todo. **Mejora:** ahora aplican el filtro en el Catálogo. "Diseños" (personalizada) se muestra solo si hay productos de esa categoría; hoy no hay.
- ✅ Test · "Ver todas" en Categorías y en Más populares → Catálogo.
- ✅ Test · Más populares (ahora hasta 8) con estados de error, carga (esqueleto) y vacío.
- ✅ Test · Tocar un producto abre el detalle.

## Catálogo
- ✅ Código · Lista en tiempo real de `productos`.
- ✅ Test · Acceso a FAQ y Carrito (ahora desde la barra lateral o inferior y la barra superior).
- ✅ Test · Buscador por nombre, código, hex, color, modelo y categoría, más familias de colores (la lógica es la misma). Ahora es el buscador global de la barra superior; en móvil está dentro del catálogo.
- ✅ Test · Chips de categoría (ahora con cantidad).
- ✅ Test · Botón Filtros con contador → bottom sheet con modelo, colores múltiples, "Limpiar filtros" y "Ver resultados".
- ✅ Test · Grilla adaptable y estado vacío (ahora con el botón "Limpiar filtros").
- ✅ Test · Detalle con agregar al carrito, cierre automático, SnackBar y respeto del stock.
- **Nuevo:** chips de Modelo y Orden, filtros rápidos (Ofertas, Nuevos modelos, Personalizables), "Limpiar" y filtros reflejados en la URL.

## Tarjeta de producto
- ✅ Test · Imagen, badge de % OFF, badge de personalizable, punto de color, categoría y color, nombre y precio con el original tachado. Ahora con hover y foco con teclado.

## Detalle de producto
- ✅ Test · Imagen, categoría, color, stock, nombre, precios y descuento.
- ✅ Test · Color con muestra y nombre legible; modelos compatibles; aviso de personalizable.
- ✅ Test · "Agregar al carrito": cierra el detalle y muestra un SnackBar con "Ver carrito". Avisa si se alcanzó el stock máximo y está deshabilitado si el producto está agotado.
- **Cambio:** en escritorio y tablet es un diálogo de 2 columnas con toda la información, y en móvil es pantalla completa. El popup compacto anterior y su enlace "Ver detalle completo" se unificaron en esta vista.

## Imágenes
- ✅ Test · Assets locales (incluida la corrección de `.png` a `.jpg`) y URLs http/https.
- ✅ Código · Carga con esqueleto y porcentaje, aparición suave y placeholder con ícono si falla.

## Carrito
- ✅ Test · Selector − / cantidad / + que respeta el stock.
- ✅ Test · Eliminar con "Deshacer".
- ✅ Código · Bajar de 1 a 0 elimina el ítem (con Deshacer).
- 🔶 Manual · Código promocional + Aplicar (lee `cupones/{CODIGO}`). Ahora valida que el código exista, esté activo, vigente (inicio y fin), tenga usos disponibles, cumpla la compra mínima y aplique a los productos, con un mensaje claro para cada caso. La lógica de cálculo está cubierta por tests.
- ✅ Test · Porcentaje y monto fijo (el monto fijo nunca supera lo que aplica).
- ✅ Test · Resumen: Subtotal, Descuento, Total y "Continuar al pedido" (a la derecha en escritorio, fijo abajo en móvil). **Nuevo:** botón para quitar el código.
- ✅ Test · Estado vacío (ahora con "Ver catálogo").

## Checkout
- ✅ Test · Formulario con nombre obligatorio y forma de pago; ahora muestra también el resumen del pedido.
- 🔶 Manual · Transacción: verifica que cada producto exista y tenga stock, descuenta el stock y suma 1 al uso del código. **Cambio:** ahora hace todas las lecturas antes que las escrituras, como exige Firestore (la versión anterior intercalaba lecturas y escrituras y podía fallar con 2 o más productos distintos), y vuelve a validar el código dentro de la transacción.
- 🔶 Manual · Mensaje de WhatsApp y apertura de `wa.me/595991345198` (sin cambios).
- ✅ Código · Vaciar el carrito y volver; mostrar errores; bloquear "atrás" mientras procesa.
- **Nuevo:** registra la venta en `ventas`. Si falla, el pedido sigue igual.

## FAQ
- ✅ Test · 5 preguntas estándar más las de la colección `faq` (sin duplicados).
- ✅ Test · Banner y tarjetas expandibles.
- ✅ Test · Botón "Contactar por WhatsApp".

## Acceso empleado
- 🔶 Manual · Login con email y contraseña; validación de rol `employee`/`admin`; si no corresponde, cierra la sesión y muestra "Acceso denegado"; mensajes de error. **El código de validación no cambió.**
- **Cambio:** al ingresar, la sección Empleados muestra el panel sola, sin reemplazar la pantalla. Además, la barra lateral muestra "Empleados" si hay una sesión de empleado activa.

## Panel de empleado
- ✅ Código · Mantenimiento y Cerrar sesión (ahora en el encabezado del panel). Al cerrar sesión vuelve al Inicio.
- ✅ Código · FAB "Nueva Funda" (en Servicios y Productos).
- ✅ Código · **Cambio:** las secciones son pestañas (Ventas, Servicios, Productos y Códigos promocionales). "Atrás" vuelve de Productos a Servicios y de ahí a Ventas.
- ✅ Código · Servicios: 4 tarjetas con contador y 8 accesos rápidos (las mismas acciones, con el estilo nuevo).
- 🔶 Manual · Productos: buscador, chips, tarjetas editables (guardado al salir del campo, con Enter o con ✓), diálogo de foto, stock, descuento y estado vacío. La lógica no cambió; solo los colores, para que se adapten al tema.
- 🔶 Manual · Nueva funda (bottom sheet con validaciones) → `productos.add`. La lógica no cambió.
- 🔶 Manual · Mantenimiento → "Limpiar duplicados".
- ✅ Código · Al cambiar de sección se quita el foco (dispara el guardado).
- **Nuevo:** pestaña **Ventas** (dashboard, ✅ Test con datos de ejemplo) y pestaña **Códigos promocionales** (✅ Test de la lista y del formulario; 🔶 Manual las escrituras en Firestore).

## Pruebas manuales pendientes (Firebase real)
1. Ingresar con una cuenta de empleado y con una sin rol (debe denegar el acceso).
2. Editar nombre, código, foto, stock y descuento de una funda, y crear una funda nueva.
3. Crear, editar, pausar, activar y eliminar un código promocional. **Requiere publicar `firestore.rules.propuesta`**, o al menos que las reglas actuales lo permitan. Hoy las reglas permiten todo esto a los empleados.
4. Aplicar un código en el carrito (válido, vencido, pausado, agotado, con mínimo y por categoría).
5. Confirmar un pedido con 2 o más productos y un código: el stock baja, el uso del código sube y se abre WhatsApp.
6. Ver la venta en la pestaña Ventas. **Requiere publicar reglas que incluyan `ventas`**: con las reglas actuales, la venta no se guarda (el pedido sí funciona) y el panel muestra "Sin permiso para leer las ventas".
