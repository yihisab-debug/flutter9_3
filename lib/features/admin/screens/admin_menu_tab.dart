import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/dish.dart';
import '../../../data/services/admin_menu_service.dart';
import 'admin_dish_form_screen.dart';

class AdminMenuTab extends StatelessWidget {
  const AdminMenuTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<AdminMenuService>();

    return Scaffold(
      body: StreamBuilder<List<Dish>>(
        stream: service.dishesStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorState(error: snap.error.toString());
          }
          final dishes = snap.data ?? [];
          if (dishes.isEmpty) {
            return _EmptyState(onSeed: () => _seedMenu(context));
          }

          final byCategory = <String, List<Dish>>{};
          for (final d in dishes) {
            byCategory.putIfAbsent(d.category, () => []).add(d);
          }
          final categoryNames = byCategory.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(total: dishes.length, categories: byCategory.length),
              const SizedBox(height: 16),
              for (final cat in categoryNames) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '$cat (${byCategory[cat]!.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                for (final dish in byCategory[cat]!)
                  _DishTile(
                    dish: dish,
                    onEdit: () => _openForm(context, dish: dish),
                    onDelete: () => _confirmDelete(context, dish),
                  ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.admin,
        icon: const Icon(Icons.add),
        label: const Text('Добавить блюдо',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  void _openForm(BuildContext context, {Dish? dish}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AdminDishFormScreen(dish: dish),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, Dish dish) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Удалить блюдо?'),
        content: Text(
          'Блюдо «${dish.name}» будет удалено из меню. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AdminMenuService>().deleteDish(dish.id);
      messenger.showSnackBar(
        SnackBar(content: Text('Блюдо «${dish.name}» удалено')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Ошибка удаления: $e'),
        ),
      );
    }
  }

  Future<void> _seedMenu(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count =
          await context.read<AdminMenuService>().seedInitialMenuIfEmpty();
      messenger.showSnackBar(
        SnackBar(
          content: Text(count > 0
              ? 'Добавлено блюд: $count'
              : 'В меню уже есть блюда — стартовый набор не добавлен'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Ошибка: $e'),
        ),
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int categories;
  const _SummaryCard({required this.total, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StatChip(value: '$total', label: 'Блюд'),
          const SizedBox(width: 12),
          _StatChip(value: '$categories', label: 'Категорий'),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _DishTile extends StatelessWidget {
  final Dish dish;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DishTile({
    required this.dish,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: onEdit,
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(dish.emoji, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(dish.name,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _MiniTag(
                  text: '${dish.price} ₸',
                  color: AppColors.price.withOpacity(0.15),
                  textColor: AppColors.price),
              _MiniTag(
                  text: '${dish.weight} г',
                  color: AppColors.surfaceElevated,
                  textColor: AppColors.textSecondary),
              for (final t in dish.tags.take(2))
                _MiniTag(
                    text: t,
                    color: AppColors.primary.withOpacity(0.15),
                    textColor: AppColors.primary),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: onDelete,
          tooltip: 'Удалить',
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const _MiniTag(
      {required this.text, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onSeed;
  const _EmptyState({required this.onSeed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Меню пусто',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Добавьте первое блюдо или загрузите стартовый набор из 20 национальных блюд',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onSeed,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Загрузить стартовое меню'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.admin,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text('Ошибка загрузки меню',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
