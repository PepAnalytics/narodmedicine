import '../models/models.dart';

/// Сервис для работы с API бэкенда
/// На текущем этапе возвращает моковые данные
class ApiService {
  final String? baseUrl;

  ApiService({this.baseUrl});

  /// Поиск заболеваний по симптомам
  /// В будущем будет делать запрос к бэкенду
  Future<List<Disease>> searchSymptoms(List<String> symptoms) async {
    // TODO: Реализовать HTTP запрос к бэкенду
    // final response = await _client?.post(
    //   Uri.parse('$baseUrl/symptoms/search'),
    //   body: jsonEncode({'symptoms': symptoms}),
    // );

    // Возвращаем моковые данные
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Имитация задержки сети

    return [
      Disease(
        id: 1,
        name: 'Простуда',
        description:
            'Острое респираторное заболевание, вызванное вирусами. Характеризуется насморком, кашлем, повышенной температурой.',
        symptoms: const [
          Symptom(id: 1, name: 'Насморк'),
          Symptom(id: 2, name: 'Кашель'),
          Symptom(id: 3, name: 'Температура'),
        ],
      ),
      Disease(
        id: 2,
        name: 'Грипп',
        description:
            'Острое инфекционное заболевание дыхательных путей, вызванное вирусом гриппа. Сопровождается высокой температурой, слабостью, болью в мышцах.',
        symptoms: const [
          Symptom(id: 3, name: 'Температура'),
          Symptom(id: 4, name: 'Слабость'),
          Symptom(id: 5, name: 'Боль в мышцах'),
        ],
      ),
      Disease(
        id: 3,
        name: 'Ангина',
        description:
            'Острое инфекционное заболевание с поражением миндалин. Характеризуется сильной болью в горле, повышенной температурой.',
        symptoms: const [
          Symptom(id: 6, name: 'Боль в горле'),
          Symptom(id: 3, name: 'Температура'),
        ],
      ),
      Disease(
        id: 4,
        name: 'Бронхит',
        description:
            'Воспаление слизистой оболочки бронхов. Сопровождается кашлем, одышкой, затрудненным дыханием.',
        symptoms: const [
          Symptom(id: 2, name: 'Кашель'),
          Symptom(id: 7, name: 'Одышка'),
        ],
      ),
    ];
  }

  /// Получение деталей заболевания по ID
  Future<Disease> getDisease(int id) async {
    // TODO: Реализовать HTTP запрос к бэкенду
    // final response = await _client?.get(Uri.parse('$baseUrl/diseases/$id'));

    await Future.delayed(const Duration(milliseconds: 300));

    return Disease(
      id: id,
      name: 'Простуда',
      description:
          'Острое респираторное заболевание, вызванное вирусами. Характеризуется насморком, кашлем, повышенной температурой.',
      symptoms: const [
        Symptom(id: 1, name: 'Насморк'),
        Symptom(id: 2, name: 'Кашель'),
        Symptom(id: 3, name: 'Температура'),
      ],
    );
  }

  /// Получение метода лечения по ID
  Future<Remedy> getRemedy(int id) async {
    // TODO: Реализовать HTTP запрос к бэкенду
    // final response = await _client?.get(Uri.parse('$baseUrl/remedies/$id'));

    await Future.delayed(const Duration(milliseconds: 300));

    return Remedy(
      id: id,
      name: 'Чай с медом и лимоном',
      description:
          'Классическое народное средство при простуде. Помогает смягчить горло и укрепить иммунитет.',
      recipe:
          '1. Вскипятите 250 мл воды.\n2. Добавьте 1 чайную ложку меда.\n3. Выжмите сок из четверти лимона.\n4. Размешайте и пейте теплым 3-4 раза в день.',
      ingredients: const [
        Ingredient(id: 1, name: 'Мед', amount: '1 ч. л.'),
        Ingredient(id: 2, name: 'Лимон', amount: '1/4 шт.'),
        Ingredient(id: 3, name: 'Вода', amount: '250 мл'),
      ],
      risks:
          'Возможна аллергическая реакция на мед или цитрусовые. Не рекомендуется при диабете.',
      evidenceLevel: EvidenceLevel.medium,
      source: 'Народная медицина, проверено поколениями',
    );
  }

  /// Оценка метода лечения (лайк/дизлайк)
  Future<void> rateRemedy(int remedyId, bool isLike, String comment) async {
    // TODO: Реализовать HTTP запрос к бэкенду
    // final response = await _client?.post(
    //   Uri.parse('$baseUrl/remedies/$remedyId/rate'),
    //   body: jsonEncode({'isLike': isLike, 'comment': comment}),
    // );

    // ignore: avoid_print
    print('Rate remedy $remedyId: isLike=$isLike, comment=$comment');
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Получение списка методов для заболевания
  Future<List<Remedy>> getRemediesForDisease(int diseaseId) async {
    // TODO: Реализовать HTTP запрос к бэкенду

    await Future.delayed(const Duration(milliseconds: 300));

    return [
      Remedy(
        id: 1,
        name: 'Чай с медом и лимоном',
        description: 'Классическое народное средство при простуде.',
        recipe:
            '1. Вскипятите 250 мл воды.\n2. Добавьте 1 чайную ложку меда.\n3. Выжмите сок из четверти лимона.\n4. Размешайте и пейте теплым.',
        ingredients: const [
          Ingredient(id: 1, name: 'Мед', amount: '1 ч. л.'),
          Ingredient(id: 2, name: 'Лимон', amount: '1/4 шт.'),
          Ingredient(id: 3, name: 'Вода', amount: '250 мл'),
        ],
        risks: 'Возможна аллергия на мед.',
        evidenceLevel: EvidenceLevel.medium,
        source: 'Народная медицина',
      ),
      Remedy(
        id: 2,
        name: 'Ингаляция с эвкалиптом',
        description: 'Помогает при заложенности носа и кашле.',
        recipe:
            '1. Вскипятите 1 литр воды.\n2. Добавьте 5-7 капель эвкалиптового масла.\n3. Накройтесь полотенцем и дышите паром 10-15 минут.',
        ingredients: const [
          Ingredient(id: 4, name: 'Эвкалиптовое масло', amount: '5-7 капель'),
          Ingredient(id: 3, name: 'Вода', amount: '1 л'),
        ],
        risks: 'Осторожно при астме. Не используйте слишком горячий пар.',
        evidenceLevel: EvidenceLevel.high,
        source: 'Фитотерапия',
      ),
      Remedy(
        id: 3,
        name: 'Компресс из капусты',
        description: 'Народное средство при кашле и бронхите.',
        recipe:
            '1. Возьмите свежий капустный лист.\n2. Нагрейте его в горячей воде.\n3. Приложите к груди на ночь, закрепив бинтом.',
        ingredients: const [
          Ingredient(id: 5, name: 'Капустный лист', amount: '1-2 шт.'),
        ],
        risks: 'Не применять при высокой температуре.',
        evidenceLevel: EvidenceLevel.low,
        source: 'Сельская медицина',
      ),
    ];
  }
}
