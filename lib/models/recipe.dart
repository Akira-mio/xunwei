import 'dart:convert';

class Recipe {
  final int? id;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final Map<String, String> health_info;
  final String? imageUrl;
  final DateTime? createdAt;

  Recipe({
    this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.health_info,
    this.imageUrl,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ingredients': ingredients.join('|'),
      'steps': steps.join('|'),
      'health_info': json.encode(health_info),
      'image_url': imageUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    // 处理 ingredients
    List<String> parseIngredients(dynamic ingredients) {
      if (ingredients is String) {
        return ingredients.split('|');
      } else if (ingredients is List) {
        return ingredients.map((e) => e.toString()).toList();
      }
      return [];
    }

    // 处理 steps
    List<String> parseSteps(dynamic steps) {
      if (steps is String) {
        return steps.split('|');
      } else if (steps is List) {
        return steps.map((e) => e.toString()).toList();
      }
      return [];
    }

    // 处理 health_info
    Map<String, String> parseHealthInfo(dynamic healthInfo) {
      if (healthInfo is String) {
        try {
          // 尝试解析 JSON 字符串
          final Map<String, dynamic> decoded = json.decode(healthInfo);
          return decoded.map((key, value) => MapEntry(key, value.toString()));
        } catch (e) {
          // 如果 JSON 解析失败，尝试解析旧格式
          try {
            final content = healthInfo.substring(1, healthInfo.length - 1);
            final pairs = content.split(',');
            final Map<String, String> result = {};
            
            for (var pair in pairs) {
              final parts = pair.split(':');
              if (parts.length == 2) {
                final key = parts[0].trim();
                final value = parts[1].trim();
                result[key] = value;
              }
            }
            
            return result;
          } catch (e) {
            return {
              'calories': '0',
              'protein': '0g',
              'carbs': '0g',
              'fat': '0g',
              'fiber': '0g'
            };
          }
        }
      } else if (healthInfo is Map) {
        return healthInfo.map((key, value) => MapEntry(key.toString(), value.toString()));
      }
      return {
        'calories': '0',
        'protein': '0g',
        'carbs': '0g',
        'fat': '0g',
        'fiber': '0g'
      };
    }

    return Recipe(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      ingredients: parseIngredients(map['ingredients']),
      steps: parseSteps(map['steps']),
      health_info: parseHealthInfo(map['health_info']),
      imageUrl: map['image_url'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
    );
  }
} 