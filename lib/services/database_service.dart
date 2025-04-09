import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_profile.dart';
import '../models/recipe.dart';

class DatabaseService {
  static const _databaseName = 'app.db';
  static const _databaseVersion = 1;
  static const _tableName = 'user_profile'; // 统一使用user_profile作为表名

  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();
  factory DatabaseService() => instance;

  static Database? _database;
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        activity_level TEXT NOT NULL,
        daily_calories INTEGER NOT NULL,
        dietary_restrictions TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 菜谱收藏表
    await db.execute('''
      CREATE TABLE recipes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        ingredients TEXT,
        steps TEXT,
        health_info TEXT,
        image_url TEXT,
        created_at TEXT
      )
    ''');
  }

  // 用户配置相关操作
  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await database;
    await db.insert(
      _tableName,
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  // 菜谱相关操作
  Future<void> saveRecipe(Recipe recipe) async {
    final db = await database;
    
    // 检查是否已经存在相同的菜谱
    final List<Map<String, dynamic>> existingRecipes = await db.query(
      'recipes',
      where: 'name = ?',
      whereArgs: [recipe.name],
    );
    
    if (existingRecipes.isEmpty) {
      // 如果不存在，则插入新记录
      await db.insert('recipes', recipe.toMap());
    }
  }

  Future<List<Recipe>> getRecipes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('recipes');
    return maps.map((map) => Recipe.fromMap(map)).toList();
  }

  Future<void> deleteRecipe(int id) async {
    final db = await database;
    await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Recipe>> getFavoriteRecipes({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return Recipe.fromMap(maps[i]);
    });
  }
} 