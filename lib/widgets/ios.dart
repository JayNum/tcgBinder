import 'package:flutter/cupertino.dart' hide Text;
import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/label_colors.dart';

/// One row of an [showActionSheet].
class SheetAction<T> {
  const SheetAction(
    this.label,
    this.value, {
    this.checked = false,
    this.destructive = false,
  });

  final String label;
  final T value;
  final bool checked;
  final bool destructive;
}

/// An iOS action sheet that slides up from the bottom. Returns the value of
/// the tapped action, or null when cancelled.
Future<T?> showActionSheet<T>(
  BuildContext context, {
  String? title,
  String? message,
  required List<SheetAction<T>> actions,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: title == null ? null : Text(title),
      message: message == null ? null : Text(message),
      actions: [
        for (final a in actions)
          CupertinoActionSheetAction(
            isDestructiveAction: a.destructive,
            onPressed: () => Navigator.pop(context, a.value),
            child: Text(a.checked ? '✓  ${tr(a.label)}' : a.label),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ),
  );
}

/// An iOS alert asking to confirm. True when the user confirms.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final ok = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

/// A text prompt in an iOS alert. Returns the text, or null when cancelled.
Future<String?> promptDialog(
  BuildContext context, {
  required String title,
  required String placeholder,
  required String confirmLabel,
}) {
  // Not disposed on purpose: the dialog is still animating out when this
  // future completes.
  final controller = TextEditingController();
  return showCupertinoDialog<String>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(
          controller: controller,
          placeholder: tr(placeholder),
          autofocus: true,
          maxLength: 24,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// A grouped, rounded block of rows, like an inset grouped iOS list.
class GroupedSection extends StatelessWidget {
  const GroupedSection({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: tokens.chunky
            ? Border.all(color: tokens.text, width: 2.5)
            : tokens.outlined
                ? Border.all(color: tokens.border)
                : null,
        boxShadow: tokens.chunky
            ? [BoxShadow(color: tokens.text, offset: const Offset(3, 3))]
            : null,
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// Small grey heading above a grouped section.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Text(
        tr(text).toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          color: context.binder.muted,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

/// A rounded filter pill: filled with its colour when switched on. Give it
/// a [color] (a label colour) and it shows a dot of that colour when off.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.icon,
    this.color,
    this.background,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData? icon;

  /// Fill when switched on (defaults to the accent colour).
  final Color? color;

  /// Colour when switched off; defaults to the surface colour.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final fill = color ?? context.accent;
    final fg = selected ? onColor(fill) : tokens.text;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? fill : (background ?? tokens.surface),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (color != null && !selected) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                ] else if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
