import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class DsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const DsCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class DsEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const DsEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          )),
          if (onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel ?? 'Adicionar')),
          ],
        ],
      ),
    );
  }
}

class DsLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const DsLoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class DsTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const DsTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffix: suffix,
      ),
    );
  }
}

class DsCurrencyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const DsCurrencyField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DsTextField(
      controller: controller,
      label: label,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      prefixIcon: Icons.attach_money,
      validator: validator ?? (v) {
        if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
        final parsed = double.tryParse(v.replaceAll(',', '.'));
        if (parsed == null || parsed <= 0) return 'Valor inválido';
        return null;
      },
    );
  }
}

class DsErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const DsErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        border: Border(left: BorderSide(color: AppColors.error, width: 4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: AppColors.error))),
          if (onDismiss != null)
            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onDismiss),
        ],
      ),
    );
  }
}
