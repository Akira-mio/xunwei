import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../main.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _dietaryRestrictionsController = TextEditingController();
  String _selectedActivityLevel = '久坐';
  bool _isLoading = true;
  bool _isSaving = false;
  int _dailyCalories = 0;

  final List<String> _activityLevels = [
    '久坐',
    '轻度活动',
    '中度活动',
    '重度活动',
    '极重度活动',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _dietaryRestrictionsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _databaseService.getUserProfile();
      if (profile != null) {
        setState(() {
          _heightController.text = profile.height.toString();
          _weightController.text = profile.weight.toString();
          _selectedActivityLevel = profile.activityLevel;
          _dietaryRestrictionsController.text = profile.dietaryRestrictions;
          _dailyCalories = profile.dailyCalories;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载个人资料失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateCalories() {
    if (_heightController.text.isNotEmpty && _weightController.text.isNotEmpty) {
      final height = double.tryParse(_heightController.text);
      final weight = double.tryParse(_weightController.text);
      
      if (height != null && weight != null) {
        final profile = UserProfile(
          height: height,
          weight: weight,
          activityLevel: _selectedActivityLevel,
          dailyCalories: 0,
          dietaryRestrictions: _dietaryRestrictionsController.text,
        );
        setState(() {
          _dailyCalories = profile.calculateCalorie();
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final height = double.parse(_heightController.text);
      final weight = double.parse(_weightController.text);
      
      final profile = UserProfile(
        height: height,
        weight: weight,
        activityLevel: _selectedActivityLevel,
        dailyCalories: _dailyCalories,
        dietaryRestrictions: _dietaryRestrictionsController.text,
      );

      await _databaseService.saveUserProfile(profile);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('保存成功'),
            content: const Text('个人资料已更新，需要重启应用以应用更改。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MyApp()),
                    (route) => false,
                  );
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资料'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: '身高 (cm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入身高';
                  }
                  final height = double.tryParse(value);
                  if (height == null || height <= 0) {
                    return '请输入有效的身高';
                  }
                  return null;
                },
                onChanged: (_) => _updateCalories(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: '体重 (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入体重';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return '请输入有效的体重';
                  }
                  return null;
                },
                onChanged: (_) => _updateCalories(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedActivityLevel,
                decoration: const InputDecoration(
                  labelText: '活动水平',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '久坐', child: Text('久坐')),
                  DropdownMenuItem(value: '轻度活动', child: Text('轻度活动')),
                  DropdownMenuItem(value: '中度活动', child: Text('中度活动')),
                  DropdownMenuItem(value: '高度活动', child: Text('高度活动')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedActivityLevel = value!;
                  });
                  _updateCalories();
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dietaryRestrictionsController,
                decoration: const InputDecoration(
                  labelText: '忌口',
                  hintText: '请输入您的忌口，用逗号分隔',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Text(
                '每日推荐热量: $_dailyCalories 千卡',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 