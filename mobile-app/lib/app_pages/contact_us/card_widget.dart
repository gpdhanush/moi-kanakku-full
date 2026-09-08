import 'package:flutter/material.dart';

class CardWidget extends StatelessWidget {
  final IconData leadingIcon;
  final IconData? trailingIcon;
  final String title;
  final String subTitle;
  final VoidCallback? onPressed;

  // Constructor for CardWidget
  const CardWidget({
    super.key,
    required this.leadingIcon,
    required this.title,
    required this.subTitle,
    this.trailingIcon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.75),
          width: 1,
        ),
        // boxShadow: [
        //   BoxShadow(
        //     color: colorScheme.primary.withValues(alpha: 0.5),
        //     blurRadius: 10,
        //     offset: const Offset(0, 3),
        //     spreadRadius: 0,
        //   ),
        // ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    leadingIcon,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontFamily: "englishFont",
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subTitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                          fontFamily: "englishFont",
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPressed,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          trailingIcon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
