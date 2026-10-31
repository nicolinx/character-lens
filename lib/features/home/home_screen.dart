import 'package:flutter/material.dart';

import 'package:character_lens/core/theme/app_colors.dart';
import 'package:character_lens/core/theme/app_text.dart';
import 'package:character_lens/features/canvas/canvas_screen.dart';
import 'package:character_lens/features/history/history_screen.dart';

/// The two tabs. Both stay built, so the strokes survive a visit to the
/// history, and the history is noted from the start.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _tab = 0;
  late var _shownAt = widget.clock();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _tab,
        children: [
          const CanvasScreen(),
          HistoryScreen(now: _shownAt),
        ],
      ),
      bottomNavigationBar: _TabBar(
        selected: _tab,
        onSelected: (index) => setState(() {
          _tab = index;
          _shownAt = widget.clock();
        }),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _Tab(
              icon: Icons.edit_outlined,
              label: 'Write',
              selected: selected == 0,
              onTap: () => onSelected(0),
            ),
            _Tab(
              icon: Icons.history,
              label: 'History',
              selected: selected == 1,
              onTap: () => onSelected(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.seal : AppColors.muted;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppText.sans(
                    size: 11.5,
                    weight: selected ? 600 : 400,
                    color: color,
                    letterSpacing: 0.5,
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
