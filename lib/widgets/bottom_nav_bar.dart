import 'package:flutter/material.dart';
import '../utils/colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Inicio',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.favorite_rounded,
                  label: 'Matches',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.error_outline,
                  label: 'Quejas',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.smart_toy_rounded,
                  label: 'Chatbot',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Perfil',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: isSelected ? 10 : 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? null
              : null,
          color: isSelected ? Colors.pink.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(isSelected ? 20 : 16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                size: isSelected ? 28 : 24,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 300),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  letterSpacing: isSelected ? 0.3 : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}