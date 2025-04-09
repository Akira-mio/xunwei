class UserProfile {
  final int? id;
  final double height;
  final double weight;
  final String activityLevel;
  final int dailyCalories;
  final String dietaryRestrictions;
  String dietaryHabits;
  List<String> allergies;
  List<String> restrictions;

  UserProfile({
    this.id,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.dailyCalories,
    this.dietaryRestrictions = '',
    this.dietaryHabits = '',
    this.allergies = const [],
    this.restrictions = const [],
  });

  // 计算每日所需热量
  int calculateCalorie() {
    // 基础代谢率（BMR）计算
    double bmr = 10 * weight + 6.25 * height - 5 * 25; // 假设年龄为25岁
    
    // 根据活动水平调整
    double activityMultiplier = 1.2; // 默认久坐
    switch (activityLevel) {
      case '轻度活动':
        activityMultiplier = 1.375;
        break;
      case '中度活动':
        activityMultiplier = 1.55;
        break;
      case '高度活动':
        activityMultiplier = 1.725;
        break;
      case '极重度活动':
        activityMultiplier = 1.9;
        break;
    }
    
    return (bmr * activityMultiplier).round();
  }

  // 转换为Map以便存储
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'height': height,
      'weight': weight,
      'activity_level': activityLevel,
      'daily_calories': dailyCalories,
      'dietary_restrictions': dietaryRestrictions,
    };
  }

  // 从Map创建实例
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      height: map['height'] as double,
      weight: map['weight'] as double,
      activityLevel: map['activity_level'] as String,
      dailyCalories: map['daily_calories'] as int,
      dietaryRestrictions: map['dietary_restrictions'] as String? ?? '',
    );
  }
} 