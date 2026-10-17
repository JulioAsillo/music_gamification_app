import 'package:flutter/material.dart';

import 'profile_avatar.dart';

/// Abre la hoja para editar el nombre. Devuelve el nombre nuevo, o `null`
/// si el usuario cancela.
///
/// Se abre en el **navigator raíz** (por encima del shell de pestañas): así
/// la hoja tapa el mini-player y la barra de navegación, recibe el
/// `viewInsets` real del teclado y no depende del `Navigator` de la pestaña.
Future<String?> showEditNameSheet(BuildContext context, {required String initial}) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => EditNameSheet(initial: initial),
  );
}

/// Hoja para editar el nombre de usuario.
///
/// - Es dueña de su [TextEditingController] y [FocusNode] (se liberan al
///   desmontarse, después de la animación de salida).
/// - El [TextField] NO está dentro de un builder que se reconstruya con cada
///   tecla: solo la vista previa del avatar escucha al controller.
class EditNameSheet extends StatefulWidget {
  const EditNameSheet({super.key, required this.initial});

  final String initial;

  static const maxLength = 30;

  @override
  State<EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<EditNameSheet> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial)
    ..selection = TextSelection.collapsed(offset: widget.initial.length);
  final FocusNode _focusNode = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pedir el foco cuando la hoja ya terminó de abrirse (autofocus durante
    // la animación de entrada puede no abrir el teclado en algunos equipos).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return 'El nombre no puede estar vacío';
    if (clean.length < 2) return 'Usa al menos 2 caracteres';
    return null;
  }

  void _save() {
    final error = _validate(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre de usuario', style: tt.titleLarge),
            const SizedBox(height: 4),
            Text('Así aparecerás en tu perfil.', style: tt.bodySmall),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Solo el avatar se reconstruye al escribir.
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (_, value, _) => ProfileAvatar(name: value.text),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLength: EditNameSheet.maxLength,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      hintText: 'Escribe tu nombre',
                      errorText: _error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _save, child: const Text('Guardar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
