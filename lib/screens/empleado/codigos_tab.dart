import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/cupon.dart';
import '../../models/producto.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../utils/visual.dart';
import '../../widgets/ui/ui.dart';

String _fecha(DateTime f) =>
    '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

/// Último día incluido en la vigencia (la fecha guardada es el inicio del día siguiente).
DateTime _ultimoDia(Cupon c) =>
    c.vigenciaHasta.subtract(const Duration(seconds: 1));

Color _colorEstado(EstadoCupon e) => switch (e) {
      EstadoCupon.activo => AppColors.verdeStock,
      EstadoCupon.programado => const Color(0xFF0284C7),
      EstadoCupon.vencido => const Color(0xFF64748B),
      EstadoCupon.agotado => const Color(0xFFEA580C),
      EstadoCupon.pausado => const Color(0xFFCA8A04),
    };

String _alcance(Cupon c) => switch (c.aplicaA) {
      AlcanceCupon.categorias =>
        'Categorías: ${c.categorias.map(Categorias.etiqueta).join(', ')}',
      AlcanceCupon.modelos => 'Modelos: ${c.modelos.join(', ')}',
      _ => 'Todo el catálogo',
    };

/// Pestaña "Códigos promocionales" del panel de empleados.
class CodigosTab extends StatefulWidget {
  final List<Producto> productos;

  /// Solo para tests: códigos fijos en lugar de Firestore.
  @visibleForTesting
  final List<Cupon>? cuponesDePrueba;

  const CodigosTab({super.key, required this.productos, this.cuponesDePrueba});

  @override
  State<CodigosTab> createState() => _CodigosTabState();
}

class _CodigosTabState extends State<CodigosTab> {
  final _busquedaCtrl = TextEditingController();
  EstadoCupon? _filtroEstado;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      FirebaseFirestore.instance.collection('cupones').limit(500).snapshots();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('cupones');

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _avisar(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(texto), backgroundColor: error ? Colors.red : null),
    );
  }

  List<String> get _modelosDisponibles {
    final s = <String>{
      for (final p in widget.productos) ...p.modelosCompatibles
    };
    return s.toList()..sort((a, b) => b.compareTo(a));
  }

  Future<void> _crear() async {
    final nuevo =
        await abrirFormularioCodigo(context, modelos: _modelosDisponibles);
    if (nuevo == null) return;
    try {
      // Transacción: el código (id del documento) tiene que ser único
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final ref = _col.doc(nuevo.codigo);
        final actual = await tx.get(ref);
        if (actual.exists) {
          throw Exception('Ya existe el código ${nuevo.codigo}.');
        }
        tx.set(ref, {
          ...nuevo.toMap(),
          'usosActuales': 0,
          'creadoEn': FieldValue.serverTimestamp()
        });
      });
      _avisar('Código ${nuevo.codigo} creado');
    } catch (e) {
      _avisar('No se pudo crear: ${e.toString().replaceAll('Exception: ', '')}',
          error: true);
    }
  }

  Future<void> _editar(Cupon c) async {
    final editado = await abrirFormularioCodigo(context,
        existente: c, modelos: _modelosDisponibles);
    if (editado == null) return;
    try {
      await _col.doc(c.codigo).update(editado.toMap());
      _avisar('Código ${c.codigo} actualizado');
    } catch (e) {
      _avisar('No se pudo guardar: $e', error: true);
    }
  }

  Future<void> _alternarPausa(Cupon c) async {
    try {
      await _col.doc(c.codigo).update({'activo': !c.activo});
      _avisar(c.activo
          ? 'Código ${c.codigo} pausado'
          : 'Código ${c.codigo} activado');
    } catch (e) {
      _avisar('No se pudo actualizar: $e', error: true);
    }
  }

  Future<void> _eliminar(Cupon c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: AppColors.rojoDescuento),
        title: Text('¿Eliminar el código ${c.codigo}?'),
        content: const Text(
            'Esta acción no se puede deshacer. Las ventas ya registradas conservan el código.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.rojoDescuento,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _col.doc(c.codigo).delete();
      _avisar('Código ${c.codigo} eliminado');
    } catch (e) {
      _avisar('No se pudo eliminar: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cuponesDePrueba != null) return _vista(widget.cuponesDePrueba!);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ListView(children: [
            _encabezado(const []),
            const EmptyState.error(titulo: 'No se pudieron cargar los códigos'),
          ]);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final cupones = snapshot.data!.docs
            .map((d) => Cupon.fromMap({'codigo': d.id, ...d.data()}))
            .toList()
          ..sort((a, b) => a.codigo.compareTo(b.codigo));
        return _vista(cupones);
      },
    );
  }

  Widget _encabezado(List<Cupon> todos) {
    final royal = context.royal;
    final conteo = <EstadoCupon, int>{};
    for (final c in todos) {
      conteo[c.estado()] = (conteo[c.estado()] ?? 0) + 1;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          titulo: 'Códigos promocionales',
          subtitulo:
              'Creá descuentos por porcentaje o monto fijo, con vigencia y límites.',
          accion: 'Nuevo código',
          iconoAccion: Icons.add_rounded,
          onAccion: _crear,
        ),
        TextField(
          controller: _busquedaCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Buscar código',
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            suffixIcon: _busquedaCtrl.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar búsqueda',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(_busquedaCtrl.clear),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('Todos (${todos.length})'),
              selected: _filtroEstado == null,
              showCheckmark: false,
              labelStyle: TextStyle(
                  color: _filtroEstado == null
                      ? AppColors.azul
                      : royal.textoPrincipal),
              onSelected: (_) => setState(() => _filtroEstado = null),
            ),
            for (final e in EstadoCupon.values)
              ChoiceChip(
                avatar:
                    CircleAvatar(radius: 5, backgroundColor: _colorEstado(e)),
                label: Text('${e.etiqueta} (${conteo[e] ?? 0})'),
                selected: _filtroEstado == e,
                showCheckmark: false,
                labelStyle: TextStyle(
                    color: _filtroEstado == e
                        ? AppColors.azul
                        : royal.textoPrincipal),
                onSelected: (_) => setState(
                    () => _filtroEstado = _filtroEstado == e ? null : e),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _vista(List<Cupon> todos) {
    final q = Cupon.normalizarCodigo(_busquedaCtrl.text);
    final lista = todos
        .where((c) => q.isEmpty || c.codigo.contains(q))
        .where((c) => _filtroEstado == null || c.estado() == _filtroEstado)
        .toList();

    return LayoutBuilder(
      builder: (context, c) {
        final tabla = c.maxWidth >= 900;
        final Widget cuerpo;
        if (todos.isEmpty) {
          cuerpo = EmptyState(
            icono: Icons.confirmation_number_outlined,
            titulo: 'Todavía no hay códigos promocionales',
            mensaje: 'Creá el primero para ofrecer descuentos en el carrito.',
            accion: 'Crear código',
            onAccion: _crear,
          );
        } else if (lista.isEmpty) {
          cuerpo = const EmptyState(
              icono: Icons.search_off_rounded,
              titulo: 'Ningún código coincide con la búsqueda');
        } else if (tabla) {
          cuerpo = _Tabla(
              cupones: lista,
              onEditar: _editar,
              onPausa: _alternarPausa,
              onEliminar: _eliminar);
        } else {
          cuerpo = Column(
            children: [
              for (final cupon in lista)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _TarjetaCodigo(
                    cupon: cupon,
                    onEditar: () => _editar(cupon),
                    onPausa: () => _alternarPausa(cupon),
                    onEliminar: () => _eliminar(cupon),
                  ),
                ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
          children: [_encabezado(todos), cuerpo],
        );
      },
    );
  }
}

class _ChipEstado extends StatelessWidget {
  final EstadoCupon estado;
  const _ChipEstado(this.estado);

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(estado.etiqueta,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _Acciones extends StatelessWidget {
  final Cupon cupon;
  final VoidCallback onEditar;
  final VoidCallback onPausa;
  final VoidCallback onEliminar;

  const _Acciones(
      {required this.cupon,
      required this.onEditar,
      required this.onPausa,
      required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEditar),
        IconButton(
          tooltip: cupon.activo ? 'Pausar' : 'Activar',
          icon: Icon(cupon.activo
              ? Icons.pause_circle_outline
              : Icons.play_circle_outline),
          onPressed: onPausa,
        ),
        IconButton(
          tooltip: 'Eliminar',
          icon:
              const Icon(Icons.delete_outline, color: AppColors.rojoDescuento),
          onPressed: onEliminar,
        ),
      ],
    );
  }
}

class _Tabla extends StatelessWidget {
  final List<Cupon> cupones;
  final ValueChanged<Cupon> onEditar;
  final ValueChanged<Cupon> onPausa;
  final ValueChanged<Cupon> onEliminar;

  const _Tabla(
      {required this.cupones,
      required this.onEditar,
      required this.onPausa,
      required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    final encabezado = TextStyle(
        fontWeight: FontWeight.w700,
        color: royal.textoSecundario,
        fontSize: 12);
    final celda = TextStyle(color: royal.textoPrincipal, fontSize: 13);

    return AppCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: c.maxWidth),
            child: DataTable(
              headingTextStyle: encabezado,
              dataTextStyle: celda,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 72,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('CÓDIGO')),
                DataColumn(label: Text('DESCUENTO')),
                DataColumn(label: Text('VIGENCIA')),
                DataColumn(label: Text('USOS'), numeric: true),
                DataColumn(label: Text('MÍNIMO')),
                DataColumn(label: Text('APLICA A')),
                DataColumn(label: Text('ESTADO')),
                DataColumn(label: Text('ACCIONES')),
              ],
              rows: [
                for (final cupon in cupones)
                  DataRow(cells: [
                    DataCell(Text(cupon.codigo,
                        style: celda.copyWith(
                            fontWeight: FontWeight.w800, letterSpacing: 0.5))),
                    DataCell(Text(cupon.descripcionDescuento)),
                    DataCell(Text(
                      '${cupon.fechaInicio != null ? '${_fecha(cupon.fechaInicio!)} – ' : 'Hasta '}${_fecha(_ultimoDia(cupon))}',
                    )),
                    DataCell(Text(
                        '${cupon.usosActuales} / ${cupon.usosMaximos ?? '∞'}')),
                    DataCell(Text(cupon.compraMinima > 0
                        ? formatPrice(cupon.compraMinima)
                        : '—')),
                    DataCell(ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(_alcance(cupon),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    )),
                    DataCell(_ChipEstado(cupon.estado())),
                    DataCell(_Acciones(
                      cupon: cupon,
                      onEditar: () => onEditar(cupon),
                      onPausa: () => onPausa(cupon),
                      onEliminar: () => onEliminar(cupon),
                    )),
                  ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaCodigo extends StatelessWidget {
  final Cupon cupon;
  final VoidCallback onEditar;
  final VoidCallback onPausa;
  final VoidCallback onEliminar;

  const _TarjetaCodigo(
      {required this.cupon,
      required this.onEditar,
      required this.onPausa,
      required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    Widget fila(IconData icono, String texto) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, size: 16, color: royal.textoSecundario),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(texto,
                      style: TextStyle(
                          fontSize: 13, color: royal.textoSecundario))),
            ],
          ),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cupon.codigo,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      letterSpacing: 0.5,
                      color: royal.textoPrincipal),
                ),
              ),
              _ChipEstado(cupon.estado()),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${cupon.descripcionDescuento} de descuento',
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.dorado,
                fontSize: 15),
          ),
          fila(
            Icons.event_outlined,
            '${cupon.fechaInicio != null ? 'Desde ${_fecha(cupon.fechaInicio!)} · ' : ''}Hasta ${_fecha(_ultimoDia(cupon))}',
          ),
          fila(Icons.repeat_rounded,
              cupon.usosMaximos == null
                  ? 'Usos: ${cupon.usosActuales} (sin límite)'
                  : 'Usos: ${cupon.usosActuales} de ${cupon.usosMaximos}'),
          if (cupon.compraMinima > 0)
            fila(Icons.shopping_cart_outlined,
                'Compra mínima: ${formatPrice(cupon.compraMinima)}'),
          fila(Icons.category_outlined, _alcance(cupon)),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: _Acciones(
                cupon: cupon,
                onEditar: onEditar,
                onPausa: onPausa,
                onEliminar: onEliminar),
          ),
        ],
      ),
    );
  }
}

/// Convierte lo que se escribe a mayúsculas.
class _Mayusculas extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

/// Formulario de alta / edición. Devuelve el código armado (sin escribir en la base) o null.
Future<Cupon?> abrirFormularioCodigo(BuildContext context,
    {Cupon? existente, required List<String> modelos}) {
  final formulario = _FormularioCodigo(existente: existente, modelos: modelos);
  if (Breakpoints.esMovil(context)) {
    return showDialog<Cupon>(
        context: context, builder: (_) => Dialog.fullscreen(child: formulario));
  }
  return showDialog<Cupon>(
    context: context,
    builder: (_) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 760),
          child: formulario),
    ),
  );
}

class _FormularioCodigo extends StatefulWidget {
  final Cupon? existente;
  final List<String> modelos;
  const _FormularioCodigo({required this.existente, required this.modelos});

  @override
  State<_FormularioCodigo> createState() => _FormularioCodigoState();
}

class _FormularioCodigoState extends State<_FormularioCodigo> {
  final _formKey = GlobalKey<FormState>();
  late final _codigoCtrl =
      TextEditingController(text: widget.existente?.codigo ?? '');
  late final _valorCtrl =
      TextEditingController(text: widget.existente?.valor.toString() ?? '10');
  late final _usosCtrl = TextEditingController(
      text: widget.existente?.usosMaximos?.toString() ?? '');
  late final _minimoCtrl = TextEditingController(
    text: (widget.existente?.compraMinima ?? 0) > 0
        ? widget.existente!.compraMinima.toString()
        : '',
  );
  late String _tipo = widget.existente?.tipo ?? 'porcentaje';
  late DateTime _inicio = widget.existente?.fechaInicio ??
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  late DateTime _fin = widget.existente != null
      ? DateTime(
          _ultimoDia(widget.existente!).year,
          _ultimoDia(widget.existente!).month,
          _ultimoDia(widget.existente!).day)
      : _inicio.add(const Duration(days: 30));
  late bool _activo = widget.existente?.activo ?? true;
  late String _aplicaA = widget.existente?.aplicaA ?? AlcanceCupon.todo;
  late final Set<String> _categorias = {...?widget.existente?.categorias};
  late final Set<String> _modelos = {...?widget.existente?.modelos};
  String? _errorAlcance;

  bool get _editando => widget.existente != null;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _valorCtrl.dispose();
    _usosCtrl.dispose();
    _minimoCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha(bool esInicio) async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: esInicio ? _inicio : _fin,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5),
      helpText: esInicio ? 'Fecha de inicio' : 'Fecha de fin',
    );
    if (elegida == null) return;
    setState(() {
      if (esInicio) {
        _inicio = elegida;
        if (_fin.isBefore(_inicio)) _fin = _inicio;
      } else {
        _fin = elegida;
      }
    });
  }

  void _guardar() {
    final valido = _formKey.currentState!.validate();
    setState(() {
      _errorAlcance = switch (_aplicaA) {
        AlcanceCupon.categorias when _categorias.isEmpty =>
          'Elegí al menos una categoría.',
        AlcanceCupon.modelos when _modelos.isEmpty =>
          'Elegí al menos un modelo.',
        _ => null,
      };
    });
    if (!valido || _errorAlcance != null) return;

    final usos = int.tryParse(_usosCtrl.text.trim());
    Navigator.pop(
      context,
      Cupon(
        codigo: _editando
            ? widget.existente!.codigo
            : Cupon.normalizarCodigo(_codigoCtrl.text),
        tipo: _tipo,
        valor: int.parse(_valorCtrl.text.trim()),
        fechaInicio: _inicio,
        // Vigente hasta el final del día elegido
        vigenciaHasta: DateTime(_fin.year, _fin.month, _fin.day + 1),
        usosMaximos: usos,
        usosActuales: widget.existente?.usosActuales ?? 0,
        compraMinima: int.tryParse(_minimoCtrl.text.trim()) ?? 0,
        activo: _activo,
        aplicaA: _aplicaA,
        categorias: _aplicaA == AlcanceCupon.categorias
            ? _categorias.toList()
            : const [],
        modelos:
            _aplicaA == AlcanceCupon.modelos ? _modelos.toList() : const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    final etiqueta = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: royal.textoSecundario,
        letterSpacing: 0.4);
    final digitos = [FilteringTextInputFormatter.digitsOnly];

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando
            ? 'Editar ${widget.existente!.codigo}'
            : 'Nuevo código promocional'),
        backgroundColor: royal.superficie,
        foregroundColor: royal.textoPrincipal,
        titleTextStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: royal.textoPrincipal,
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              tooltip: 'Cerrar',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context)),
        ],
      ),
      backgroundColor: royal.superficie,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl - 4),
          children: [
            TextFormField(
              controller: _codigoCtrl,
              enabled: !_editando,
              autofocus: !_editando,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                _Mayusculas()
              ],
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Código',
                hintText: 'Ej. ROYAL10',
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                helperText: _editando
                    ? 'El código no se puede cambiar (creá uno nuevo si hace falta).'
                    : 'Mayúsculas, números, guion o guion bajo. Sin espacios.',
              ),
              validator: (v) {
                if (_editando) return null;
                final c = Cupon.normalizarCodigo(v ?? '');
                if (!Cupon.formatoCodigo.hasMatch(c)) {
                  return 'Entre 3 y 20 caracteres: A-Z, 0-9, - o _.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('TIPO DE DESCUENTO', style: etiqueta),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'porcentaje',
                    label: Text('Porcentaje'),
                    icon: Icon(Icons.percent_rounded)),
                ButtonSegment(
                    value: 'monto_fijo',
                    label: Text('Monto fijo'),
                    icon: Icon(Icons.payments_outlined)),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _valorCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: digitos,
              decoration: InputDecoration(
                labelText: 'Valor',
                suffixText: _tipo == 'porcentaje' ? '%' : 'Gs',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Ingresá un valor mayor a 0.';
                if (_tipo == 'porcentaje' && n > 100) {
                  return 'El porcentaje no puede superar 100.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('VIGENCIA', style: etiqueta),
            const SizedBox(height: 6),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text('Desde ${_fecha(_inicio)}'),
                  onPressed: () => _elegirFecha(true),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event_busy_outlined, size: 18),
                  label: Text('Hasta ${_fecha(_fin)}'),
                  onPressed: () => _elegirFecha(false),
                ),
              ],
            ),
            if (_fin.isBefore(_inicio))
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('La fecha de fin no puede ser anterior al inicio.',
                    style: TextStyle(color: AppColors.rojoDescuento)),
              ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _usosCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: digitos,
                    decoration: const InputDecoration(
                        labelText: 'Límite de usos',
                        helperText: 'Vacío = sin límite'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Mayor a 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _minimoCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: digitos,
                    decoration: const InputDecoration(
                      labelText: 'Compra mínima',
                      suffixText: 'Gs',
                      helperText: 'Vacío = sin mínimo',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Activo'),
              subtitle: Text(_activo
                  ? 'Se puede usar en el carrito'
                  : 'Pausado: no se puede usar'),
              value: _activo,
              onChanged: (v) => setState(() => _activo = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('APLICA A', style: etiqueta),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: AlcanceCupon.todo, label: Text('Todo')),
                ButtonSegment(
                    value: AlcanceCupon.categorias, label: Text('Categorías')),
                ButtonSegment(
                    value: AlcanceCupon.modelos, label: Text('Modelos')),
              ],
              selected: {_aplicaA},
              onSelectionChanged: (s) => setState(() {
                _aplicaA = s.first;
                _errorAlcance = null;
              }),
            ),
            if (_aplicaA != AlcanceCupon.todo) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_aplicaA == AlcanceCupon.categorias)
                    for (final c in Categorias.todas)
                      FilterChip(
                        avatar: Icon(c.icono, size: 16, color: c.color),
                        label: Text(c.etiqueta),
                        selected: _categorias.contains(c.id),
                        labelStyle: TextStyle(
                            color: _categorias.contains(c.id)
                                ? AppColors.azul
                                : royal.textoPrincipal),
                        onSelected: (v) => setState(() => v
                            ? _categorias.add(c.id)
                            : _categorias.remove(c.id)),
                      )
                  else
                    for (final m in widget.modelos)
                      FilterChip(
                        label: Text(m),
                        selected: _modelos.contains(m),
                        labelStyle: TextStyle(
                            color: _modelos.contains(m)
                                ? AppColors.azul
                                : royal.textoPrincipal),
                        onSelected: (v) => setState(
                            () => v ? _modelos.add(m) : _modelos.remove(m)),
                      ),
                ],
              ),
            ],
            if (_errorAlcance != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_errorAlcance!,
                    style: const TextStyle(color: AppColors.rojoDescuento)),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(
              icon: const Icon(Icons.check_rounded),
              label: Text(_editando ? 'Guardar cambios' : 'Crear código'),
              onPressed: _fin.isBefore(_inicio) ? null : _guardar,
            ),
          ],
        ),
      ),
    );
  }
}
