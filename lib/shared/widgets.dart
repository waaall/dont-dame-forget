import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'strings.dart';
import 'theme.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class ContentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const ContentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}

class SoftPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const SoftPill(this.label, {super.key, required this.color, this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
          ),
        ),
      ],
    ),
  );
}

class EmptyContent extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final Widget? action;
  const EmptyContent({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 12),
    child: Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(29),
          ),
          child: Icon(icon, size: 38, color: AppColors.orange),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(
            height: 1.7,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 24), action!],
      ],
    ),
  );
}

Future<int?> chooseDuration(BuildContext context, int initial) =>
    showDialog<int>(context: context, builder: (_) => _DurationDialog(initial));

class _DurationDialog extends StatefulWidget {
  final int initial;
  const _DurationDialog(this.initial);
  @override
  State<_DurationDialog> createState() => _DurationDialogState();
}

class _DurationDialogState extends State<_DurationDialog> {
  late final _controller = TextEditingController(text: '${widget.initial}');
  String? _error;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.chooseDuration),
    content: SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            children: [5, 10, 15, 30, 60, 120]
                .map(
                  (minutes) => ActionChip(
                    label: Text(context.durationLabel(minutes)),
                    onPressed: () => Navigator.pop(context, minutes),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              labelText: context.l10n.customDuration,
              suffixText: context.l10n.minutes,
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(onPressed: _save, child: Text(context.l10n.done)),
    ],
  );
  void _save() {
    final minutes = int.tryParse(_controller.text) ?? 0;
    if (minutes < 1 || minutes > 1440) {
      setState(() => _error = context.l10n.errorDuration);
      return;
    }
    Navigator.pop(context, minutes);
  }
}

Route<T> appRoute<T>(WidgetBuilder builder) =>
    MaterialPageRoute<T>(builder: builder);
