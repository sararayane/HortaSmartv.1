import 'package:flutter/material.dart';

/// Área centralizada e responsiva usada pelas páginas principais.
class AreaPagina extends StatelessWidget {
  const AreaPagina({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final margemHorizontal = constraints.maxWidth < 370 ? 12.0 : constraints.maxWidth < 700 ? 17.0 : 25.0;
        final margemVertical = constraints.maxWidth < 700 ? 16.0 : 24.0;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: padding ?? EdgeInsets.fromLTRB(margemHorizontal, margemVertical, margemHorizontal, 28),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
