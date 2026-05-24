import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/complaint.dart';
import '../../../data/models/order.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/complaints_service.dart';
import 'admin_complaints_tab.dart';
import 'admin_menu_tab.dart';

class AdminRootScreen extends StatefulWidget {
  const AdminRootScreen({super.key});

  @override
  State<AdminRootScreen> createState() => _AdminRootScreenState();
}

class _AdminRootScreenState extends State<AdminRootScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('👑  ', style: TextStyle(fontSize: 22)),
            const Text('Админ-панель',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Выйти',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          _AdminStatsTab(),
          _AdminOrdersTab(),
          AdminMenuTab(),
          AdminComplaintsTab(),
          _AdminUsersTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: StreamBuilder<List<Complaint>>(
          stream: context.read<ComplaintsService>().allComplaintsStream(),
          builder: (context, snap) {
            final pending = (snap.data ?? [])
                .where((c) => c.status == ComplaintStatus.pending)
                .length;
            return BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_outlined),
                  label: 'Статистика',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_rounded),
                  label: 'Заказы',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu_rounded),
                  label: 'Меню',
                ),
                BottomNavigationBarItem(
                  icon: _ComplaintsIcon(pendingCount: pending),
                  label: 'Жалобы',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  label: 'Пользователи',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ComplaintsIcon extends StatelessWidget {
  final int pendingCount;
  const _ComplaintsIcon({required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.report_problem_outlined),
        if (pendingCount > 0)
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
              child: Text(
                pendingCount > 99 ? '99+' : '$pendingCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminStatsTab extends StatelessWidget {
  const _AdminStatsTab();

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Сводка',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('orders').snapshots(),
            builder: (context, ordersSnap) {
              final orders = ordersSnap.data?.docs ?? [];
              final pending = orders.where((d) {
                final m = d.data() as Map<String, dynamic>;
                return m['status'] == 'pending';
              }).length;
              final delivering = orders.where((d) {
                final m = d.data() as Map<String, dynamic>;
                return m['status'] == 'delivering' || m['status'] == 'confirmed';
              }).length;
              final completed = orders.where((d) {
                final m = d.data() as Map<String, dynamic>;
                return m['status'] == 'completed';
              }).length;
              final totalRevenue = orders.fold<int>(0, (sum, d) {
                final m = d.data() as Map<String, dynamic>;
                if (m['status'] != 'completed') return sum;
                return sum + ((m['total'] ?? 0) as int);
              });
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              title: 'Всего заказов',
                              value: '${orders.length}',
                              emoji: '📦',
                              color: AppColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatCard(
                              title: 'Ожидают',
                              value: '$pending',
                              emoji: '⏳',
                              color: AppColors.price)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              title: 'В пути',
                              value: '$delivering',
                              emoji: '🛵',
                              color: const Color(0xFF60A5FA))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatCard(
                              title: 'Доставлено',
                              value: '$completed',
                              emoji: '✓',
                              color: AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _StatCard(
                    title: 'Общая выручка',
                    value: '$totalRevenue ₸',
                    emoji: '💰',
                    color: AppColors.admin,
                    wide: true,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('users').snapshots(),
            builder: (context, usersSnap) {
              final users = usersSnap.data?.docs ?? [];
              final customers = users.where((d) {
                final m = d.data() as Map<String, dynamic>;
                return m['role'] == 'customer';
              }).length;
              final couriers = users.where((d) {
                final m = d.data() as Map<String, dynamic>;
                return m['role'] == 'courier';
              }).length;
              return Row(
                children: [
                  Expanded(
                      child: _StatCard(
                          title: 'Покупатели',
                          value: '$customers',
                          emoji: '🛍️',
                          color: AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _StatCard(
                          title: 'Курьеры',
                          value: '$couriers',
                          emoji: '🛵',
                          color: AppColors.price)),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('complaints').snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              final pending = docs.where((d) {
                final m = d.data() as Map<String, dynamic>;
                return m['status'] == 'pending';
              }).length;
              final approved = docs.where((d) {
                final m = d.data() as Map<String, dynamic>;
                return m['status'] == 'approved';
              }).length;
              return Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Жалоб ожидают',
                      value: '$pending',
                      emoji: '⚠️',
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: 'Возвратов сделано',
                      value: '$approved',
                      emoji: '💸',
                      color: AppColors.admin,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String emoji;
  final Color color;
  final bool wide;
  const _StatCard({
    required this.title,
    required this.value,
    required this.emoji,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: wide ? 22 : 18,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminOrdersTab extends StatelessWidget {
  const _AdminOrdersTab();

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('Все заказы',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('orders').snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                final docs = snap.data?.docs ?? [];
                final orders = docs
                    .map((d) =>
                        AppOrder.fromMap(d.id, d.data() as Map<String, dynamic>))
                    .toList();
                orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                if (orders.isEmpty) {
                  return const Center(
                    child: Text('Заказов пока нет',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _AdminOrderCard(order: orders[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final AppOrder order;
  const _AdminOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('№${order.id.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(order.status.label,
                    style: TextStyle(
                        color: _statusColor(order.status),
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Клиент: ${order.userName ?? "—"}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          if (order.courierName != null)
            Text('Курьер: ${order.courierName}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Spacer(),
              Text('${order.total} ₸',
                  style: const TextStyle(
                      color: AppColors.price,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return AppColors.price;
      case OrderStatus.confirmed:
        return const Color(0xFF4ADE80);
      case OrderStatus.delivering:
        return const Color(0xFF60A5FA);
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.canceled:
        return AppColors.error;
    }
  }
}

class _AdminUsersTab extends StatelessWidget {
  const _AdminUsersTab();

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('Пользователи',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('users').snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                final users = snap.data?.docs ?? [];
                if (users.isEmpty) {
                  return const Center(
                    child: Text('Пользователей пока нет',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final d = users[i];
                    final m = d.data() as Map<String, dynamic>;
                    final role = UserRoleX.fromString(m['role'] as String?);
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(role.emoji,
                                style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['name'] ?? '—',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14)),
                                Text(m['email'] ?? '',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11),
                                    overflow: TextOverflow.ellipsis),
                                Text(role.label,
                                    style: const TextStyle(
                                        color: AppColors.price,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          if (role == UserRole.customer && m['balance'] != null)
                            Text('${m['balance']} ₸',
                                style: const TextStyle(
                                    color: AppColors.price,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13)),
                          if (role == UserRole.courier)
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: AppColors.star, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                    '${(m['rating'] ?? 0).toStringAsFixed(1)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12)),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
