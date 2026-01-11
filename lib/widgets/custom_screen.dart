import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CustomScreen extends StatelessWidget {
  final Widget child;
  final bool showOverlay;
  final List<GlobalKey>? highlightWidgetKeys;
  final VoidCallback? onOverlayTap;
  final HighlightStyle? highlightStyle;

  const CustomScreen({
    super.key,
    required this.child,
    this.showOverlay = false,
    this.highlightWidgetKeys,
    this.onOverlayTap,
    this.highlightStyle,
  });

  bool get _shouldShowOverlay =>
      showOverlay &&
      highlightWidgetKeys != null &&
      highlightWidgetKeys!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ),
        ),
        if (_shouldShowOverlay)
          Positioned.fill(
            child: _SelectiveOverlay(
              widgetKeys: highlightWidgetKeys!,
              onDarkAreaTap: onOverlayTap,
              style: highlightStyle ?? const HighlightStyle(),
            ),
          ),
      ],
    );
  }
}

class _SelectiveOverlay extends SingleChildRenderObjectWidget {
  final List<GlobalKey> widgetKeys;
  final HighlightStyle style;
  final VoidCallback? onDarkAreaTap;

  const _SelectiveOverlay({
    required this.widgetKeys,
    required this.style,
    this.onDarkAreaTap,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSelectiveOverlay(
      widgetKeys: widgetKeys,
      style: style,
      onDarkAreaTap: onDarkAreaTap,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSelectiveOverlay renderObject,
  ) {
    renderObject
      ..widgetKeys = widgetKeys
      ..style = style
      ..onDarkAreaTap = onDarkAreaTap;
  }
}

class _RenderSelectiveOverlay extends RenderBox {
  List<GlobalKey> _widgetKeys;
  HighlightStyle _style;
  VoidCallback? _onDarkAreaTap;

  _RenderSelectiveOverlay({
    required List<GlobalKey> widgetKeys,
    required HighlightStyle style,
    VoidCallback? onDarkAreaTap,
  }) : _widgetKeys = widgetKeys,
       _style = style,
       _onDarkAreaTap = onDarkAreaTap;

  List<GlobalKey> get widgetKeys => _widgetKeys;
  set widgetKeys(List<GlobalKey> value) {
    if (_widgetKeys == value) return;
    _widgetKeys = value;
    markNeedsPaint();
  }

  HighlightStyle get style => _style;
  set style(HighlightStyle value) {
    if (_style == value) return;
    _style = value;
    markNeedsPaint();
  }

  VoidCallback? get onDarkAreaTap => _onDarkAreaTap;
  set onDarkAreaTap(VoidCallback? value) {
    _onDarkAreaTap = value;
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final size = this.size;

    final paint = Paint()
      ..color = _style.overlayColor
      ..style = PaintingStyle.fill;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    for (final key in _widgetKeys) {
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox == null || !renderBox.attached) continue;

      final position = renderBox.localToGlobal(Offset.zero);
      final widgetSize = renderBox.size;

      final widgetRect = Rect.fromLTWH(
        position.dx - (_style.padding / 2),
        position.dy - (_style.padding / 2),
        widgetSize.width + _style.padding,
        widgetSize.height + _style.padding,
      );

      path.addRRect(
        RRect.fromRectAndRadius(
          widgetRect,
          Radius.circular(_style.borderRadius),
        ),
      );
    }

    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    for (final key in _widgetKeys) {
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox == null || !renderBox.attached) continue;

      final widgetPosition = renderBox.localToGlobal(Offset.zero);
      final widgetSize = renderBox.size;

      final rect = Rect.fromLTWH(
        widgetPosition.dx - (_style.padding / 2),
        widgetPosition.dy - (_style.padding / 2),
        widgetSize.width + _style.padding,
        widgetSize.height + _style.padding,
      );

      if (rect.contains(position)) {
        return false;
      }
    }

    if (size.contains(position)) {
      _onDarkAreaTap?.call();
      result.add(BoxHitTestEntry(this, position));
      return true;
    }

    return false;
  }
}

class HighlightStyle extends Equatable {
  final Color overlayColor;
  final double borderRadius;
  final double padding;

  const HighlightStyle({
    this.overlayColor = Colors.black54,
    this.borderRadius = 12.0,
    this.padding = 8.0,
  });

  @override
  List<Object?> get props => [overlayColor, borderRadius, padding];
}
