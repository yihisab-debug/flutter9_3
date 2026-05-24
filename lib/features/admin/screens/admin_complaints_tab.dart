import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/complaint.dart';
import '../../../data/services/complaints_service.dart';

class AdminComplaintsTab extends StatelessWidget {
  const AdminComplaintsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final complaints = context.watch<ComplaintsService>();
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Жалобы клиентов',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Complaint>>(
              stream: complaints.allComplaintsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  );
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🎉', style: TextStyle(fontSize: 56)),
                          SizedBox(height: 12),
                          Text(
                            'Жалоб пока нет',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _ComplaintCard(complaint: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  const _ComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final dt =
        '${complaint.createdAt.day.toString().padLeft(2, '0')}.${complaint.createdAt.month.toString().padLeft(2, '0')} '
        '${complaint.createdAt.hour.toString().padLeft(2, '0')}:${complaint.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _statusColor(complaint.status).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(complaint.reason.emoji,
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  complaint.reason.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              _statusChip(complaint.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.receipt_long,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '№${complaint.orderId.substring(0, 6).toUpperCase()}',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              Text(
                '${complaint.orderTotal} ₸',
                style: const TextStyle(
                    color: AppColors.price,
                    fontSize: 12,
                    fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                dt,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('👤 ', style: TextStyle(fontSize: 12)),
                    Text(
                      complaint.userName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
                if (complaint.courierName != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Text('🛵 ', style: TextStyle(fontSize: 12)),
                      Text(
                        complaint.courierName!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  complaint.description,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          if (complaint.status == ComplaintStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context),
                    icon: const Icon(Icons.close,
                        size: 18, color: AppColors.textSecondary),
                    label: const Text(
                      'Отклонить',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveDialog(context),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text(
                      'Одобрить',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            if (complaint.status == ComplaintStatus.approved &&
                complaint.refundAmount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'Возвращено: ${complaint.refundAmount} ₸',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            if (complaint.adminComment != null &&
                complaint.adminComment!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💬 ${complaint.adminComment}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _statusChip(ComplaintStatus s) {
    final c = _statusColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Text(
        s.label,
        style: TextStyle(
            color: c, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  Color _statusColor(ComplaintStatus s) {
    switch (s) {
      case ComplaintStatus.pending:
        return AppColors.price;
      case ComplaintStatus.approved:
        return AppColors.success;
      case ComplaintStatus.rejected:
        return AppColors.error;
    }
  }

  Future<void> _showApproveDialog(BuildContext context) async {
    final refundCtrl = TextEditingController(
      text: complaint.orderTotal.toString(),
    );
    final commentCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Одобрить жалобу',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Сумма возврата на баланс клиента (₸):',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: refundCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.attach_money, size: 18),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Комментарий (опционально):',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Например: Приносим извинения…',
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.price.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: AppColors.price),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Заказ будет отменён, деньги вернутся клиенту.',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final refund = int.tryParse(refundCtrl.text.trim()) ?? 0;
      final ok = await context.read<ComplaintsService>().approveComplaint(
            complaint: complaint,
            refundAmount: refund,
            adminComment: commentCtrl.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ok
                ? AppColors.success.withOpacity(0.9)
                : AppColors.error.withOpacity(0.9),
            content: Text(
              ok
                  ? '✓ Жалоба одобрена. Клиенту возвращено $refund ₸'
                  : 'Не удалось обработать жалобу',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final commentCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Отклонить жалобу',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Причина отказа (будет видна клиенту):',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Опишите причину…',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final ok = await context.read<ComplaintsService>().rejectComplaint(
            complaint: complaint,
            adminComment: commentCtrl.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ok
                ? AppColors.textSecondary.withOpacity(0.9)
                : AppColors.error.withOpacity(0.9),
            content: Text(
              ok ? '✓ Жалоба отклонена' : 'Не удалось обработать жалобу',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
    }
  }
}
