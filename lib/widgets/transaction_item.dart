
import 'package:flutter/material.dart';

class TransactionItem extends StatelessWidget {
  final String title;
  final String category;
  final String date;
  final num amount;
  final bool isIncome;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionItem({
    super.key,
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
    required this.isIncome,
    required this.icon,
    this.onTap,
    this.onEdit,
    this.onDelete,
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
    final color = isIncome
        ? const Color(0xFF20A779)
        : const Color(0xFFE65B65);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$category • $date',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${formatRupiah(amount)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),

                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 19,
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 9),
                              Text('Edit'),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                              SizedBox(width: 9),
                              Text(
                                'Hapus',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
