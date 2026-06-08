import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class AdaptiveNav extends StatelessWidget {
  final Widget body;
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget? drawer;
  final String? title;
  final List<Widget>? actions;

  const AdaptiveNav({
    super.key,
    required this.body,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.drawer,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return Scaffold(
        appBar: AppBar(title: Text(title ?? ''), actions: actions),
        body: Row(
          children: [
            NavigationRail(
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: d.icon,
                        selectedIcon: d.selectedIcon ?? d.icon,
                        label: Text(d.label),
                      ))
                  .toList(),
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: body),
          ],
        ),
        drawer: drawer,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title ?? ''), actions: actions),
      body: body,
      bottomNavigationBar: NavigationBar(
        destinations: destinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
      ),
      drawer: drawer,
    );
  }
}
