import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';
import 'package:character_lens/domain/ink/stroke_point.dart';
import 'package:character_lens/domain/ink/writing_area.dart';
import 'package:character_lens/features/canvas/controllers/canvas_controller.dart';
import 'package:character_lens/features/canvas/widgets/canvas_painters.dart';
import 'package:character_lens/features/canvas/controllers/model_status_controller.dart';

class WritingPad extends ConsumerStatefulWidget {
  const WritingPad({super.key});

  @override
  ConsumerState<WritingPad> createState() => _WritingPadState();
}

class _WritingPadState extends ConsumerState<WritingPad> {
  int? _pointer;
  Size _size = Size.zero;

  CanvasController get _controller =>
      ref.read(canvasControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.seal, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _reportSize(constraints.biggest);
            return Semantics(
              label: 'Drawing area: write one character with your finger',
              image: true,
              child: RawGestureDetector(
                // Claims every touch at once, so a scrolling page above the
                // pad cannot take a vertical stroke for a scroll.
                gestures: {
                  EagerGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        EagerGestureRecognizer
                      >(EagerGestureRecognizer.new, (_) {}),
                },
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _onDown,
                  onPointerMove: _onMove,
                  onPointerUp: _onEnd,
                  onPointerCancel: _onEnd,
                  child: const Stack(
                    fit: StackFit.expand,
                    children: [
                      RepaintBoundary(
                        child: CustomPaint(painter: PracticeSheetPainter()),
                      ),
                      RepaintBoundary(child: _StrokeLayer()),
                      _PadMessage(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Done after the frame, because the controller may clear strokes when the size
  /// changes.
  void _reportSize(Size size) {
    if (size == _size) return;
    _size = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.updateWritingArea(
        WritingArea(width: size.width, height: size.height),
      );
    });
  }

  void _onDown(PointerDownEvent event) {
    // One finger draws; a second one is ignored until the first lifts.
    if (_pointer != null || !ref.read(drawingEnabledProvider)) return;
    _pointer = event.pointer;
    _controller.startStroke(_pointFor(event));
  }

  void _onMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    _controller.addPoint(_pointFor(event));
  }

  void _onEnd(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    _controller.endStroke();
  }

  StrokePoint _pointFor(PointerEvent event) => StrokePoint(
    x: event.localPosition.dx.clamp(0, _size.width),
    y: event.localPosition.dy.clamp(0, _size.height),
    timestampMs: event.timeStamp.inMilliseconds,
  );
}

class _StrokeLayer extends ConsumerWidget {
  const _StrokeLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strokes = ref.watch(
      canvasControllerProvider.select((s) => s.strokes),
    );
    return CustomPaint(painter: StrokePainter(strokes));
  }
}

class _PadMessage extends ConsumerWidget {
  const _PadMessage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(selectedModelStatusProvider);
    final enabled = ref.watch(drawingEnabledProvider);
    final empty = ref.watch(
      canvasControllerProvider.select((s) => s.strokes.isEmpty),
    );

    if (!enabled) {
      return ColoredBox(
        color: AppColors.sheet.withValues(alpha: 0.9),
        child: Center(
          child: Semantics(
            liveRegion: true,
            child: Text(
              status == null
                  ? 'Checking the model…'
                  : 'Download the model to start',
              textAlign: TextAlign.center,
              style: AppText.sans(size: 14, color: AppColors.muted),
            ),
          ),
        ),
      );
    }

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: empty ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Write one character',
                  textAlign: TextAlign.center,
                  style: AppText.serif(
                    size: 22,
                    height: 1.2,
                    italic: true,
                    color: AppColors.hint,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Strokes stay on your device',
                  textAlign: TextAlign.center,
                  style: AppText.sans(size: 12.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
