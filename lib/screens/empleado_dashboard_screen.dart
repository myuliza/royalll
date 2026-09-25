import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';
import '../utils/catalogo_seeder.dart';
import '../widgets/app_product_image.dart';

class EmpleadoDashboardScreen extends StatefulWidget {
  const EmpleadoDashboardScreen({super.key});

  @override
  State<EmpleadoDashboardScreen> createState() => _EmpleadoDashboardScreenState();
}

class _EmpleadoDashboardScreenState extends State<EmpleadoDashboardScreen> {
  String _categoriaFiltro = 'todas';
  String _busqueda = '';
  final _searchController = TextEditingController();

  final List<String> _categorias = [
    'todas',
    'solido',
    'transparente',
    'personalizada',
  ];

  // Paleta estandarizada de colores para crear/editar productos
  static const List<Map<String, String>> _paletaColores = [
    {'nombre': 'Negro', 'hex': '#000000', 'fotoDefecto': 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=800&auto=format&fit=crop&q=80'},
    {'nombre': 'Blanco', 'hex': '#FFFFFF', 'fotoDefecto': 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=800&auto=format&fit=crop&q=80'},
    {'nombre': 'Transparente', 'hex': '#E5E7EB', 'fotoDefecto': 'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=800&auto=format&fit=crop&q=80'},
    {'nombre': 'Azul', 'hex': '#0B2545', 'fotoDefecto': 'https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=800&auto=format&fit=crop&q=80'},
    {'nombre': 'Rojo', 'hex': '#DC2626', 'fotoDefecto': 'https://images.unsplash.com/photo-1584438784894-089d6a62b8fa?w=800&auto=format&fit=crop&q=80'},
    {'nombre': 'Verde', 'hex': '#16A34A', 'fotoDefecto': 'https://images.unsplash.com/photo-1574944985070-8f3ebc6b79d2?w=800&auto=format&fit=crop&q=80'},
    {'nombre': 'Rosa', 'hex': '#F472B6', 'fotoDefecto': 'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=800&auto=format&fit=crop&q=80'},
    {'nombre': 'Morado', 'hex': '#7E22CE', 'fotoDefecto': 'https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb?w=800&auto=format&fit=crop&q=80'},
    {'nombre': 'Dorado/Beige', 'hex': '#C9A227', 'fotoDefecto': 'https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?w=800&auto=format&fit=crop&q=80'},
    {'nombre': 'Gris/Titanio', 'hex': '#64748B', 'fotoDefecto': 'https://images.unsplash.com/photo-1565849904461-04a58ad377e0?w=800&auto=format&fit=crop&q=80'},
  ];

  static const List<String> _modelosIPhone = [
    'iPhone 16 Pro Max',
    'iPhone 16 Pro',
    'iPhone 16',
    'iPhone 15 Pro Max',
    'iPhone 15 Pro',
    'iPhone 15',
    'iPhone 14 Pro Max',
    'iPhone 14 Pro',
    'iPhone 14',
    'iPhone 13 Pro Max',
    'iPhone 13 Pro',
    'iPhone 13',
    'iPhone 12 Pro',
    'iPhone 12',
  ];

  String _labelCategoria(String c) {
    switch (c) {
      case 'solido':
        return 'Color sólido';
      case 'transparente':
        return 'Transparente';
      case 'personalizada':
        return 'Personalizada';
      default:
        return 'Todas';
    }
  }

  Color _parseHex(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Future<void> _guardarCambiosProducto(
    String id, {
    String? nombre,
    String? codigoColor,
    String? fotoUrl,
    int? stock,
    bool? enDescuento,
    int? porcentajeDescuento,
  }) async {
    final Map<String, dynamic> datos = {};

    if (nombre != null && nombre.trim().isNotEmpty) {
      // Garantiza formato estricto "Funda iPhone X"
      datos['nombre'] = Producto.limpiarNombre(nombre.trim());
    }
    if (codigoColor != null) {
      datos['codigoColor'] = codigoColor.trim();
    }
    if (fotoUrl != null) {
      final url = fotoUrl.trim();
      datos['fotosUrls'] = url.isNotEmpty ? [url] : <String>[];
      datos['imagenUrl'] = url;
      datos['fotoUrl'] = url; // Soporte total para esquemas previos en Firestore
    }
    if (stock != null) {
      // Validación: no permitir valores menores a 0
      datos['stock'] = stock >= 0 ? stock : 0;
    }
    if (enDescuento != null) {
      datos['enDescuento'] = enDescuento;
    }
    if (porcentajeDescuento != null) {
      datos['porcentajeDescuento'] = porcentajeDescuento.clamp(0, 100);
    }

    try {
      if (datos.isNotEmpty) {
        await FirebaseFirestore.instance.collection('productos').doc(id).update(datos);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Guardado en Firebase en tiempo real'),
              duration: Duration(milliseconds: 1500),
              backgroundColor: AppColors.azul,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar en Firebase: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _editarStock(Producto p) async {
    final ctrl = TextEditingController(text: p.stock.toString());
    String? errorText;

    final nuevoStock = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(p.nombre, style: const TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Stock (unidades)',
                  errorText: errorText,
                  suffixText: 'unidades',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final valor = int.tryParse(ctrl.text.trim());
                if (valor == null || valor < 0) {
                  setDialogState(() {
                    errorText = 'El stock no puede ser menor a 0';
                  });
                  return;
                }
                Navigator.pop(context, valor);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (nuevoStock != null) {
      await _guardarCambiosProducto(p.id, stock: nuevoStock);
    }
  }

  Future<void> _editarDescuento(Producto p) async {
    final ctrl = TextEditingController(
      text: p.porcentajeDescuento > 0 ? p.porcentajeDescuento.toString() : '15',
    );
    final resultado = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(p.nombre, style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresá el porcentaje de descuento a aplicar:',
              style: TextStyle(fontSize: 13, color: AppColors.textoSecundario),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Porcentaje (%)',
                suffixText: '%',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [10, 15, 20, 25, 30, 50].map((pct) {
                return ActionChip(
                  label: Text('$pct%'),
                  onPressed: () => ctrl.text = pct.toString(),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final valor = int.tryParse(ctrl.text.trim());
              Navigator.pop(context, valor);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );

    if (resultado != null && resultado > 0) {
      await _guardarCambiosProducto(p.id, enDescuento: true, porcentajeDescuento: resultado);
    }
  }

  /// Diálogo dedicado e interactivo para cambiar o actualizar la foto de una funda
  Future<void> _mostrarDialogoCambiarFoto(Producto p) async {
    final urlCtrl = TextEditingController(text: p.fotoPrincipalUrl);

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final urlActual = urlCtrl.text.trim();
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.photo_camera_outlined, color: AppColors.azul),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cambiar Foto - ${p.nombre}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vista previa en vivo
                    Center(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.bordeSuave),
                        ),
                        child: AppProductImage(
                          imageUrl: urlActual,
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ingresá o pegá la URL de la imagen:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textoSecundario),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: urlCtrl,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        suffixIcon: urlCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  urlCtrl.clear();
                                  setDialogState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'O elegir foto real de catálogo sugerida:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textoSecundario),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _paletaColores.map((col) {
                        return ActionChip(
                          avatar: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _parseHex(col['hex']!),
                              shape: BoxShape.circle,
                            ),
                          ),
                          label: Text(col['nombre']!, style: const TextStyle(fontSize: 10)),
                          onPressed: () {
                            setDialogState(() {
                              urlCtrl.text = col['fotoDefecto']!;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Guardar Foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azul,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final nuevaUrl = urlCtrl.text.trim();
                    if (nuevaUrl.isEmpty || !nuevaUrl.startsWith('http')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ingresá una URL válida que empiece con http:// o https://'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(dialogCtx);
                    await _guardarCambiosProducto(p.id, fotoUrl: nuevaUrl);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// REQUERIMIENTO 4: FORMULARIO EN MODO EMPLEADO PARA CREAR NUEVAS FUNDAS EN FIREBASE
  void _mostrarModalCrearFunda() {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: 'Funda iPhone 16 Pro');
    final codigoColorCtrl = TextEditingController(text: 'negro 001');
    final precioCtrl = TextEditingController(text: '90000');
    final stockCtrl = TextEditingController(text: '15');
    final fotoUrlCtrl = TextEditingController(
      text: 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=800&auto=format&fit=crop&q=80',
    );

    String colorHexSeleccionado = '#000000';
    String modeloSeleccionado = 'iPhone 16 Pro';
    String categoriaSeleccionada = 'solido';
    bool guardando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.add_circle_outline, color: AppColors.azul, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Agregar Nueva Funda',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textoPrincipal,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Campo 1: Modelo de iPhone base
                      const Text(
                        '1. SELECCIONAR MODELO DE iPHONE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textoSecundario),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: modeloSeleccionado,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: _modelosIPhone.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              modeloSeleccionado = val;
                              nombreCtrl.text = 'Funda $val';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Nombre completo
                      const Text(
                        'NOMBRE DEL PRODUCTO (Formato: Funda iPhone...)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textoSecundario),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: InputDecoration(
                          hintText: 'Ej. Funda iPhone 16 Pro',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá el nombre' : null,
                      ),
                      const SizedBox(height: 12),

                      // Campo 2: Paleta de Colores
                      const Text(
                        '2. COLOR PRINCIPAL',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textoSecundario),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _paletaColores.map((colorItem) {
                          final hex = colorItem['hex']!;
                          final isSelected = colorHexSeleccionado == hex;
                          final colorVisual = _parseHex(hex);

                          return ChoiceChip(
                            label: Text(colorItem['nombre']!),
                            selected: isSelected,
                            selectedColor: AppColors.dorado,
                            avatar: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: colorVisual,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black26),
                              ),
                            ),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.azul : AppColors.textoPrincipal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  colorHexSeleccionado = hex;
                                  fotoUrlCtrl.text = colorItem['fotoDefecto']!;
                                  codigoColorCtrl.text = '${colorItem['nombre']!.toLowerCase()} 001';
                                  if (hex == '#E5E7EB') {
                                    categoriaSeleccionada = 'transparente';
                                  }
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Campo 3: Código de Modelo/Color y Categoría
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '3. CÓDIGO COLOR',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textoSecundario),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: codigoColorCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Ej. rojo 002',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CATEGORÍA',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textoSecundario),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  initialValue: categoriaSeleccionada,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'solido', child: Text('Sólido')),
                                    DropdownMenuItem(value: 'transparente', child: Text('Transparente')),
                                    DropdownMenuItem(value: 'personalizada', child: Text('Personalizada')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => categoriaSeleccionada = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Campo 4: Precio y Stock
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '4. PRECIO (Gs)',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textoSecundario),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: precioCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    suffixText: 'Gs',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n <= 0) return 'Precio inválido';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '5. STOCK INICIAL',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textoSecundario),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: stockCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    suffixText: 'un.',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n < 0) return 'Stock >= 0';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Campo 5: URL de la Imagen con vista previa
                      const Text(
                        '6. URL DE LA FOTO REAL DE LA FUNDA',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textoSecundario),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: fotoUrlCtrl,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          hintText: 'https://...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Ingresá la URL';
                          if (!v.trim().startsWith('http')) return 'Debe comenzar con http o https';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Vista previa pequeña de la foto
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: AppProductImage(
                            imageUrl: fotoUrlCtrl.text.trim(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botón Guardar en Firebase
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: guardando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.cloud_upload),
                          label: Text(guardando ? 'Guardando en Firebase...' : 'Crear y Publicar Funda'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azul,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: guardando
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() => guardando = true);

                                  try {
                                    final nombreSanitizado = Producto.limpiarNombre(nombreCtrl.text);
                                    final precioInt = int.parse(precioCtrl.text.trim());
                                    final stockInt = int.parse(stockCtrl.text.trim());
                                    final urlFoto = fotoUrlCtrl.text.trim();

                                    await FirebaseFirestore.instance.collection('productos').add({
                                      'nombre': nombreSanitizado,
                                      'categoria': categoriaSeleccionada,
                                      'modelosCompatibles': [modeloSeleccionado],
                                      'precio': precioInt,
                                      'colorHex': colorHexSeleccionado,
                                      'codigoColor': codigoColorCtrl.text.trim(),
                                      'personalizable': categoriaSeleccionada == 'personalizada',
                                      'stock': stockInt,
                                      'fotosUrls': [urlFoto],
                                      'imagenUrl': urlFoto,
                                      'enDescuento': false,
                                      'porcentajeDescuento': 0,
                                    });

                                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('¡"$nombreSanitizado" creada exitosamente en Firebase!'),
                                          backgroundColor: AppColors.azul,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setModalState(() => guardando = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error al guardar: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _abrirMenuDatos() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text(
                    'Mantenimiento de Firebase',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text('Herramientas de sincronización'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.sync, color: AppColors.azul),
                  title: const Text('Actualizar fotos reales y nomenclatura'),
                  subtitle: const Text('Asigna imágenes reales y formato "Funda iPhone X" a todos los productos'),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final actualizados = await CatalogoSeeder.sincronizarFotosYNomenclatura();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Catálogo actualizado: $actualizados fundas con fotos reales')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined, color: Colors.orange),
                  title: const Text('Limpiar duplicados en Firestore'),
                  subtitle: const Text('Conserva un solo documento por modelo'),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final eliminados = await CatalogoSeeder.limpiarDuplicados();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Limpieza completa: $eliminados duplicados eliminados')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.dorado),
                  title: const Text('Poblar datos semilla (10 fundas variadas)'),
                  subtitle: const Text('Inserta modelos con fotos reales si la colección está vacía'),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final count = await CatalogoSeeder.inicializarDatosSemillaSiVacio();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Datos semilla: $count cargados')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.azul,
        foregroundColor: Colors.white,
        title: const Text(
          'Panel Empleado',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storage_rounded),
            tooltip: 'Mantenimiento de datos',
            onPressed: _abrirMenuDatos,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.dorado,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Funda', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _mostrarModalCrearFunda,
      ),
      body: Column(
        children: [
          // Buscador integrado por modelo, color y código de producto
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _busqueda = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Buscar por modelo, color o código (ej. iPhone 15, rojo, 001)...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textoAtenuado),
                    suffixIcon: _busqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _busqueda = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categorias.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final cat = _categorias[idx];
                      final isSelected = cat == _categoriaFiltro;
                      return ChoiceChip(
                        label: Text(_labelCategoria(cat)),
                        selected: isSelected,
                        selectedColor: AppColors.azul,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textoPrincipal,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (_) => setState(() => _categoriaFiltro = cat),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Lista en tiempo real de productos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('productos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al sincronizar con Firebase'));
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.dorado),
                  );
                }

                var productos = snapshot.data!.docs
                    .map((d) => Producto.fromMap(d.id, d.data() as Map<String, dynamic>))
                    .toList();

                if (_categoriaFiltro != 'todas') {
                  productos = productos.where((p) => p.categoria == _categoriaFiltro).toList();
                }

                // Buscador integrado: modelo, color y código de producto (ej. 001, rojo, transparente 001)
                if (_busqueda.isNotEmpty) {
                  productos = productos.where((p) {
                    final q = _busqueda;
                    final matchNombre = p.nombre.toLowerCase().contains(q);
                    final matchCodigo = p.codigoColor.toLowerCase().contains(q);
                    final matchColorHex = p.colorHex.toLowerCase().contains(q);
                    final matchCat = p.categoria.toLowerCase().contains(q);
                    final matchModelos = p.modelosCompatibles.any((m) => m.toLowerCase().contains(q));
                    return matchNombre || matchCodigo || matchColorHex || matchCat || matchModelos;
                  }).toList();
                }

                if (productos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textoAtenuado),
                          const SizedBox(height: 12),
                          const Text(
                            'No se encontraron fundas para este filtro.',
                            style: TextStyle(color: AppColors.textoSecundario),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar la primera funda'),
                            onPressed: _mostrarModalCrearFunda,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: productos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final p = productos[i];
                    return _EmpleadoProductoEditableCard(
                      key: ValueKey(p.id),
                      producto: p,
                      onGuardar: (nombre, codigoColor, fotoUrl) => _guardarCambiosProducto(
                        p.id,
                        nombre: nombre,
                        codigoColor: codigoColor,
                        fotoUrl: fotoUrl,
                      ),
                      onEditarStock: () => _editarStock(p),
                      onEditarDescuento: () => _editarDescuento(p),
                      onEditarFoto: () => _mostrarDialogoCambiarFoto(p),
                      onToggleDescuento: (val) {
                        if (val && p.porcentajeDescuento <= 0) {
                          _editarDescuento(p);
                        } else {
                          _guardarCambiosProducto(p.id, enDescuento: val);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de empleado con inputs en línea: Nombre, Código de Modelo/Color, URL de Foto,
/// guardado on-blur / submit y validación de stock.
class _EmpleadoProductoEditableCard extends StatefulWidget {
  final Producto producto;
  final Function(String nombre, String codigoColor, String fotoUrl) onGuardar;
  final VoidCallback onEditarStock;
  final VoidCallback onEditarDescuento;
  final VoidCallback onEditarFoto;
  final ValueChanged<bool> onToggleDescuento;

  const _EmpleadoProductoEditableCard({
    super.key,
    required this.producto,
    required this.onGuardar,
    required this.onEditarStock,
    required this.onEditarDescuento,
    required this.onEditarFoto,
    required this.onToggleDescuento,
  });

  @override
  State<_EmpleadoProductoEditableCard> createState() => _EmpleadoProductoEditableCardState();
}

class _EmpleadoProductoEditableCardState extends State<_EmpleadoProductoEditableCard> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _codigoColorCtrl;
  late TextEditingController _fotoCtrl;

  late FocusNode _nombreFocus;
  late FocusNode _codigoFocus;
  late FocusNode _fotoFocus;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.producto.nombre);
    _codigoColorCtrl = TextEditingController(text: widget.producto.codigoColor);
    _fotoCtrl = TextEditingController(text: widget.producto.fotoPrincipalUrl);

    _nombreFocus = FocusNode();
    _codigoFocus = FocusNode();
    _fotoFocus = FocusNode();

    _nombreFocus.addListener(() {
      if (!_nombreFocus.hasFocus) _guardar();
    });
    _codigoFocus.addListener(() {
      if (!_codigoFocus.hasFocus) _guardar();
    });
    _fotoFocus.addListener(() {
      if (!_fotoFocus.hasFocus) _guardar();
    });
  }

  @override
  void didUpdateWidget(covariant _EmpleadoProductoEditableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.producto.nombre != widget.producto.nombre && !_nombreFocus.hasFocus) {
      _nombreCtrl.text = widget.producto.nombre;
    }
    if (oldWidget.producto.codigoColor != widget.producto.codigoColor && !_codigoFocus.hasFocus) {
      _codigoColorCtrl.text = widget.producto.codigoColor;
    }
    if (oldWidget.producto.fotoPrincipalUrl != widget.producto.fotoPrincipalUrl && !_fotoFocus.hasFocus) {
      _fotoCtrl.text = widget.producto.fotoPrincipalUrl;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _codigoColorCtrl.dispose();
    _fotoCtrl.dispose();
    _nombreFocus.dispose();
    _codigoFocus.dispose();
    _fotoFocus.dispose();
    super.dispose();
  }

  void _guardar() {
    widget.onGuardar(_nombreCtrl.text, _codigoColorCtrl.text, _fotoCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final tieneDescuento = p.enDescuento && p.porcentajeDescuento > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordeSuave),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Inputs editables
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo 1: Nombre (estrictamente "Funda iPhone X")
                    const Text(
                      'MODELO / NOMBRE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 3),
                    TextField(
                      controller: _nombreCtrl,
                      focusNode: _nombreFocus,
                      onSubmitted: (_) => _guardar(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        hintText: 'Ej. Funda iPhone 15 Pro',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Campo 2: Código de Modelo/Color
                    const Text(
                      'CÓDIGO DE MODELO/COLOR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 3),
                    TextField(
                      controller: _codigoColorCtrl,
                      focusNode: _codigoFocus,
                      onSubmitted: (_) => _guardar(),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        hintText: 'Ej. transparente 001, rojo 002',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Campo 3: URL de Foto con botón de guardado rápido
                    const Text(
                      'URL DE LA FOTO (IMAGEN REAL)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 3),
                    TextField(
                      controller: _fotoCtrl,
                      focusNode: _fotoFocus,
                      onChanged: (val) => setState(() {}),
                      onSubmitted: (_) => _guardar(),
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        hintText: 'https://...',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.azul),
                              tooltip: 'Elegir foto del catálogo o previsualizar',
                              onPressed: widget.onEditarFoto,
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle, size: 18, color: AppColors.verdeStock),
                              tooltip: 'Guardar cambios',
                              onPressed: _guardar,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Imagen a la derecha interactiva con previsualización en vivo y botón de edición
              InkWell(
                onTap: widget.onEditarFoto,
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.bordeSuave),
                      ),
                      child: AppProductImage(
                        imageUrl: _fotoCtrl.text.trim().isNotEmpty
                            ? _fotoCtrl.text.trim()
                            : p.fotoPrincipalUrl,
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.azul.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Fila inferior: Control de Stock (validación >= 0) y Descuento
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Stock con modal validado >= 0
              InkWell(
                onTap: widget.onEditarStock,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.fondo,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.bordeSuave),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.azul),
                      const SizedBox(width: 6),
                      Text(
                        'Stock: ${p.stock} un.',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.azul),
                      ),
                    ],
                  ),
                ),
              ),

              // Control de Descuento
              Row(
                children: [
                  const Text(
                    'Descuento:',
                    style: TextStyle(fontSize: 12, color: AppColors.textoSecundario, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: p.enDescuento,
                      activeThumbColor: AppColors.rojoDescuento,
                      onChanged: widget.onToggleDescuento,
                    ),
                  ),
                  InkWell(
                    onTap: widget.onEditarDescuento,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: tieneDescuento
                            ? AppColors.rojoDescuento.withValues(alpha: 0.12)
                            : AppColors.fondo,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tieneDescuento ? '${p.porcentajeDescuento}% OFF' : '0%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: tieneDescuento ? AppColors.rojoDescuento : AppColors.textoAtenuado,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}