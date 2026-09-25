/**
 * ROYAL IPHONE CASES — APLICACIÓN WEB
 * Integración directa con Firebase Firestore en tiempo real (Firebase JS SDK v10 Modular)
 */

import { initializeApp } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js";
import { 
  getFirestore, 
  collection, 
  onSnapshot, 
  doc, 
  updateDoc, 
  addDoc, 
  getDocs, 
  writeBatch 
} from "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js";

/* ==========================================================================
   1. CONFIGURACIÓN DE FIREBASE (Plantilla configurable)
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
let coloresFiltro = new Set();          // Conjunto de colores seleccionados (Multicolor)
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
const btnPoblarSemilla = document.getElementById("btnPoblarSemilla");
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
   4. DIAGNÓSTICO Y CORRECCIÓN DE IMÁGENES
   ========================================================================== */
/**
 * Resuelve la URL válida de imagen para un producto soportando:
 * 1. Propiedad directa `imagenUrl`
 * 2. Arreglo `fotosUrls` (primer elemento)
 * 3. Fallback a SVG en caso de estar vacío o inválido.
 */
function resolverUrlImagen(producto) {
  if (producto.imagenUrl && typeof producto.imagenUrl === "string" && producto.imagenUrl.trim() !== "") {
    return producto.imagenUrl.trim();
  }
  if (Array.isArray(producto.fotosUrls) && producto.fotosUrls.length > 0 && producto.fotosUrls[0]) {
    return producto.fotosUrls[0].trim();
  }
  return PLACEHOLDER_SVG;
}

/**
 * Normaliza y formatea el nombre legible del color.
 */
function normalizarColor(producto) {
  if (producto.color && typeof producto.color === "string" && producto.color.trim() !== "") {
    return producto.color.trim();
  }
  // Mapeo por hex si existe
  const hex = (producto.colorHex || "").toUpperCase().trim();
  const mapeoHex = {
    "#000000": "Negro",
    "#FFFFFF": "Blanco",
    "#0B2545": "Azul Midnight",
    "#13315C": "Azul",
    "#C9A227": "Dorado",
    "#E5E7EB": "Transparente",
    "#F472B6": "Rosa Pastel",
    "#78350F": "Marrón",
    "#DC2626": "Rojo"
  };
  return mapeoHex[hex] || "Estándar";
}

function resolverColorHex(producto) {
  if (producto.colorHex && producto.colorHex.startsWith("#")) {
    return producto.colorHex;
  }
  const nombre = normalizarColor(producto).toLowerCase();
  const mapa = {
    negro: "#000000",
    blanco: "#FFFFFF",
    azul: "#0B2545",
    "azul midnight": "#0B2545",
    dorado: "#C9A227",
    oro: "#C9A227",
    transparente: "#E5E7EB",
    rosa: "#F472B6",
    marrón: "#78350F",
    rojo: "#DC2626"
  };
  return mapa[nombre] || "#C9A227";
}

function formatearGs(monto) {
  return (monto || 0).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".") + " Gs";
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
      renderizarColoresDinamicos();
      renderizarCatalogo();
      mostrarToast("La base de datos está vacía. Puedes presionar 'Poblar datos semilla'.");
      return;
    }

    productosState = snapshot.docs.map(docSnap => {
      const data = docSnap.data();
      return {
        id: docSnap.id,
        nombre: data.nombre || "Funda iPhone",
        categoria: data.categoria || "solido",
        modelosCompatibles: Array.isArray(data.modelosCompatibles) ? data.modelosCompatibles : ["iPhone 15"],
        precio: typeof data.precio === "number" ? data.precio : parseInt(data.precio) || 85000,
        colorHex: data.colorHex || "#000000",
        color: data.color || normalizarColor(data),
        stock: typeof data.stock === "number" ? data.stock : 10,
        enDescuento: !!data.enDescuento,
        porcentajeDescuento: data.porcentajeDescuento || 0,
        imagenUrl: resolverUrlImagen(data),
        fotosUrls: Array.isArray(data.fotosUrls) ? data.fotosUrls : []
      };
    });

    // Actualizar colores dinámicamente según lo que vino de Firebase
    actualizarListaColoresDinamicos();
    renderizarCatalogo();
  }, (error) => {
    console.error("Error al sincronizar con Firebase:", error);
    estadoCarga.innerHTML = `<p style="color:red">Error de conexión: ${error.message}</p>`;
  });
}

/* ==========================================================================
   6. FILTRADO MULTICOLOR DINÁMICO
   ========================================================================== */
function actualizarListaColoresDinamicos() {
  const mapaColores = new Map();

  productosState.forEach(p => {
    const nombreColor = normalizarColor(p);
    const hex = resolverColorHex(p);
    if (!mapaColores.has(nombreColor)) {
      mapaColores.set(nombreColor, { nombre: nombreColor, hex: hex, count: 1 });
    } else {
      mapaColores.get(nombreColor).count++;
    }
  });

  coloresDisponibles = Array.from(mapaColores.values());
  renderizarColoresDinamicos();
}

function renderizarColoresDinamicos() {
  if (coloresDisponibles.length === 0) {
    coloresCheckboxContainer.innerHTML = '<div class="loading-colors">No hay colores disponibles</div>';
    return;
  }

  coloresCheckboxContainer.innerHTML = coloresDisponibles.map(c => {
    const isChecked = coloresFiltro.has(c.nombre);
    return `
      <label class="color-checkbox-item">
        <div class="color-checkbox-left">
          <input type="checkbox" value="${c.nombre}" ${isChecked ? "checked" : ""}>
          <span class="color-swatch-circle" style="background-color: ${c.hex}"></span>
          <span class="color-name-text">${c.nombre}</span>
        </div>
        <span class="color-count-badge">${c.count}</span>
      </label>
    `;
  }).join("");

  // Event listener para selección múltiple
  coloresCheckboxContainer.querySelectorAll('input[type="checkbox"]').forEach(chk => {
    chk.addEventListener("change", (e) => {
      const colorVal = e.target.value;
      if (e.target.checked) {
        coloresFiltro.add(colorVal);
      } else {
        coloresFiltro.delete(colorVal);
      }
      renderizarCatalogo();
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
      const q = busquedaFiltro.toLowerCase();
      const coincideNombre = p.nombre.toLowerCase().includes(q);
      const coincideModelo = p.modelosCompatibles.some(m => m.toLowerCase().includes(q));
      if (!coincideNombre && !coincideModelo) return false;
    }

    // 2. Filtro por modelo de iPhone
    if (modeloFiltro !== "todos") {
      if (!p.modelosCompatibles.includes(modeloFiltro)) return false;
    }

    // 3. FILTRADO MULTICOLOR: Si hay colores seleccionados, el producto debe coincidir con alguno
    if (coloresFiltro.size > 0) {
      const colorProducto = normalizarColor(p);
      if (!coloresFiltro.has(colorProducto)) return false;
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
      <article class="product-card" data-id="${p.id}">
        <div class="card-img-box" data-action="open-modal" data-id="${p.id}">
          ${tieneDesc ? `<span class="badge-discount">-${p.porcentajeDescuento}% OFF</span>` : ""}
          <img 
            src="${imgUrl}" 
            alt="${p.nombre}" 
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
            <span class="color-dot" style="background-color: ${colorHex}"></span>
            <span class="card-category">${p.categoria} &bull; ${colorNombre}</span>
          </div>

          <h3 class="card-title">${p.nombre}</h3>
          <p class="card-models-summary">Compatible con ${p.modelosCompatibles.slice(0, 2).join(", ")}${p.modelosCompatibles.length > 2 ? '...' : ''}</p>

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
      <article class="employee-card" data-id="${p.id}">
        <!-- Encabezado con previsualización en tiempo real -->
        <div class="employee-header-row">
          <div class="employee-img-preview-box">
            <img 
              id="preview-img-${p.id}" 
              src="${imgUrl}" 
              alt="${p.nombre}" 
              class="employee-img-preview" 
              onerror="this.onerror=null; this.src='${PLACEHOLDER_SVG}';"
            >
          </div>
          <div class="employee-top-info">
            <span class="employee-id-tag">ID: ${p.id.substring(0, 10)}...</span>
            <div style="display:flex; align-items:center; gap:6px;">
              <span class="color-dot" style="background-color: ${colorHex}"></span>
              <span style="font-size:0.75rem; font-weight:700;">${normalizarColor(p)}</span>
            </div>
            <span class="employee-stock-chip">Stock: ${p.stock} un.</span>
          </div>
        </div>

        <!-- Campo 1: Nombre de la funda -->
        <div class="employee-field">
          <label class="employee-label" for="input-nombre-${p.id}">
            <span>Nombre de la funda</span>
            <span id="status-nombre-${p.id}" class="employee-save-status">Guardado &#10003;</span>
          </label>
          <input 
            type="text" 
            id="input-nombre-${p.id}" 
            class="employee-input input-nombre" 
            data-id="${p.id}" 
            value="${p.nombre}" 
            placeholder="Nombre de producto"
          >
        </div>

        <!-- Campo 2: URL de la Imagen -->
        <div class="employee-field">
          <label class="employee-label" for="input-imagen-${p.id}">
            <span>URL de imagen (Foto)</span>
            <span id="status-imagen-${p.id}" class="employee-save-status">Guardado &#10003;</span>
          </label>
          <input 
            type="url" 
            id="input-imagen-${p.id}" 
            class="employee-input input-imagen" 
            data-id="${p.id}" 
            value="${p.imagenUrl === PLACEHOLDER_SVG ? '' : p.imagenUrl}" 
            placeholder="https://ejemplo.com/foto.jpg"
          >
        </div>

        <!-- Pie con botón de guardado explícito -->
        <div class="employee-card-footer">
          <span style="font-size:0.78rem; font-weight:700; color:var(--azul);">
            ${formatearGs(p.precio)}
          </span>
          <button class="btn-guardar-card" data-id="${p.id}">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
            Guardar en Firebase
          </button>
        </div>
      </article>
    `;
  }).join("");

  // Configurar listeners de edición (blur, Enter y clic en botón)
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
      // Actualizar previsualización inmediatamente en el DOM local
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

      await actualizarCampoFirebase(id, datos, null);
      mostrarToast("¡Funda actualizada exitosamente en Firebase!");
    });
  });
}

/**
 * Ejecuta updateDoc en Firestore y muestra feedback visual de guardado.
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
  } catch (error) {
    console.error("Error al actualizar en Firebase:", error);
    mostrarToast("Error al guardar: " + error.message);
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
    `<span class="modelo-chip">${m}</span>`
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
   10. POBLADO INICIAL (DATOS SEMILLA EN FIREBASE)
   ========================================================================== */
const DATOS_SEMILLA = [
  {
    nombre: "Funda Royal Titanium MagSafe",
    categoria: "solido",
    color: "Dorado",
    colorHex: "#C9A227",
    modelosCompatibles: ["iPhone 16 Pro Max", "iPhone 16 Pro"],
    precio: 120000,
    enDescuento: true,
    porcentajeDescuento: 15,
    stock: 20,
    imagenUrl: "https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?w=600&auto=format&fit=crop&q=80",
    fotosUrls: ["https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?w=600&auto=format&fit=crop&q=80"]
  },
  {
    nombre: "Funda Royal Armor Negro Mate",
    categoria: "solido",
    color: "Negro",
    colorHex: "#000000",
    modelosCompatibles: ["iPhone 16 Pro Max", "iPhone 16 Pro", "iPhone 16"],
    precio: 95000,
    enDescuento: false,
    porcentajeDescuento: 0,
    stock: 15,
    imagenUrl: "https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=600&auto=format&fit=crop&q=80",
    fotosUrls: ["https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=600&auto=format&fit=crop&q=80"]
  },
  {
    nombre: "Funda Royal Silicone Azul Midnight",
    categoria: "solido",
    color: "Azul",
    colorHex: "#0B2545",
    modelosCompatibles: ["iPhone 16", "iPhone 15 Pro Max", "iPhone 15 Pro"],
    precio: 85000,
    enDescuento: true,
    porcentajeDescuento: 20,
    stock: 18,
    imagenUrl: "https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=600&auto=format&fit=crop&q=80",
    fotosUrls: ["https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=600&auto=format&fit=crop&q=80"]
  },
  {
    nombre: "Funda Clear Hybrid Antiamarilleo",
    categoria: "transparente",
    color: "Transparente",
    colorHex: "#E5E7EB",
    modelosCompatibles: ["iPhone 16", "iPhone 15", "iPhone 14", "iPhone 13"],
    precio: 80000,
    enDescuento: false,
    porcentajeDescuento: 0,
    stock: 30,
    imagenUrl: "https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=600&auto=format&fit=crop&q=80",
    fotosUrls: ["https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=600&auto=format&fit=crop&q=80"]
  },
  {
    nombre: "Funda Royal Frosted White Silk",
    categoria: "solido",
    color: "Blanco",
    colorHex: "#FFFFFF",
    modelosCompatibles: ["iPhone 15 Pro Max", "iPhone 15 Pro", "iPhone 15"],
    precio: 90000,
    enDescuento: false,
    porcentajeDescuento: 0,
    stock: 12,
    imagenUrl: "https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=600&auto=format&fit=crop&q=80",
    fotosUrls: ["https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=600&auto=format&fit=crop&q=80"]
  },
  {
    nombre: "Funda Liquid Silicone Rosa Pastel",
    categoria: "solido",
    color: "Rosa",
    colorHex: "#F472B6",
    modelosCompatibles: ["iPhone 15", "iPhone 14", "iPhone 13"],
    precio: 85000,
    enDescuento: true,
    porcentajeDescuento: 10,
    stock: 14,
    imagenUrl: "https://images.unsplash.com/photo-1580910051074-3eb694886505?w=600&auto=format&fit=crop&q=80",
    fotosUrls: ["https://images.unsplash.com/photo-1580910051074-3eb694886505?w=600&auto=format&fit=crop&q=80"]
  },
  {
    nombre: "Funda Royal Leather Vintage",
    categoria: "solido",
    color: "Marrón",
    colorHex: "#78350F",
    modelosCompatibles: ["iPhone 14 Pro Max", "iPhone 14 Pro"],
    precio: 130000,
    enDescuento: false,
    porcentajeDescuento: 0,
    stock: 8,
    imagenUrl: "https://images.unsplash.com/photo-1544816155-12df9643f363?w=600&auto=format&fit=crop&q=80",
    fotosUrls: ["https://images.unsplash.com/photo-1544816155-12df9643f363?w=600&auto=format&fit=crop&q=80"]
  },
  {
    nombre: "Funda Royal MagSafe Clear Glow",
    categoria: "transparente",
    color: "Transparente",
    colorHex: "#E5E7EB",
    modelosCompatibles: ["iPhone 14 Pro Max", "iPhone 14 Pro", "iPhone 14"],
    precio: 95000,
    enDescuento: true,
    porcentajeDescuento: 15,
    stock: 22,
    imagenUrl: "https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb?w=600&auto=format&fit=crop&q=80",
    fotosUrls: ["https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb?w=600&auto=format&fit=crop&q=80"]
  },
  {
    nombre: "Funda Carbon Fiber Ultra Slim",
    categoria: "solido",
    color: "Negro",
    colorHex: "#000000",
    modelosCompatibles: ["iPhone 13 Pro Max", "iPhone 13 Pro", "iPhone 13"],
    precio: 100000,
    enDescuento: false,
    porcentajeDescuento: 0,
    stock: 16,
    imagenUrl: "https://images.unsplash.com/photo-1565849904461-04a58ad377e0?w=600&auto=format&fit=crop&q=80",
    fotosUrls: ["https://images.unsplash.com/photo-1565849904461-04a58ad377e0?w=600&auto=format&fit=crop&q=80"]
  },
  {
    nombre: "Funda Heavy Duty Shield Red",
    categoria: "solido",
    color: "Rojo",
    colorHex: "#DC2626",
    modelosCompatibles: ["iPhone 13 Pro Max", "iPhone 13"],
    precio: 90000,
    enDescuento: true,
    porcentajeDescuento: 25,
    stock: 10,
    imagenUrl: "https://images.unsplash.com/photo-1584438784894-089d6a62b8fa?w=600&auto=format&fit=crop&q=80",
    fotosUrls: ["https://images.unsplash.com/photo-1584438784894-089d6a62b8fa?w=600&auto=format&fit=crop&q=80"]
  }
];

async function poblarDatosSemillaEnFirebase() {
  try {
    mostrarToast("Iniciando carga de 10 fundas en Firebase...");
    const batch = writeBatch(db);
    const colRef = collection(db, PRODUCTOS_COLLECTION);

    for (const item of DATOS_SEMILLA) {
      const nuevoDocRef = doc(colRef);
      batch.set(nuevoDocRef, item);
    }

    await batch.commit();
    mostrarToast("¡Catálogo semilla subido a Firebase con éxito!");
  } catch (error) {
    console.error("Error al poblar datos semilla:", error);
    mostrarToast("Error al poblar: " + error.message);
  }
}

btnPoblarSemilla.addEventListener("click", () => {
  if (confirm("¿Deseas subir el catálogo semilla inicial (10 fundas) a Firebase?")) {
    poblarDatosSemillaEnFirebase();
  }
});

/* ==========================================================================
   11. CONTROLADORES DE FILTROS Y EVENTOS
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
  renderizarColoresDinamicos();
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
   12. UTILIDADES Y TOAST
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
