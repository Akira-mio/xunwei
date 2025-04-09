import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../models/recipe.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../utils/theme.dart';
import '../providers/navigation_provider.dart';
import '../components/recipe_card.dart';
import 'profile_view.dart';
import 'recipe_detail_view.dart';
import '../main.dart';
import 'dart:convert';

class RecommendationView extends StatefulWidget {
  const RecommendationView({super.key});

  @override
  State<RecommendationView> createState() => _RecommendationViewState();
}

class _RecommendationViewState extends State<RecommendationView> {
  final DatabaseService _databaseService = DatabaseService();
  final _aiService = AIService();
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isGettingRecommendations = false;
  String _selectedCuisine = '不限';
  String _selectedTaste = '不限';
  int _servingCount = 2;
  int _recipeCount = 3;
  String _additionalRequirements = '';
  List<Recipe>? _recommendations;
  String? _error;
  bool showProfileWarning = false;

  final List<String> _cuisines = [
    '不限',
    '川菜',
    '粤菜',
    '苏菜',
    '鲁菜',
    '浙菜',
    '闽菜',
    '湘菜',
    '徽菜',
  ];

  final List<String> _tastes = [
    '不限',
    '清淡',
    '麻辣',
    '酸甜',
    '咸鲜',
    '香辣',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面获得焦点时重新加载个人资料
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _databaseService.getUserProfile();
      if (!mounted) return;
      
      setState(() {
        _profile = profile;
        _isLoading = false;
        // 如果已经完善了个人资料，清除错误信息
        if (profile != null && profile.height > 0 && profile.weight > 0) {
          _error = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '加载个人资料失败';
      });
    }
  }

  void _navigateToProfile() {
    Provider.of<NavigationProvider>(context, listen: false).setIndex(3);
  }

  Future<void> _getRecommendation() async {
    if (_profile == null) {
      setState(() {
        _error = '请先完善个人信息';
      });
      return;
    }

    setState(() {
      _isGettingRecommendations = true;
      _error = null;
    });

    try {
      final recommendations = await AIService.getRecommendations(
        _profile!,
        cuisine: _selectedCuisine,
        taste: _selectedTaste,
        count: _recipeCount,
        servingCount: _servingCount,
        additionalNeeds: _additionalRequirements,
      );

      setState(() {
        _recommendations = recommendations;
        _isGettingRecommendations = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isGettingRecommendations = false;
      });
    }
  }

  void _showRecipeDetail(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailView(
          recipe: recipe,
          onFavoriteChanged: (isFavorite) {
            // 通知收藏页面刷新
            if (isFavorite) {
              final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
              navigationProvider.notifyCollectionChanged();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 检查是否需要显示提示框
    showProfileWarning = _profile == null || 
        (_profile!.height <= 0 || _profile!.weight <= 0 || 
         _profile!.height.isNaN || _profile!.weight.isNaN);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能推荐'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showProfileWarning)
                    Card(
                      color: Colors.orange[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              '为了获得更准确的推荐，请先完善您的个人信息',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                // 导航到个人资料页面
                                Provider.of<NavigationProvider>(context, listen: false).setIndex(2);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                              child: const Text('去完善'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '推荐设置',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: '菜系偏好',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedCuisine,
                            items: _cuisines.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedCuisine = newValue;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: '口味偏好',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedTaste,
                            items: _tastes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedTaste = newValue;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text('推荐菜品数量'),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _recipeCount.toDouble(),
                                  min: 1,
                                  max: 5,
                                  divisions: 4,
                                  label: '$_recipeCount道菜',
                                  onChanged: (double value) {
                                    setState(() {
                                      _recipeCount = value.round();
                                    });
                                  },
                                ),
                              ),
                              Text('$_recipeCount道菜'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('食用份数'),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _servingCount.toDouble(),
                                  min: 1,
                                  max: 8,
                                  divisions: 7,
                                  label: '$_servingCount人份',
                                  onChanged: (double value) {
                                    setState(() {
                                      _servingCount = value.round();
                                    });
                                  },
                                ),
                              ),
                              Text('$_servingCount人份'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: '额外需求',
                              hintText: '请输入您的特殊需求（如：低脂、高蛋白、素食等）',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            onChanged: (value) {
                              setState(() {
                                _additionalRequirements = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isGettingRecommendations
                                  ? null
                                  : _getRecommendation,
                              child: _isGettingRecommendations
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('获取推荐'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_recommendations != null) ...[
                    const SizedBox(height: 16),
                    ..._recommendations!.map((recipe) => RecipeCard(
                          recipe: recipe,
                          onTap: () => _showRecipeDetail(recipe),
                        )).toList(),
                  ],
                ],
              ),
            ),
    );
  }
} 