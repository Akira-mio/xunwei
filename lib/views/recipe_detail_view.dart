import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/recipe.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';

class RecipeDetailView extends StatefulWidget {
  final Recipe recipe;
  final Function(bool)? onFavoriteChanged;

  const RecipeDetailView({
    super.key, 
    required this.recipe,
    this.onFavoriteChanged,
  });

  @override
  State<RecipeDetailView> createState() => _RecipeDetailViewState();
}

class _RecipeDetailViewState extends State<RecipeDetailView> {
  final _databaseService = DatabaseService();
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final recipes = await _databaseService.getRecipes();
      if (!mounted) return;
      
      setState(() {
        _isFavorite = recipes.any((r) => r.name == widget.recipe.name);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;  // 如果正在加载，直接返回
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFavorite) {
        // 取消收藏
        final recipes = await _databaseService.getRecipes();
        final recipeToDelete = recipes.firstWhere(
          (r) => r.name == widget.recipe.name,
          orElse: () => widget.recipe,
        );
        
        if (recipeToDelete.id != null) {
          await _databaseService.deleteRecipe(recipeToDelete.id!);
          setState(() {
            _isFavorite = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已从收藏中移除')),
            );
          }
        }
      } else {
        // 添加收藏
        await _databaseService.saveRecipe(widget.recipe);
        setState(() {
          _isFavorite = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已添加到收藏')),
          );
        }
      }
      
      // 通知父页面收藏状态变化
      widget.onFavoriteChanged?.call(_isFavorite);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _tryOpenApp(String scheme) async {
    try {
      final Uri uri = Uri.parse(scheme);
      // if (!await canLaunchUrl(uri)) {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text('未安装对应的应用')),
      //     );
      //   }
      //   return;
      // }
      
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('打开应用失败')),
        );
      }
    }
  }

  void _openXiaohongshu() {
    final recipeName = Uri.encodeComponent(widget.recipe.name);
    _tryOpenApp('xhsdiscover://search/result?keyword=$recipeName');
  }

  void _openMeituan() {
    final recipeName = Uri.encodeComponent(widget.recipe.name);
    _tryOpenApp('imeituan://www.meituan.com/search?q=$recipeName');
  }

  void _openBilibili() {
    final recipeName = Uri.encodeComponent(widget.recipe.name);
    _tryOpenApp('bilibili://search?keyword=$recipeName');
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildHealthInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.name),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white,
                  ),
            onPressed: _isLoading ? null : _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.recipe.imageUrl != null && widget.recipe.imageUrl!.isNotEmpty)
              Image.network(
                widget.recipe.imageUrl!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(
                        Icons.restaurant,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipe.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.recipe.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '食材',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.recipe.ingredients.map((ingredient) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.fiber_manual_record, size: 8),
                            const SizedBox(width: 8),
                            Text(ingredient),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                  const Text(
                    '步骤',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.recipe.steps.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(entry.value),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                  const Text(
                    '健康信息',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.recipe.health_info.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '营养信息',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildHealthInfoRow('热量', '${widget.recipe.health_info['calories'] ?? 0}卡路里'),
                            _buildHealthInfoRow('蛋白质', '${widget.recipe.health_info['protein'] ?? 0}克'),
                            _buildHealthInfoRow('碳水化合物', '${widget.recipe.health_info['carbs'] ?? 0}克'),
                            _buildHealthInfoRow('脂肪', '${widget.recipe.health_info['fat'] ?? 0}克'),
                            _buildHealthInfoRow('膳食纤维', '${widget.recipe.health_info['fiber'] ?? 0}克'),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.video_library,
                        label: '小红书',
                        color: const Color(0xFFFF2442),
                        onPressed: _openXiaohongshu,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delivery_dining,
                        label: '美团外卖',
                        color: const Color(0xFFFFD100),
                        onPressed: _openMeituan,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.video_library,
                        label: '哔哩哔哩',
                        color: const Color(0xFFFF69B4),
                        onPressed: _openBilibili,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 