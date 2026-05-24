import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/dish.dart';
import '../../../data/services/admin_menu_service.dart';

class AdminDishFormScreen extends StatefulWidget {
  final Dish? dish;
  const AdminDishFormScreen({super.key, this.dish});

  @override
  State<AdminDishFormScreen> createState() => _AdminDishFormScreenState();
}

class _AdminDishFormScreenState extends State<AdminDishFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _weight;
  late final TextEditingController _emoji;

  late String _category;
  late Set<String> _selectedTags;

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.dish != null;

  @override
  void initState() {
    super.initState();
    final d = widget.dish;
    _name = TextEditingController(text: d?.name ?? '');
    _description = TextEditingController(text: d?.description ?? '');
    _price = TextEditingController(
        text: d?.price != null ? d!.price.toString() : '');
    _weight = TextEditingController(
        text: d?.weight != null ? d!.weight.toString() : '');
    _emoji = TextEditingController(text: d?.emoji ?? '🍽️');
    _category = d?.category ?? AdminMenuService.categories.first;
    _selectedTags = {...?d?.tags};
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _weight.dispose();
    _emoji.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Редактировать блюдо' : 'Новое блюдо',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            Center(
              child: Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _emoji.text.isEmpty ? '🍽️' : _emoji.text,
                  style: const TextStyle(fontSize: 56),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const _Label('ЭМОДЗИ'),
            TextFormField(
              controller: _emoji,
              maxLength: 4,
              decoration: const InputDecoration(
                hintText: '🍖',
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Укажите эмодзи' : null,
            ),
            const SizedBox(height: 12),

            const _Label('НАЗВАНИЕ'),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                hintText: 'Например: Бесбармак',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Введите название';
                if (v.trim().length < 2) return 'Слишком короткое название';
                return null;
              },
            ),
            const SizedBox(height: 12),

            const _Label('ОПИСАНИЕ'),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Из чего состоит блюдо, как подаётся…',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Введите описание';
                return null;
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('ЦЕНА (₸)'),
                      TextFormField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '1500'),
                        validator: _validatePositiveInt,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('ВЕС (г)'),
                      TextFormField(
                        controller: _weight,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '450'),
                        validator: _validatePositiveInt,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            const _Label('КАТЕГОРИЯ'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in AdminMenuService.categories)
                  _ChoiceChipBox(
                    label: cat,
                    selected: _category == cat,
                    onTap: () => setState(() => _category = cat),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            const _Label('ТЕГИ'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in AdminMenuService.availableTags)
                  _ChoiceChipBox(
                    label: tag,
                    selected: _selectedTags.contains(tag),
                    onTap: () => setState(() {
                      if (_selectedTags.contains(tag)) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    }),
                  ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.error))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.admin,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(_isEdit ? 'Сохранить изменения' : 'Добавить блюдо',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 12),
            if (_isEdit)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _saving ? null : _delete,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error),
                  label: const Text('Удалить блюдо',
                      style: TextStyle(color: AppColors.error)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _validatePositiveInt(String? v) {
    if (v == null || v.trim().isEmpty) return 'Введите число';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Должно быть число';
    if (n <= 0) return 'Должно быть > 0';
    return null;
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final svc = context.read<AdminMenuService>();
      final dish = Dish(
        id: widget.dish?.id ?? '',
        name: _name.text.trim(),
        description: _description.text.trim(),
        price: int.parse(_price.text.trim()),
        weight: int.parse(_weight.text.trim()),
        emoji: _emoji.text.trim(),
        category: _category,
        tags: _selectedTags.toList(),
      );

      if (_isEdit) {
        await svc.updateDish(dish);
        messenger.showSnackBar(
          SnackBar(content: Text('«${dish.name}» обновлено')),
        );
      } else {
        await svc.createDish(dish);
        messenger.showSnackBar(
          SnackBar(content: Text('«${dish.name}» добавлено в меню')),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Ошибка сохранения: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final dish = widget.dish;
    if (dish == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Удалить блюдо?'),
        content: Text('«${dish.name}» будет удалено из меню.'),
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

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AdminMenuService>().deleteDish(dish.id);
      messenger.showSnackBar(
        SnackBar(content: Text('«${dish.name}» удалено')),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = 'Ошибка удаления: $e';
        _saving = false;
      });
    }
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
            )),
      );
}

class _ChoiceChipBox extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceChipBox({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.admin.withOpacity(0.18) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.admin : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.admin : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
