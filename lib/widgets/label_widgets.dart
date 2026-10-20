import 'package:flutter/cupertino.dart' hide Text;
import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/label_colors.dart';

/// A row of round colour choices.
class ColorSwatches extends StatelessWidget {
  const ColorSwatches({super.key, required this.selected, required this.onChanged});

  final Color selected;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in labelPalette)
          Semantics(
            button: true,
            selected: c.toARGB32() == selected.toARGB32(),
            label: 'Colour',
            child: GestureDetector(
              onTap: () => onChanged(c),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.toARGB32() == selected.toARGB32()
                        ? context.binder.text
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: c.toARGB32() == selected.toARGB32()
                    ? Icon(Icons.check_rounded, size: 16, color: onColor(c))
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// A new label: its name and its colour.
class NewLabel {
  const NewLabel(this.name, this.color);
  final String name;
  final Color color;
}

Future<NewLabel?> showNewLabelDialog(BuildContext context) {
  final controller = TextEditingController();
  var color = labelPalette[6];
  return showCupertinoDialog<NewLabel>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => CupertinoAlertDialog(
        title: const Text('New label'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              CupertinoTextField(
                controller: controller,
                placeholder: tr('e.g. Trade'),
                autofocus: true,
                maxLength: 24,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              ColorSwatches(
                selected: color,
                onChanged: (c) => setState(() => color = c),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(
              context,
              controller.text.trim().isEmpty
                  ? null
                  : NewLabel(controller.text.trim(), color),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
}

/// Pick a new colour for a label.
Future<Color?> showLabelColorDialog(
  BuildContext context, {
  required String label,
  required Color current,
}) {
  var color = current;
  return showCupertinoDialog<Color>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => CupertinoAlertDialog(
        title: Text('Colour for “$label”'),
        content: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: ColorSwatches(
            selected: color,
            onChanged: (c) => setState(() => color = c),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, color),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
