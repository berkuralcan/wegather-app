import 'package:flutter/material.dart';
import 'package:wegather_app/global_widgets/wg_tab_selector.dart';

/// A [WgTabSelector] with the page it switches underneath it, the two halves
/// sliding the way the selection moved.
///
/// Like the selector it wraps, this is deliberately dumb: it renders [labels],
/// marks [selectedIndex], reports taps through [onSelected] and shows whatever
/// [child] the parent hands back for the tab it settled on. The parent owns the
/// selection, so it can persist it, react to it, or drive it from elsewhere.
///
/// The direction of the slide is the one thing the widget works out itself, by
/// watching [selectedIndex] change: a tab further right enters from the right
/// and pushes the one it replaces off to the left, and the other way back. That
/// is presentation, not state, so it stays in here.
class WgTabView extends StatefulWidget {
  const WgTabView({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    required this.child,
    this.spacing = 16,
  });

  /// The tabs to offer, in the order they should appear — already localised.
  final List<String> labels;

  /// The index into [labels] that is currently selected.
  final int selectedIndex;

  /// Called with the tapped tab's index — including one already selected.
  final ValueChanged<int> onSelected;

  /// The page belonging to [selectedIndex]. Rebuild it with a different widget
  /// when the index changes and it slides in; the widget keys the page by
  /// index, so the parent doesn't have to.
  final Widget child;

  /// The gap between the tabs and the page under them.
  final double spacing;

  /// How long a page takes to slide in.
  static const _slide = Duration(milliseconds: 250);

  @override
  State<WgTabView> createState() => _WgTabViewState();
}

class _WgTabViewState extends State<WgTabView> {
  /// Whether the page coming in sits to the *right* of the one going out.
  bool _forward = true;

  @override
  void didUpdateWidget(WgTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _forward = widget.selectedIndex > oldWidget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WgTabSelector(
          labels: widget.labels,
          selectedIndex: widget.selectedIndex,
          onSelected: widget.onSelected,
        ),
        SizedBox(height: widget.spacing),
        // Clipped to its own box: the pages are full-width, so without this the
        // one on its way out would paint over whatever surrounds the widget.
        ClipRect(
          child: AnimatedSwitcher(
            duration: WgTabView._slide,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            // The default switcher centres its children on each other and sizes
            // itself to the largest. Pages are rarely the same height, so pin
            // them to the top-left instead and let the taller one decide the
            // height for the length of the transition.
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, if (current != null) current],
            ),
            transitionBuilder: (child, animation) {
              // Both pages are built with this one builder — the outgoing one
              // simply runs its animation backwards — so the side a page starts
              // from depends on which of the two it is.
              final isIncoming =
                  (child.key as ValueKey<int>?)?.value == widget.selectedIndex;
              final from = _forward == isIncoming ? 1.0 : -1.0;
              return SlideTransition(
                position: Tween(
                  begin: Offset(from, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(widget.selectedIndex),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}
