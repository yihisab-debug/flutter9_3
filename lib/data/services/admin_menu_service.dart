import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dish.dart';

class AdminMenuService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('dishes');

  Stream<List<Dish>> dishesStream() {
    return _col.orderBy('name').snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return Dish.fromJson(data);
      }).toList();
    });
  }

  Future<String> createDish(Dish dish) async {
    final data = dish.toJson();

    data.remove('id');
    final ref = await _col.add(data);
    return ref.id;
  }

  Future<void> updateDish(Dish dish) async {
    if (dish.id.isEmpty) {
      throw ArgumentError('Нельзя обновить блюдо без id');
    }
    final data = dish.toJson();
    data.remove('id');
    await _col.doc(dish.id).update(data);
  }

  Future<void> deleteDish(String dishId) async {
    if (dishId.isEmpty) return;
    await _col.doc(dishId).delete();
  }

  Future<int> seedInitialMenuIfEmpty() async {
    final existing = await _col.limit(1).get();
    if (existing.docs.isNotEmpty) return 0;

    final batch = _db.batch();
    for (final dish in _initialMenu) {
      final data = dish.toJson()..remove('id');
      batch.set(_col.doc(), data);
    }
    await batch.commit();
    return _initialMenu.length;
  }

  static const List<String> categories = [
    'Мясное',
    'Тесто',
    'Супы',
    'Хлеб',
    'Сладкое',
    'Напитки',
  ];

  static const List<String> availableTags = [
    'Хит',
    'Новинка',
    'Национальное',
    'Острое',
    'Веган',
  ];

  static final List<Dish> _initialMenu = [
    Dish(id: '', name: 'Бесбармак', description: 'Конина или баранина с лапшой и луковым соусом', price: 2200, category: 'Мясное', emoji: '🍖', tags: ['Хит', 'Национальное'], weight: 700),
    Dish(id: '', name: 'Куырдак', description: 'Жареные субпродукты с картофелем и луком', price: 1800, category: 'Мясное', emoji: '🥘', tags: ['Острое', 'Хит'], weight: 500),
    Dish(id: '', name: 'Казы', description: 'Домашняя конская колбаса — традиционное лакомство', price: 2500, category: 'Мясное', emoji: '🥩', tags: ['Национальное', 'Хит'], weight: 400),
    Dish(id: '', name: 'Шашлык (5 шт)', description: 'Маринованная баранина на углях', price: 2100, category: 'Мясное', emoji: '🍢', tags: ['Хит'], weight: 400),
    Dish(id: '', name: 'Куырдак из конины', description: 'Сочное мясо коня с овощами и специями', price: 2400, category: 'Мясное', emoji: '🍲', tags: ['Национальное'], weight: 550),
    Dish(id: '', name: 'Манты', description: 'С рубленым мясом и луком, на пару', price: 1500, category: 'Тесто', emoji: '🥟', tags: ['Хит', 'Национальное'], weight: 450),
    Dish(id: '', name: 'Самса', description: 'С мясом или тыквой, в слоёном тесте', price: 400, category: 'Тесто', emoji: '🥟', tags: ['Новинка'], weight: 200),
    Dish(id: '', name: 'Пельмени по-казахски', description: 'Домашние пельмени с говядиной и бараниной', price: 1700, category: 'Тесто', emoji: '🥟', tags: ['Хит'], weight: 400),
    Dish(id: '', name: 'Сорпа', description: 'Наваристый мясной бульон с лапшой', price: 1200, category: 'Супы', emoji: '🍜', tags: ['Национальное'], weight: 500),
    Dish(id: '', name: 'Лагман', description: 'Лапша ручной работы с мясом и овощами', price: 1600, category: 'Супы', emoji: '🍝', tags: ['Хит'], weight: 550),
    Dish(id: '', name: 'Кеспе', description: 'Домашний суп-лапша с курицей', price: 1300, category: 'Супы', emoji: '🍲', tags: ['Национальное'], weight: 500),
    Dish(id: '', name: 'Баурсаки', description: 'Жареные пышные пончики — к чаю', price: 500, category: 'Хлеб', emoji: '🍩', tags: ['Национальное', 'Хит'], weight: 250),
    Dish(id: '', name: 'Шелпек', description: 'Тонкие казахские лепёшки', price: 350, category: 'Хлеб', emoji: '🫓', tags: ['Национальное'], weight: 200),
    Dish(id: '', name: 'Чак-чак', description: 'Хрустящие медовые шарики из теста', price: 900, category: 'Сладкое', emoji: '🍯', tags: ['Национальное'], weight: 300),
    Dish(id: '', name: 'Талкан', description: 'Мука из жареной пшеницы с маслом и мёдом', price: 700, category: 'Сладкое', emoji: '🍡', tags: ['Национальное', 'Новинка'], weight: 300),
    Dish(id: '', name: 'Курт', description: 'Сушёный солёный творог — традиционная закуска', price: 600, category: 'Сладкое', emoji: '🧀', tags: ['Национальное'], weight: 150),
    Dish(id: '', name: 'Кумыс', description: 'Кобылье молоко — древний полезный напиток', price: 800, category: 'Напитки', emoji: '🥛', tags: ['Национальное', 'Хит'], weight: 500),
    Dish(id: '', name: 'Шубат', description: 'Верблюжье молоко — освежающий напиток', price: 900, category: 'Напитки', emoji: '🥛', tags: ['Национальное'], weight: 500),
    Dish(id: '', name: 'Айран', description: 'Кисломолочный напиток', price: 400, category: 'Напитки', emoji: '🥤', tags: ['Национальное'], weight: 400),
    Dish(id: '', name: 'Чай с молоком', description: 'Казахский чёрный чай с молоком и солью', price: 350, category: 'Напитки', emoji: '🍵', tags: ['Хит'], weight: 250),
  ];
}
