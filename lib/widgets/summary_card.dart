
import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final num amount;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  String formatRupiah(num value) {
    final number = value.toInt().toString();

    final formatted = number.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.more_horiz_rounded,
                color: Colors.grey.shade400,
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatRupiah(amount),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF252A3A),
              ),
            ),
          ),

          if (subtitle != null) ...[
            const SizedBox(height: 7),
            Text(
              subtitle!,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
