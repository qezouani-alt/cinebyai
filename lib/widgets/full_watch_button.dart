import 'package:flutter/material.dart';

/// A solid crimson watch action shared by movie and series details.
class FullWatchButton extends StatelessWidget {
  const FullWatchButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: const Color(0xFFC8102E),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: const Color(0x26FFFFFF),
          highlightColor: const Color(0x14000000),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F0),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: const Color(0xFFC8102E), size: 22),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFFFF5F0),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.only(left: 14),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Color(0xFFDE586D)),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFFFF5F0),
                      size: 21,
                    ),
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
