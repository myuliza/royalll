import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Formatos y tamaño aceptados para fotos de productos.
const extensionesImagen = ['jpg', 'jpeg', 'png', 'webp'];
const tamanoMaximoImagen = 5 * 1024 * 1024; // 5 MB

String? tipoMimeImagen(String extension) => switch (extension.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };

/// Valida un archivo elegido; devuelve el mensaje de error o null si está bien.
String? validarArchivoImagen(String nombre, int tamano) {
  final ext = nombre.contains('.') ? nombre.split('.').last : '';
  if (tipoMimeImagen(ext) == null) return 'Formato no permitido. Elegí una imagen JPG, PNG o WEBP.';
  if (tamano > tamanoMaximoImagen) {
    final mb = (tamano / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',');
    return 'La imagen pesa $mb MB. El máximo es 5 MB.';
  }
  if (tamano == 0) return 'El archivo está vacío.';
  return null;
}

enum _Modo { url, subir }

/// Selector de la foto de un producto: "URL" (el campo de siempre) o "Subir desde mi PC".
///
/// Al subir, la imagen va a Firebase Storage (`productos/…`) y su URL de descarga se escribe
/// en [urlController], que es el mismo campo de imagen que ya usan los formularios.
/// Funciona en web, Windows y celular trabajando con los bytes del archivo (sin rutas ni dart:io).
class SelectorImagenProducto extends StatefulWidget {
  final TextEditingController urlController;

  /// El campo de URL que ya tenía el formulario (se muestra en la opción "URL").
  final Widget campoUrl;

  /// Se llama cuando cambia la URL (para refrescar la vista previa del formulario).
  final VoidCallback? onCambio;

  /// Avisa si hay una subida en curso (para deshabilitar el botón Guardar).
  final ValueChanged<bool>? onSubiendo;

  const SelectorImagenProducto({
    super.key,
    required this.urlController,
    required this.campoUrl,
    this.onCambio,
    this.onSubiendo,
  });

  @override
  State<SelectorImagenProducto> createState() => _SelectorImagenProductoState();
}

class _SelectorImagenProductoState extends State<SelectorImagenProducto> {
  _Modo _modo = _Modo.url;
  Uint8List? _bytes;
  String? _nombre;
  double? _progreso;
  String? _error;
  bool _listo = false;
  UploadTask? _tarea;
  StreamSubscription<TaskSnapshot>? _sub;

  bool get _subiendo => _tarea != null;

  @override
  void dispose() {
    _sub?.cancel();
    _tarea?.cancel();
    super.dispose();
  }

  void _setSubiendo(UploadTask? tarea) {
    _tarea = tarea;
    widget.onSubiendo?.call(tarea != null);
  }

  Future<void> _elegir() async {
    setState(() {
      _error = null;
      _listo = false;
    });
    try {
      final archivos = await FilePicker.pickFiles(
        dialogTitle: 'Elegí la foto de la funda',
        type: FileType.custom,
        allowedExtensions: extensionesImagen,
      );
      if (archivos.isEmpty) return; // canceló
      final archivo = archivos.first;
      final tamano = archivo.lengthSync() ?? await archivo.length() ?? 0;
      final error = validarArchivoImagen(archivo.name, tamano);
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      final bytes = await archivo.readAsBytes();
      if (bytes.length > tamanoMaximoImagen) {
        setState(() => _error = validarArchivoImagen(archivo.name, bytes.length));
        return;
      }
      setState(() {
        _bytes = bytes;
        _nombre = archivo.name;
      });
      await _subir(bytes, archivo.name);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo leer el archivo. Probá con otra imagen.');
    }
  }

  Future<void> _subir(Uint8List bytes, String nombre) async {
    final ext = nombre.split('.').last.toLowerCase();
    final limpio = nombre
        .toLowerCase()
        .replaceAll(RegExp(r'\.[a-z0-9]+$'), '')
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    final ref = FirebaseStorage.instance.ref('productos/${DateTime.now().millisecondsSinceEpoch}_$limpio.$ext');

    final tarea = ref.putData(bytes, SettableMetadata(contentType: tipoMimeImagen(ext)));
    setState(() {
      _progreso = 0;
      _setSubiendo(tarea);
    });
    _sub = tarea.snapshotEvents.listen((s) {
      if (!mounted || s.totalBytes == 0) return;
      setState(() => _progreso = s.bytesTransferred / s.totalBytes);
    }, onError: (_) {});

    try {
      await tarea;
      final url = await ref.getDownloadURL();
      if (!mounted) return;
      widget.urlController.text = url;
      widget.onCambio?.call();
      setState(() {
        _listo = true;
        _progreso = null;
        _setSubiendo(null);
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _progreso = null;
        _setSubiendo(null);
        _error = switch (e.code) {
          'canceled' => 'Subida cancelada.',
          'unauthorized' || 'unauthenticated' =>
            'No tenés permiso para subir imágenes. Revisá las reglas de Storage (storage.rules.propuesta).',
          'retry-limit-exceeded' => 'Se perdió la conexión mientras subía la imagen. Intentá de nuevo.',
          'quota-exceeded' => 'Se superó el espacio disponible en Firebase Storage.',
          'bucket-not-found' || 'project-not-found' || 'no-default-bucket' =>
            'Firebase Storage no está activado en este proyecto. Activalo desde la consola de Firebase para subir imágenes.',
          _ => 'No se pudo subir la imagen (${e.code}). Intentá de nuevo.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _progreso = null;
        _setSubiendo(null);
        _error = 'No se pudo subir la imagen. Revisá tu conexión e intentá de nuevo.';
      });
    } finally {
      await _sub?.cancel();
      _sub = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedButton<_Modo>(
          segments: const [
            ButtonSegment(value: _Modo.url, label: Text('URL'), icon: Icon(Icons.link_rounded)),
            ButtonSegment(value: _Modo.subir, label: Text('Subir desde mi PC'), icon: Icon(Icons.upload_rounded)),
          ],
          selected: {_modo},
          onSelectionChanged: _subiendo ? null : (s) => setState(() => _modo = s.first),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_modo == _Modo.url)
          widget.campoUrl
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: royal.superficieAlta,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: royal.borde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Vista previa del archivo elegido (antes de guardar el producto)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: royal.fondoImagen,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: royal.borde),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _bytes != null
                          ? Image.memory(_bytes!, fit: BoxFit.contain)
                          : Icon(Icons.image_outlined, color: royal.textoAtenuado),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nombre ?? 'Ningún archivo elegido',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: royal.textoPrincipal),
                          ),
                          Text(
                            'JPG, PNG o WEBP · hasta 5 MB',
                            style: TextStyle(fontSize: 11, color: royal.textoSecundario),
                          ),
                          const SizedBox(height: 6),
                          if (_subiendo)
                            TextButton.icon(
                              onPressed: () => _tarea?.cancel(),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Cancelar subida'),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: _elegir,
                              icon: const Icon(Icons.folder_open_rounded, size: 18),
                              label: Text(_bytes == null ? 'Elegir imagen…' : 'Elegir otra'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_progreso != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(value: _progreso, minHeight: 6),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Subiendo… ${((_progreso ?? 0) * 100).round()} %',
                    style: TextStyle(fontSize: 12, color: royal.textoSecundario),
                  ),
                ],
                if (_listo) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: AppColors.verdeStock),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Imagen subida. Se guardará al confirmar el producto.',
                          style: TextStyle(fontSize: 12, color: AppColors.verdeStock, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, size: 16, color: AppColors.rojoDescuento),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.rojoDescuento)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
