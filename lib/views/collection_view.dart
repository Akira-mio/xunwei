import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../providers/navigation_provider.dart';
import 'recipe_detail_view.dart';

class CollectionView extends StatefulWidget {
  const CollectionView({super.key});

  @override
  State<CollectionView> createState() => _CollectionViewState();
}

class _CollectionViewState extends State<CollectionView> {
  final _databaseService = DatabaseService();
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面获得焦点时重新加载数据
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final recipes = await _databaseService.getRecipes();
    if (!mounted) return;
    
    setState(() {
      _recipes = recipes;
      _isLoading = false;
    });
  }

  Future<void> _deleteRecipe(int id) async {
    await _databaseService.deleteRecipe(id);
    await _loadRecipes();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已从收藏中移除')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听收藏变化
    Provider.of<NavigationProvider>(context).collectionChanged;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _recipes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无收藏',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // 导航到推荐页面
                      Provider.of<NavigationProvider>(context, listen: false).setIndex(0);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      minimumSize: const Size(200, 48),
                    ),
                    child: const Text('去发现美食'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _recipes.length,
              itemBuilder: (context, index) {
                final recipe = _recipes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailView(
                            recipe: recipe,
                            onFavoriteChanged: (isFavorite) {
                              if (!isFavorite) {
                                _loadRecipes();
                              }
                            },
                          ),
                        ),
                      ).then((_) => _loadRecipes());
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              recipe.imageUrl!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 180,
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(
                                      Icons.restaurant,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      recipe.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('确认删除'),
                                          content: Text('确定要从收藏中移除 ${recipe.name} 吗？'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('取消'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteRecipe(recipe.id!);
                                              },
                                              child: const Text(
                                                '删除',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                recipe.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
} 