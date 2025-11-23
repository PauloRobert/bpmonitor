import 'package:flutter/material.dart';

Future<DateTime?> showFixedDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    locale: const Locale('pt', 'BR'),
    builder: (context, child) {
      if (child == null) return const SizedBox.shrink();

      // Remove o botão do lápis (input mode button)
      return Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: const DatePickerThemeData(
            // Força sempre o modo calendário
            dayStyle: TextStyle(),
          ),
        ),
        child: _RemoveInputModeButton(child: child),
      );
    },
  );
}

class _RemoveInputModeButton extends StatelessWidget {
  final Widget child;

  const _RemoveInputModeButton({required this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Theme(
          data: Theme.of(context).copyWith(
            // Remove o botão do lápis via IconTheme override
            iconTheme: const IconThemeData(opacity: 0.0),
          ),
          child: child,
        );
      },
    );
  }
}