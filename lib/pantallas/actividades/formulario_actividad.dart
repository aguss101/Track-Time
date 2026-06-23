import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constantes/colores.dart';
import '../../componentes/selector_color.dart';
import '../../estado/proveedores.dart';
import '../../modelos/actividad.dart';
import '../../modelos/grupo.dart';

class FormularioActividad extends ConsumerStatefulWidget {
  final Actividad? actividad;
  const FormularioActividad({super.key, this.actividad});

  @override
  ConsumerState<FormularioActividad> createState() =>
      _FormularioActividadState();
}

class _FormularioActividadState extends ConsumerState<FormularioActividad> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;

  late String _colorHex;
  int? _idGrupo;
  late Set<int> _dias;
  late Set<int> _meses;

  int? _objDiario;
  int? _objSemanal;
  int? _objMensual;
  int? _objAnual;

  bool _guardando = false;

  static const _diasLabel = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _mesesLabel = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
  ];

  bool get _esEdicion => widget.actividad != null;

  @override
  void initState() {
    super.initState();
    final a = widget.actividad;
    _nombre = TextEditingController(text: a?.nombre ?? '');
    _colorHex = a?.color ?? ColoresActividad.aHex(ColoresActividad.todos.first);
    _idGrupo = a?.idGrupo;
    _dias = {...?a?.dias};
    _meses = {...?a?.meses};
    _objDiario = a?.objetivoDiario;
    _objSemanal = a?.objetivoSemanal;
    _objMensual = a?.objetivoMensual;
    _objAnual = a?.objetivoAnual;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final base = Actividad(
      id: widget.actividad?.id ?? 0,
      idGrupo: _idGrupo,
      nombre: _nombre.text.trim(),
      color: _colorHex,
      dias: (_dias.toList()..sort()),
      meses: (_meses.toList()..sort()),
      objetivoDiario: _objDiario,
      objetivoSemanal: _objSemanal,
      objetivoMensual: _objMensual,
      objetivoAnual: _objAnual,
    );

    try {
      final notifier = ref.read(actividadesProvider.notifier);
      if (_esEdicion) {
        await notifier.actualizar(base);
      } else {
        await notifier.crear(base);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grupos = ref.watch(gruposProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar actividad' : 'Nueva actividad'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _nombre,
              style: const TextStyle(color: Colores.textoPrimario),
              decoration: const InputDecoration(labelText: 'Nombre'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresá un nombre' : null,
            ),
            const SizedBox(height: 24),

            _Seccion('Color'),
            SelectorColor(
              seleccionadoHex: _colorHex,
              alElegir: (hex) => setState(() => _colorHex = hex),
            ),
            const SizedBox(height: 24),

            _Seccion('Grupo'),
            grupos.when(
              loading: () => const LinearProgressIndicator(color: Colores.acento),
              error: (_, _) => const Text('No se pudieron cargar los grupos',
                  style: TextStyle(color: Colores.textoSecundario)),
              data: (lista) => _DropdownGrupo(
                grupos: lista,
                seleccionado: _idGrupo,
                alElegir: (id) => setState(() => _idGrupo = id),
              ),
            ),
            const SizedBox(height: 24),

            _Seccion('Días (opcional)'),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                final dia = i + 1;
                final activo = _dias.contains(dia);
                return _Chip(
                  texto: _diasLabel[i],
                  activo: activo,
                  alTocar: () => setState(() =>
                      activo ? _dias.remove(dia) : _dias.add(dia)),
                );
              }),
            ),
            const SizedBox(height: 24),

            _Seccion('Meses (opcional)'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(12, (i) {
                final mes = i + 1;
                final activo = _meses.contains(mes);
                return _Chip(
                  texto: _mesesLabel[i],
                  activo: activo,
                  alTocar: () => setState(() =>
                      activo ? _meses.remove(mes) : _meses.add(mes)),
                );
              }),
            ),
            const SizedBox(height: 24),

            _Seccion('Objetivos (opcional)'),
            _CampoObjetivo(
              etiqueta: 'Diario',
              segundos: _objDiario,
              alCambiar: (s) => setState(() => _objDiario = s),
            ),
            _CampoObjetivo(
              etiqueta: 'Semanal',
              segundos: _objSemanal,
              alCambiar: (s) => setState(() => _objSemanal = s),
            ),
            _CampoObjetivo(
              etiqueta: 'Mensual',
              segundos: _objMensual,
              alCambiar: (s) => setState(() => _objMensual = s),
            ),
            _CampoObjetivo(
              etiqueta: 'Anual',
              segundos: _objAnual,
              alCambiar: (s) => setState(() => _objAnual = s),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : Text(_esEdicion ? 'Guardar cambios' : 'Crear actividad'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String texto;
  const _Seccion(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colores.textoSecundario,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback alTocar;

  const _Chip({
    required this.texto,
    required this.activo,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? Colores.acento : Colores.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? Colores.acento : Colores.borde),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: activo ? Colors.black : Colores.textoSecundario,
            fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DropdownGrupo extends StatelessWidget {
  final List<Grupo> grupos;
  final int? seleccionado;
  final ValueChanged<int?> alElegir;

  const _DropdownGrupo({
    required this.grupos,
    required this.seleccionado,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colores.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colores.borde),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: seleccionado,
          isExpanded: true,
          dropdownColor: Colores.card,
          hint: const Text('Sin grupo',
              style: TextStyle(color: Colores.textoSecundario)),
          style: const TextStyle(color: Colores.textoPrimario, fontSize: 15),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Sin grupo'),
            ),
            ...grupos.map((g) => DropdownMenuItem<int?>(
                  value: g.id,
                  child: Text(g.nombre),
                )),
          ],
          onChanged: alElegir,
        ),
      ),
    );
  }
}

class _CampoObjetivo extends StatefulWidget {
  final String etiqueta;
  final int? segundos;
  final ValueChanged<int?> alCambiar;

  const _CampoObjetivo({
    required this.etiqueta,
    required this.segundos,
    required this.alCambiar,
  });

  @override
  State<_CampoObjetivo> createState() => _CampoObjetivoState();
}

class _CampoObjetivoState extends State<_CampoObjetivo> {
  late final TextEditingController _horas;
  late final TextEditingController _minutos;

  @override
  void initState() {
    super.initState();
    final s = widget.segundos;
    _horas = TextEditingController(text: s == null ? '' : '${s ~/ 3600}');
    _minutos =
        TextEditingController(text: s == null ? '' : '${(s % 3600) ~/ 60}');
  }

  @override
  void dispose() {
    _horas.dispose();
    _minutos.dispose();
    super.dispose();
  }

  void _recalcular() {
    final h = int.tryParse(_horas.text) ?? 0;
    final m = int.tryParse(_minutos.text) ?? 0;
    final total = h * 3600 + m * 60;
    widget.alCambiar(total == 0 ? null : total);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              widget.etiqueta,
              style: const TextStyle(
                  color: Colores.textoPrimario, fontSize: 15),
            ),
          ),
          Expanded(child: _num(_horas, 'h')),
          const SizedBox(width: 12),
          Expanded(child: _num(_minutos, 'min')),
        ],
      ),
    );
  }

  Widget _num(TextEditingController c, String sufijo) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: Colores.textoPrimario),
      onChanged: (_) => _recalcular(),
      decoration: InputDecoration(
        isDense: true,
        hintText: '0',
        suffixText: sufijo,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
