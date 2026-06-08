import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AssinanteBadge extends StatefulWidget {
  final bool mini;

  const AssinanteBadge({super.key, this.mini = false});

  @override
  State<AssinanteBadge> createState() => _AssinanteBadgeState();
}

class _AssinanteBadgeState extends State<AssinanteBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mini) {
      return AnimatedBuilder(
        animation: _glow,
        builder: (_, __) => Icon(
          Icons.star,
          color: AppColors.gold.withOpacity(_glow.value),
          size: 16,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gold.withOpacity(_glow.value),
              AppColors.goldLight.withOpacity(_glow.value),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(_glow.value * 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(
              'VIP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
