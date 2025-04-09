import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/recipe.dart';
import '../models/user_profile.dart';

class AIService {
  static const String _apiKey = '';
  static const String _apiUrl = '';
  static const String _model = 'gpt-4o';
  static const String _bingImageSearchUrl = 'https://cn.bing.com/images/search';

  static String _cleanJsonResponse(String response) {
    // 移除 Markdown 代码块标记
    response = response.replaceAll('```json', '');
    response = response.replaceAll('```', '');
    // 移除可能的空白字符
    response = response.trim();
    // 处理可能的 Unicode 转义序列
    try {
      // 尝试解码可能的 Unicode 转义序列
      final decoded = json.decode(response);
      return json.encode(decoded);
    } catch (e) {
      // 如果解码失败，返回原始字符串
      return response;
    }
  }

  static Future<String?> getRecommendation(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': '''你是一个专业的营养师和美食推荐专家。
请确保所有输出都使用UTF-8编码的中文字符，不要使用Unicode转义序列。
请严格按照指定的JSON格式返回数据，不要添加任何额外的文本或标记。'''
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API请求失败: ${response.statusCode} - ${response.body}');
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      final content = data['choices'][0]['message']['content'] as String;
      final cleanedContent = _cleanJsonResponse(content);
      
      // 尝试解析 JSON 以验证其格式
      final jsonData = json.decode(cleanedContent);
      if (jsonData is Map<String, dynamic>) {
        return cleanedContent;
      } else {
        throw Exception('返回的数据格式不正确');
      }
    } catch (e) {
      throw Exception('获取推荐失败: $e');
    }
  }

  static Future<String> _getRecipeImage(String recipeName) async {
    try {
      // 对中文菜名进行 URL 编码
      final encodedName = Uri.encodeComponent('$recipeName 美食 高清');
      final url = '$_bingImageSearchUrl?q=$encodedName&first=1&qft=+filterui:imagesize-large';
      
      print('\n=== 开始搜索图片 ===');
      print('搜索关键词: $recipeName');
      print('编码后的关键词: $encodedName');
      print('搜索 URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        },
      );

      print('\n=== 搜索结果 ===');
      print('HTTP 状态码: ${response.statusCode}');
      print('响应头: ${response.headers}');
      print('响应体长度: ${response.body.length} 字节');

      if (response.statusCode == 200) {
        // 解析 HTML
        final document = parser.parse(response.body);
        
        // 尝试多种选择器来获取图片
        var imageElement = document.querySelector('div.imgpt img') ?? 
                          document.querySelector('div.img_cont img') ??
                          document.querySelector('a.iusc img');
        
        if (imageElement != null) {
          String? imageUrl = imageElement.attributes['src'] ?? 
                           imageElement.attributes['data-src'] ??
                           imageElement.attributes['data-src-hq'];
          
          if (imageUrl != null) {
            // 确保 URL 是完整的
            if (!imageUrl.startsWith('http')) {
              imageUrl = 'https:$imageUrl';
            }
            
            print('\n=== 找到图片 ===');
            print('图片元素: ${imageElement.outerHtml}');
            print('图片 URL: $imageUrl');
            print('=== 图片搜索完成 ===\n');
            return imageUrl;
          }
        }
        
        print('\n=== 警告 ===');
        print('未能在 HTML 中找到图片元素');
        print('尝试查找的 HTML 片段:');
        final imgElements = document.querySelectorAll('img');
        for (var i = 0; i < (imgElements.length > 5 ? 5 : imgElements.length); i++) {
          print('图片 ${i + 1}: ${imgElements[i].outerHtml}');
        }
      } else {
        print('\n=== 错误 ===');
        print('HTTP 请求失败: ${response.statusCode}');
        print('错误信息: ${response.body}');
      }
      
      print('\n=== 使用默认图片 ===');
      final defaultImageUrl = 'https://img.zcool.cn/community/01f5f95d8c1b0ca801211d53f1a0f3.jpg@1280w_1l_2o_100sh.jpg';
      print('默认图片 URL: $defaultImageUrl');
      return defaultImageUrl;
    } catch (e) {
      print('\n=== 异常 ===');
      print('获取图片时发生错误: $e');
      print('错误类型: ${e.runtimeType}');
      print('堆栈跟踪: ${e.toString()}');
      return 'https://img.zcool.cn/community/01f5f95d8c1b0ca801211d53f1a0f3.jpg@1280w_1l_2o_100sh.jpg';
    }
  }

  static Future<List<Recipe>> getRecommendations(UserProfile profile, {
    required String cuisine,     // 菜系
    required String taste,       // 口味
    required int count,         // 推荐数量
    required int servingCount,  // 食用份数
    String? additionalNeeds,    // 额外需求
  }) async {
    try {
      final prompt = '''
作为一个专业的营养师和美食推荐专家，请根据以下用户信息推荐菜品：

用户基本信息：
- 身高：${profile.height}厘米
- 体重：${profile.weight}公斤
- 活动水平：${profile.activityLevel}
- 每日推荐热量：${profile.calculateCalorie()}卡路里
- 忌口：${profile.dietaryRestrictions.isNotEmpty ? profile.dietaryRestrictions : '无'}

用户具体需求：
- 期望菜系：${cuisine == '不限' ? '不限制特定菜系' : cuisine}
- 口味偏好：${taste == '不限' ? '不限制特定口味' : taste}
- 推荐数量：$count道菜品
- 食用份数：$servingCount人份
${additionalNeeds?.isNotEmpty == true ? '- 额外要求：$additionalNeeds\n' : ''}

请按照以下格式返回推荐菜品（使用JSON格式）：
{
  "recipes": [
    {
      "name": "菜品名称",
      "description": "菜品描述，包括主要食材和烹饪方法",
      "ingredients": ["食材1", "食材2", "食材3"],
      "steps": ["步骤1", "步骤2", "步骤3"],
      "health_info": {
        "calories": 热量（卡路里）,
        "protein": 蛋白质含量（克）,
        "carbs": 碳水化合物含量（克）,
        "fat": 脂肪含量（克）,
        "fiber": 膳食纤维含量（克）
      }
    }
  ]
}

注意事项：
1. 请确保推荐的菜品符合用户的营养需求和额外要求
2. 食材要根据食用份数写明克数
3. 步骤要详细，要有火候，时间等信息
4. 营养信息要准确合理
5. 所有数值使用数字类型，不要加单位
6. 如果用户有额外需求，请确保推荐的菜品满足这些需求
7. 需要注意用户的忌口，不要推荐用户忌口的食物
''';

      final response = await getRecommendation(prompt);
      if (response == null) {
        throw Exception('获取推荐失败');
      }

      final data = json.decode(response);
      final recipes = (data['recipes'] as List)
          .map((recipe) => Recipe.fromMap(recipe))
          .toList();

      // 为每个菜品获取图片
      final List<Recipe> updatedRecipes = [];
      for (var recipe in recipes) {
        print('Getting image for recipe: ${recipe.name}');
        final imageUrl = await _getRecipeImage(recipe.name);
        final updatedRecipe = Recipe(
          id: recipe.id,
          name: recipe.name,
          description: recipe.description,
          ingredients: recipe.ingredients,
          steps: recipe.steps,
          health_info: recipe.health_info,
          imageUrl: imageUrl,
          createdAt: recipe.createdAt,
        );
        updatedRecipes.add(updatedRecipe);
      }

      return updatedRecipes;
    } catch (e) {
      throw Exception('获取推荐失败: $e');
    }
  }
} 