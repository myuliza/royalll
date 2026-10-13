/**
 * ROYAL IPHONE CASES — APLICACIÓN WEB
 * Integración directa con Firebase Firestore en tiempo real (Firebase JS SDK v10 Modular)
 * Versión Auditada y Optimizada PC-First (16:9)
 */

import { initializeApp } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js";
import { 
  getFirestore, 
  collection, 
  onSnapshot, 
  doc, 
  updateDoc 
} from "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js";

/* ==========================================================================
   1. CONFIGURACIÓN DE FIREBASE
   ========================================================================== */
const firebaseConfig = {
  apiKey: "AIzaSyBf2aDGyqNQYbygayCFnp8k3Q7lvPzdddc",
  authDomain: "royal-3ceec.firebaseapp.com",
  projectId: "royal-3ceec",
  storageBucket: "royal-3ceec.firebasestorage.app",
  messagingSenderId: "381998098827",
  appId: "1:381998098827:web:8b27d66dd428249630278e"
};

// Inicialización de servicios
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const PRODUCTOS_COLLECTION = "productos";

/* ==========================================================================
   2. ESTADO GLOBAL DE LA APLICACIÓN
   ========================================================================== */
let productosState = [];               // Lista sincronizada desde Firestore
let modoActual = "usuario";             // 'usuario' | 'empleado'
let busquedaFiltro = "";                // Filtro de texto
let modeloFiltro = "todos";             // Filtro de modelo
let coloresFiltro = new Set();          // Conjunto de claves de colores seleccionados (minúsculas)
let coloresDisponibles = [];            // Extraídos dinámicamente de Firebase

// Placeholder SVG elegante en caso de imagen vacía o error 404
const PLACEHOLDER_SVG = "data:image/svg+xml;charset=UTF-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22200%22%20height%3D%22200%22%20viewBox%3D%220%200%2024%2024%22%20fill%3D%22none%22%20stroke%3D%22%239CA3AF%22%20stroke-width%3D%221.5%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%3E%3Crect%20x%3D%225%22%20y%3D%222%22%20width%3D%2214%22%20height%3D%2220%22%20rx%3D%223%22%2F%3E%3Cpath%20d%3D%22M12%2018h.01%22%2F%3E%3Cpath%20d%3D%22M9%205h6%22%2F%3E%3C%2Fsvg%3E";

/* ==========================================================================
   3. REFERENCIAS DEL DOM
   ========================================================================== */
const grillaProductos = document.getElementById("grillaProductos");
const estadoCarga = document.getElementById("estadoCarga");
const estadoVacio = document.getElementById("estadoVacio");
const catalogoConteo = document.getElementById("catalogoConteo");
const coloresCheckboxContainer = document.getElementById("coloresCheckboxContainer");
const inputBusqueda = document.getElementById("inputBusqueda");
const selectModelo = document.getElementById("selectModelo");
const btnLimpiarFiltros = document.getElementById("btnLimpiarFiltros");
const btnModoUsuario = document.getElementById("btnModoUsuario");
const btnModoEmpleado = document.getElementById("btnModoEmpleado");
const bannerEmpleado = document.getElementById("bannerEmpleado");

// Modal
const modalDetalle = document.getElementById("modalDetalle");
const btnCerrarModal = document.getElementById("btnCerrarModal");
const modalImagen = document.getElementById("modalImagen");
const modalNombre = document.getElementById("modalNombre");
const modalCategoria = document.getElementById("modalCategoria");
const modalPrecio = document.getElementById("modalPrecio");
const modalPrecioOriginal = document.getElementById("modalPrecioOriginal");
const modalBadgeDescuento = document.getElementById("modalBadgeDescuento");
const modalColorDot = document.getElementById("modalColorDot");
const modalColorNombre = document.getElementById("modalColorNombre");
const modalModelosList = document.getElementById("modalModelosList");
const modalStock = document.getElementById("modalStock");
const btnPedirWhatsapp = document.getElementById("btnPedirWhatsapp");

/* ==========================================================================
   4. UTILIDADES DE SEGURIDAD Y PARSEO
   ========================================================================== */
/**
 * Sanitiza texto para evitar ataques XSS al inyectar cadenas dinámicas en HTML.
 */
function escapeHtml(str) {
  if (typeof str !== "string") return "";
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

/**
 * Limpia y parsea de forma segura valores numéricos de precio.
 * Tolera cadenas como "85.000 Gs", "120.000", números o undefined.
 */
function parsearNumeroSeguro(val, fallback = 0) {
  if (typeof val === "number" && !isNaN(val)) return val;
  if (typeof val === "string") {
    const cleaned = val.replace(/[^\d]/g, "");
    const parsed = parseInt(cleaned, 10);
    return isNaN(parsed) ? fallback : parsed;
  }
  return fallback;
}

/**
 * Resuelve la URL válida de imagen para un producto soportando:
 * 1. Propiedad directa `imagenUrl`
 * 2. Arreglo `fotosUrls` (primer elemento)
 * 3. Normalización automática de .png a .jpg si es un asset local
 * 4. Fallback a SVG en caso de estar vacío o inválido.
 */
function resolverUrlImagen(producto) {
  let url = "";
  if (producto && producto.imagenUrl && typeof producto.imagenUrl === "string" && producto.imagenUrl.trim() !== "") {
    url = producto.imagenUrl.trim();
  } else if (producto && Array.isArray(producto.fotosUrls) && producto.fotosUrls.length > 0 && typeof producto.fotosUrls[0] === "string" && producto.fotosUrls[0].trim() !== "") {
    url = producto.fotosUrls[0].trim();
  }

  if (!url) return PLACEHOLDER_SVG;

  // Si apunta a assets y tiene extensión .png, normalizar a .jpg que es el archivo real
  if (url.startsWith("assets/") && url.toLowerCase().endsWith(".png")) {
    url = url.replace(/\.png$/i, ".jpg");
  }

  return url;
}

/**
 * Mapeo canónico de nombres comunes y códigos hexadecimales.
 */
const PALETA_COLORES_CANONICA = {
  negro: { nombre: "Negro", hex: "#000000" },
  blanco: { nombre: "Blanco", hex: "#FFFFFF" },
  "azul midnight": { nombre: "Azul Midnight", hex: "#0B2545" },
  azul: { nombre: "Azul", hex: "#13315C" },
  cyan: { nombre: "Cyan / Royale", hex: "#00B4D8" },
  royale: { nombre: "Royale Cell", hex: "#00B4D8" },
  cyber: { nombre: "Azul Cyber", hex: "#0284C7" },
  neon: { nombre: "Neón Naranja", hex: "#FF5722" },
  "neón": { nombre: "Neón Naranja", hex: "#FF5722" },
  botanical: { nombre: "Dark Botanical", hex: "#334155" },
  antioch: { nombre: "Dark / Antioch", hex: "#334155" },
  nightfall: { nombre: "Nightfall", hex: "#0B2545" },
  dorado: { nombre: "Dorado", hex: "#C9A227" },
  oro: { nombre: "Dorado", hex: "#C9A227" },
  transparente: { nombre: "Transparente", hex: "#E5E7EB" },
  rosa: { nombre: "Rosa", hex: "#F472B6" },
  "rosa pastel": { nombre: "Rosa", hex: "#F472B6" },
  marrón: { nombre: "Marrón", hex: "#78350F" },
  marron: { nombre: "Marrón", hex: "#78350F" },
  rojo: { nombre: "Rojo", hex: "#DC2626" },
  verde: { nombre: "Verde", hex: "#16A34A" },
  morado: { nombre: "Morado / Lila", hex: "#7E22CE" },
  lila: { nombre: "Lila", hex: "#7E22CE" },
  lavanda: { nombre: "Lavanda", hex: "#7C3AED" },
  "purple fog": { nombre: "Purple Fog", hex: "#7E22CE" },
  plata: { nombre: "Plata", hex: "#E2E8F0" },
  titanio: { nombre: "Titanio", hex: "#64748B" },
  gris: { nombre: "Gris / Titanio", hex: "#64748B" },
  amarillo: { nombre: "Amarillo", hex: "#FBBF24" },
};

const HEX_A_NOMBRE = {
  "#000000": "Negro",
  "#FFFFFF": "Blanco",
  "#0B2545": "Azul",
  "#00B4D8": "Cyan / Royale",
  "#0284C7": "Azul Cyber",
  "#13315C": "Azul Marino",
  "#C9A227": "Dorado",
  "#FF5722": "Neón Naranja",
  "#334155": "Dark / Antioch",
  "#E5E7EB": "Transparente",
  "#F472B6": "Rosa",
  "#78350F": "Marrón",
  "#DC2626": "Rojo",
  "#16A34A": "Verde",
  "#7E22CE": "Morado / Lila",
  "#7C3AED": "Lavanda",
  "#E2E8F0": "Plata",
  "#64748B": "Gris / Titanio",
  "#94A3B8": "Titanio",
  "#FBBF24": "Amarillo",
};

/**
 * Devuelve la clave normalizada canónica (en minúsculas y sin espacios redundantes).
 */
function normalizarColorKey(producto) {
  if (!producto) return "estandar";
  if (typeof producto.color === "string" && producto.color.trim() !== "") {
    return producto.color.trim().toLowerCase();
  }
  if (typeof producto.colorHex === "string" && producto.colorHex.trim() !== "") {
    const hex = producto.colorHex.toUpperCase().trim();
    if (HEX_A_NOMBRE[hex]) {
      return HEX_A_NOMBRE[hex].toLowerCase();
    }
    return hex.toLowerCase();
  }
  return "estandar";
}

/**
 * Normaliza y formatea el nombre legible del color.
 */
function normalizarColor(producto) {
  if (!producto) return "Estándar";
  if (typeof producto.color === "string" && producto.color.trim() !== "") {
    const raw = producto.color.trim();
    const key = raw.toLowerCase();
    if (PALETA_COLORES_CANONICA[key]) {
      return PALETA_COLORES_CANONICA[key].nombre;
    }
    return raw.charAt(0).toUpperCase() + raw.slice(1);
  }
  if (typeof producto.colorHex === "string" && producto.colorHex.trim() !== "") {
    const hex = producto.colorHex.toUpperCase().trim();
    if (HEX_A_NOMBRE[hex]) {
      return HEX_A_NOMBRE[hex];
    }
    return hex;
  }
  return "Estándar";
}

/**
 * Resuelve el color hexadecimal asegurando compatibilidad visual directa.
 */
function resolverColorHex(producto) {
  if (!producto) return "#C9A227";
  if (typeof producto.colorHex === "string" && producto.colorHex.startsWith("#") && producto.colorHex.length >= 4) {
    return producto.colorHex.trim();
  }
  const key = normalizarColorKey(producto);
  if (PALETA_COLORES_CANONICA[key]) {
    return PALETA_COLORES_CANONICA[key].hex;
  }
  return "#C9A227"; // Dorado Royal por defecto
}

/**
 * Formatea valores en Guaraníes (Gs.) con separador de miles.
 */
function formatearGs(monto) {
  const num = parsearNumeroSeguro(monto, 0);
  return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".") + " Gs";
}

/* ==========================================================================
   5. SINCRONIZACIÓN EN TIEMPO REAL CON FIREBASE FIRESTORE
   ========================================================================== */
function iniciarSincronizacionFirebase() {
  const productosRef = collection(db, PRODUCTOS_COLLECTION);

  // Escucha reactiva en tiempo real (onSnapshot)
  onSnapshot(productosRef, (snapshot) => {
    estadoCarga.classList.add("hidden");

    if (snapshot.empty) {
      productosState = [];
      actualizarListaColoresDinamicos();
      renderizarCatalogo();
      return;
    }

    productosState = snapshot.docs.map(docSnap => {
      const data = docSnap.data() || {};
      const safeColor = data.color || normalizarColor(data);
      const safeHex = data.colorHex || resolverColorHex(data);

      return {
        id: docSnap.id,
        nombre: data.nombre ? String(data.nombre).trim() : "Funda iPhone",
        categoria: data.categoria ? String(data.categoria).trim() : "solido",
        modelosCompatibles: Array.isArray(data.modelosCompatibles) && data.modelosCompatibles.length > 0
          ? data.modelosCompatibles.map(m => String(m).trim())
          : ["iPhone 15"],
        precio: parsearNumeroSeguro(data.precio, 85000),
        colorHex: safeHex,
        color: safeColor,
        stock: parsearNumeroSeguro(data.stock, 0),
        enDescuento: Boolean(data.enDescuento),
        porcentajeDescuento: parsearNumeroSeguro(data.porcentajeDescuento, 0),
        imagenUrl: resolverUrlImagen(data),
        fotosUrls: Array.isArray(data.fotosUrls) ? data.fotosUrls : []
      };
    });

    // Actualizar colores dinámicamente y renderizar catálogo
    actualizarListaColoresDinamicos();
    renderizarCatalogo();
  }, (error) => {
    console.error("Error al sincronizar con Firebase:", error);
    estadoCarga.innerHTML = `<p style="color:#DC2626; font-weight:600;">Error de conexión: ${escapeHtml(error.message)}</p>`;
  });
}

/* ==========================================================================
   6. FILTRADO MULTICOLOR DINÁMICO (SOLUCIÓN PASO 4)
   ========================================================================== */
function actualizarListaColoresDinamicos() {
  const mapaColores = new Map();

  productosState.forEach(p => {
    const key = normalizarColorKey(p);
    const nombreLegible = normalizarColor(p);
    const hex = resolverColorHex(p);

    if (!mapaColores.has(key)) {
      mapaColores.set(key, { key, nombre: nombreLegible, hex, count: 1 });
    } else {
      mapaColores.get(key).count++;
    }
  });

  coloresDisponibles = Array.from(mapaColores.values()).sort((a, b) => b.count - a.count);
  renderizarColoresDinamicos();
}

function alternarFiltroColor(colorKey) {
  if (coloresFiltro.has(colorKey)) {
    coloresFiltro.delete(colorKey);
  } else {
    coloresFiltro.add(colorKey);
  }
  actualizarEstilosVisualesColores();
  renderizarCatalogo();
}

function actualizarEstilosVisualesColores() {
  const items = coloresCheckboxContainer.querySelectorAll(".color-checkbox-item");
  items.forEach(item => {
    const key = item.getAttribute("data-color-key");
    const isSelected = coloresFiltro.has(key);
    item.classList.toggle("selected", isSelected);
    item.setAttribute("aria-checked", isSelected ? "true" : "false");
    const checkbox = item.querySelector('input[type="checkbox"]');
    if (checkbox) checkbox.checked = isSelected;
  });
}

function renderizarColoresDinamicos() {
  if (coloresDisponibles.length === 0) {
    coloresCheckboxContainer.innerHTML = '<div class="loading-colors">No hay colores registrados</div>';
    return;
  }

  // Se renderizan elementos estructurados con data-color-key para prevenir fallos de eventos
  coloresCheckboxContainer.innerHTML = coloresDisponibles.map(c => {
    const isSelected = coloresFiltro.has(c.key);
    return `
      <div 
        class="color-checkbox-item ${isSelected ? "selected" : ""}" 
        data-color-key="${escapeHtml(c.key)}"
        role="checkbox"
        aria-checked="${isSelected ? "true" : "false"}"
        tabindex="0"
      >
        <div class="color-checkbox-left">
          <input 
            type="checkbox" 
            tabindex="-1"
            aria-hidden="true"
            ${isSelected ? "checked" : ""}
          >
          <span class="color-swatch-circle" style="background-color: ${escapeHtml(c.hex)}"></span>
          <span class="color-name-text">${escapeHtml(c.nombre)}</span>
        </div>
        <span class="color-count-badge">${c.count}</span>
      </div>
    `;
  }).join("");

  // Controladores robustos: Click y Teclado (Accesibilidad WCAG)
  coloresCheckboxContainer.querySelectorAll(".color-checkbox-item").forEach(item => {
    const key = item.getAttribute("data-color-key");

    item.addEventListener("click", (e) => {
      e.preventDefault(); // Evita doble disparo nativo del checkbox
      alternarFiltroColor(key);
    });

    item.addEventListener("keydown", (e) => {
      if (e.key === " " || e.key === "Enter") {
        e.preventDefault();
        alternarFiltroColor(key);
      }
    });
  });
}

/* ==========================================================================
   7. RENDERIZADO DEL CATÁLOGO
   ========================================================================== */
function filtrarProductos() {
  return productosState.filter(p => {
    // 1. Filtro por texto de búsqueda
    if (busquedaFiltro.trim() !== "") {
      const q = busquedaFiltro.toLowerCase().trim();
      const coincideNombre = p.nombre.toLowerCase().includes(q);
      const coincideModelo = p.modelosCompatibles.some(m => m.toLowerCase().includes(q));
      const coincideCategoria = p.categoria.toLowerCase().includes(q);
      if (!coincideNombre && !coincideModelo && !coincideCategoria) return false;
    }

    // 2. Filtro por modelo de iPhone
    if (modeloFiltro !== "todos") {
      if (!p.modelosCompatibles.includes(modeloFiltro)) return false;
    }

    // 3. FILTRADO MULTICOLOR: Si hay colores seleccionados, el producto debe coincidir
    if (coloresFiltro.size > 0) {
      const key = normalizarColorKey(p);
      if (!coloresFiltro.has(key)) return false;
    }

    return true;
  });
}

function renderizarCatalogo() {
  const lista = filtrarProductos();

  catalogoConteo.textContent = `Mostrando ${lista.length} de ${productosState.length} fundas`;

  if (lista.length === 0) {
    grillaProductos.classList.add("hidden");
    estadoVacio.classList.remove("hidden");
    return;
  }

  estadoVacio.classList.add("hidden");
  grillaProductos.classList.remove("hidden");

  if (modoActual === "usuario") {
    renderizarModoUsuario(lista);
  } else {
    renderizarModoEmpleado(lista);
  }
}

/**
 * Renderiza la vista de Cliente / Usuario (tarjetas elegantes + clic para modal)
 */
function renderizarModoUsuario(productos) {
  grillaProductos.innerHTML = productos.map(p => {
    const tieneDesc = p.enDescuento && p.porcentajeDescuento > 0;
    const precioFinal = tieneDesc 
      ? Math.round(p.precio * (1 - p.porcentajeDescuento / 100)) 
      : p.precio;
    const colorHex = resolverColorHex(p);
    const colorNombre = normalizarColor(p);
    const imgUrl = resolverUrlImagen(p);

    return `
      <article class="product-card" data-id="${escapeHtml(p.id)}">
        <div class="card-img-box" data-action="open-modal" data-id="${escapeHtml(p.id)}">
          ${tieneDesc ? `<span class="badge-discount">-${p.porcentajeDescuento}% OFF</span>` : ""}
          <img 
            src="${escapeHtml(imgUrl)}" 
            alt="${escapeHtml(p.nombre)}" 
            class="card-img" 
            loading="lazy" 
            onerror="this.onerror=null; this.src='${PLACEHOLDER_SVG}';"
          >
          <div class="badge-zoom-hint">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/><line x1="11" y1="8" x2="11" y2="14"/><line x1="8" y1="11" x2="14" y2="11"/></svg>
            Ver detalle
          </div>
        </div>

        <div class="card-info">
          <div class="card-meta-row">
            <span class="color-dot" style="background-color: ${escapeHtml(colorHex)}"></span>
            <span class="card-category">${escapeHtml(p.categoria)} &bull; ${escapeHtml(colorNombre)}</span>
          </div>

          <h3 class="card-title">${escapeHtml(p.nombre)}</h3>
          <p class="card-models-summary">Compatible con ${escapeHtml(p.modelosCompatibles.slice(0, 2).join(", "))}${p.modelosCompatibles.length > 2 ? '...' : ''}</p>

          <div class="card-price-row">
            <span class="card-price-final ${tieneDesc ? 'has-discount' : ''}">${formatearGs(precioFinal)}</span>
            ${tieneDesc ? `<span class="card-price-original">${formatearGs(p.precio)}</span>` : ""}
          </div>
        </div>
      </article>
    `;
  }).join("");

  // Agregar escuchador de clic en imagen para abrir modal
  grillaProductos.querySelectorAll('[data-action="open-modal"]').forEach(box => {
    box.addEventListener("click", () => {
      const id = box.getAttribute("data-id");
      abrirModal(id);
    });
  });
}

/**
 * Renderiza la vista de Empleado (Inputs de edición en vivo: nombre y URL de imagen)
 */
function renderizarModoEmpleado(productos) {
  grillaProductos.innerHTML = productos.map(p => {
    const imgUrl = resolverUrlImagen(p);
    const colorHex = resolverColorHex(p);

    return `
      <article class="employee-card" data-id="${escapeHtml(p.id)}">
        <!-- Encabezado con previsualización en tiempo real -->
        <div class="employee-header-row">
          <div class="employee-img-preview-box">
            <img 
              id="preview-img-${escapeHtml(p.id)}" 
              src="${escapeHtml(imgUrl)}" 
              alt="${escapeHtml(p.nombre)}" 
              class="employee-img-preview" 
              onerror="this.onerror=null; this.src='${PLACEHOLDER_SVG}';"
            >
          </div>
          <div class="employee-top-info">
            <span class="employee-id-tag">ID: ${escapeHtml(p.id.substring(0, 10))}...</span>
            <div style="display:flex; align-items:center; gap:6px;">
              <span class="color-dot" style="background-color: ${escapeHtml(colorHex)}"></span>
              <span style="font-size:0.75rem; font-weight:700;">${escapeHtml(normalizarColor(p))}</span>
            </div>
            <span class="employee-stock-chip">Stock: ${p.stock} un.</span>
          </div>
        </div>

        <!-- Campo 1: Nombre de la funda -->
        <div class="employee-field">
          <label class="employee-label" for="input-nombre-${escapeHtml(p.id)}">
            <span>Nombre de la funda</span>
            <span id="status-nombre-${escapeHtml(p.id)}" class="employee-save-status">Guardado &#10003;</span>
          </label>
          <input 
            type="text" 
            id="input-nombre-${escapeHtml(p.id)}" 
            class="employee-input input-nombre" 
            data-id="${escapeHtml(p.id)}" 
            value="${escapeHtml(p.nombre)}" 
            placeholder="Nombre de producto"
          >
        </div>

        <!-- Campo 2: URL de la Imagen -->
        <div class="employee-field">
          <label class="employee-label" for="input-imagen-${escapeHtml(p.id)}">
            <span>URL de imagen (Foto)</span>
            <span id="status-imagen-${escapeHtml(p.id)}" class="employee-save-status">Guardado &#10003;</span>
          </label>
          <input 
            type="url" 
            id="input-imagen-${escapeHtml(p.id)}" 
            class="employee-input input-imagen" 
            data-id="${escapeHtml(p.id)}" 
            value="${escapeHtml(p.imagenUrl === PLACEHOLDER_SVG ? '' : p.imagenUrl)}" 
            placeholder="https://ejemplo.com/foto.jpg"
          >
        </div>

        <!-- Pie con botón de guardado explícito -->
        <div class="employee-card-footer">
          <span style="font-size:0.78rem; font-weight:700; color:var(--azul);">
            ${formatearGs(p.precio)}
          </span>
          <button class="btn-guardar-card" data-id="${escapeHtml(p.id)}">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
            Guardar en Firebase
          </button>
        </div>
      </article>
    `;
  }).join("");

  configurarListenersEmpleado();
}

/* ==========================================================================
   8. EDICIÓN EN MODO EMPLEADO (ACTUALIZACIÓN DIRECTA EN FIREBASE)
   ========================================================================== */
function configurarListenersEmpleado() {
  // Listener para campo Nombre
  grillaProductos.querySelectorAll(".input-nombre").forEach(input => {
    const id = input.getAttribute("data-id");

    const guardarNombre = async () => {
      const nuevoNombre = input.value.trim();
      if (!nuevoNombre) return;
      await actualizarCampoFirebase(id, { nombre: nuevoNombre }, `status-nombre-${id}`);
    };

    input.addEventListener("blur", guardarNombre);
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        input.blur();
      }
    });
  });

  // Listener para campo URL de Imagen
  grillaProductos.querySelectorAll(".input-imagen").forEach(input => {
    const id = input.getAttribute("data-id");

    const guardarImagen = async () => {
      const nuevaUrl = input.value.trim();
      const previewImg = document.getElementById(`preview-img-${id}`);
      if (previewImg) {
        previewImg.src = nuevaUrl || PLACEHOLDER_SVG;
      }
      await actualizarCampoFirebase(id, { 
        imagenUrl: nuevaUrl, 
        fotosUrls: nuevaUrl ? [nuevaUrl] : [] 
      }, `status-imagen-${id}`);
    };

    input.addEventListener("blur", guardarImagen);
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        input.blur();
      }
    });
  });

  // Listener para botón Guardar explícito
  grillaProductos.querySelectorAll(".btn-guardar-card").forEach(btn => {
    btn.addEventListener("click", async () => {
      const id = btn.getAttribute("data-id");
      const inputNombre = document.getElementById(`input-nombre-${id}`);
      const inputImagen = document.getElementById(`input-imagen-${id}`);

      const datos = {};
      if (inputNombre) datos.nombre = inputNombre.value.trim();
      if (inputImagen) {
        const u = inputImagen.value.trim();
        datos.imagenUrl = u;
        datos.fotosUrls = u ? [u] : [];
        const previewImg = document.getElementById(`preview-img-${id}`);
        if (previewImg) previewImg.src = u || PLACEHOLDER_SVG;
      }

      const exito = await actualizarCampoFirebase(id, datos, null);
      if (exito) {
        mostrarToast("¡Funda actualizada exitosamente en Firebase!");
      }
    });
  });
}

/**
 * Ejecuta updateDoc en Firestore y muestra feedback visual de guardado.
 * Retorna true en éxito y false en error para sincronización con la UI.
 */
async function actualizarCampoFirebase(id, datosActualizados, statusElementId) {
  try {
    const docRef = doc(db, PRODUCTOS_COLLECTION, id);
    await updateDoc(docRef, datosActualizados);

    if (statusElementId) {
      const statusEl = document.getElementById(statusElementId);
      if (statusEl) {
        statusEl.classList.add("visible");
        setTimeout(() => statusEl.classList.remove("visible"), 2500);
      }
    }
    return true;
  } catch (error) {
    console.error("Error al actualizar en Firebase:", error);
    mostrarToast("Error al guardar: " + error.message);
    return false;
  }
}

/* ==========================================================================
   9. POPUP / MODAL EN MODO USUARIO
   ========================================================================== */
function abrirModal(id) {
  const p = productosState.find(item => item.id === id);
  if (!p) return;

  const tieneDesc = p.enDescuento && p.porcentajeDescuento > 0;
  const precioFinal = tieneDesc 
    ? Math.round(p.precio * (1 - p.porcentajeDescuento / 100)) 
    : p.precio;

  modalImagen.src = resolverUrlImagen(p);
  modalImagen.onerror = () => { modalImagen.src = PLACEHOLDER_SVG; };
  modalNombre.textContent = p.nombre;
  modalCategoria.textContent = p.categoria.toUpperCase();
  modalPrecio.textContent = formatearGs(precioFinal);

  if (tieneDesc) {
    modalPrecioOriginal.textContent = formatearGs(p.precio);
    modalPrecioOriginal.classList.remove("hidden");
    modalBadgeDescuento.textContent = `-${p.porcentajeDescuento}% OFF`;
    modalBadgeDescuento.classList.remove("hidden");
  } else {
    modalPrecioOriginal.classList.add("hidden");
    modalBadgeDescuento.classList.add("hidden");
  }

  // Color
  const colorHex = resolverColorHex(p);
  modalColorDot.style.backgroundColor = colorHex;
  modalColorNombre.textContent = normalizarColor(p);

  // Modelos compatibles
  modalModelosList.innerHTML = p.modelosCompatibles.map(m => 
    `<span class="modelo-chip">${escapeHtml(m)}</span>`
  ).join("");

  // Stock
  modalStock.textContent = p.stock > 0 ? `Disponible (${p.stock} un.)` : "Agotado";
  modalStock.style.color = p.stock > 0 ? "var(--verde-exito)" : "var(--rojo-descuento)";

  // Enlace WhatsApp
  btnPedirWhatsapp.onclick = () => {
    const texto = encodeURIComponent(`¡Hola Royal! Me interesa la ${p.nombre} (${normalizarColor(p)}) para iPhone por ${formatearGs(precioFinal)}.`);
    window.open(`https://wa.me/595991345198?text=${texto}`, "_blank");
  };

  modalDetalle.classList.remove("hidden");
}

function cerrarModal() {
  modalDetalle.classList.add("hidden");
}

btnCerrarModal.addEventListener("click", cerrarModal);
modalDetalle.addEventListener("click", (e) => {
  if (e.target === modalDetalle) cerrarModal();
});
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape" && !modalDetalle.classList.contains("hidden")) {
    cerrarModal();
  }
});

/* ==========================================================================
   10. CONTROLADORES DE FILTROS Y EVENTOS
   ========================================================================== */
inputBusqueda.addEventListener("input", (e) => {
  busquedaFiltro = e.target.value;
  renderizarCatalogo();
});

selectModelo.addEventListener("change", (e) => {
  modeloFiltro = e.target.value;
  renderizarCatalogo();
});

btnLimpiarFiltros.addEventListener("click", () => {
  busquedaFiltro = "";
  modeloFiltro = "todos";
  coloresFiltro.clear();
  inputBusqueda.value = "";
  selectModelo.value = "todos";
  actualizarEstilosVisualesColores();
  renderizarCatalogo();
});

// Conmutación entre Modo Usuario y Modo Empleado
btnModoUsuario.addEventListener("click", () => {
  modoActual = "usuario";
  btnModoUsuario.classList.add("active");
  btnModoEmpleado.classList.remove("active");
  bannerEmpleado.classList.add("hidden");
  renderizarCatalogo();
});

btnModoEmpleado.addEventListener("click", () => {
  modoActual = "empleado";
  btnModoEmpleado.classList.add("active");
  btnModoUsuario.classList.remove("active");
  bannerEmpleado.classList.remove("hidden");
  renderizarCatalogo();
});

/* ==========================================================================
   11. UTILIDADES Y TOAST
   ========================================================================== */
function mostrarToast(mensaje) {
  const toast = document.getElementById("toast");
  toast.textContent = mensaje;
  toast.classList.remove("hidden");
  setTimeout(() => {
    toast.classList.add("hidden");
  }, 3500);
}

// Iniciar aplicación
iniciarSincronizacionFirebase();
