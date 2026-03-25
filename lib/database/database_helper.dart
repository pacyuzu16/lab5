import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static const _postsKey = 'posts';
  static const _nextIdKey = 'next_id';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<Post>> _loadPosts() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_postsKey);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded.map((e) => Post.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _savePosts(List<Post> posts) async {
    final prefs = await _prefs;
    await prefs.setString(_postsKey, jsonEncode(posts.map((p) => p.toMap()).toList()));
  }

  Future<int> _nextId() async {
    final prefs = await _prefs;
    final id = prefs.getInt(_nextIdKey) ?? 1;
    await prefs.setInt(_nextIdKey, id + 1);
    return id;
  }

  // CREATE
  Future<int> insertPost(Post post) async {
    try {
      final id = await _nextId();
      final posts = await _loadPosts();
      posts.insert(0, post.copyWith(id: id));
      await _savePosts(posts);
      return id;
    } catch (e) {
      throw Exception('Failed to insert post: $e');
    }
  }

  // READ ALL
  Future<List<Post>> getAllPosts() async {
    try {
      return await _loadPosts();
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  // READ ONE
  Future<Post?> getPostById(int id) async {
    try {
      final posts = await _loadPosts();
      return posts.where((p) => p.id == id).firstOrNull;
    } catch (e) {
      throw Exception('Failed to fetch post: $e');
    }
  }

  // UPDATE
  Future<int> updatePost(Post post) async {
    try {
      if (post.id == null) throw Exception('Post ID is null');
      final posts = await _loadPosts();
      final index = posts.indexWhere((p) => p.id == post.id);
      if (index == -1) return 0;
      posts[index] = post;
      await _savePosts(posts);
      return 1;
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  // DELETE
  Future<int> deletePost(int id) async {
    try {
      final posts = await _loadPosts();
      final before = posts.length;
      posts.removeWhere((p) => p.id == id);
      await _savePosts(posts);
      return before - posts.length;
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  Future<void> closeDatabase() async {}
}
