import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:aisec5/models/post_model.dart';
import 'package:aisec5/services/favorites_service.dart';

void main() {
  late Directory tempDir;
  late FavoritesService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PostAdapter());
    }
    await Hive.openBox<Post>('favoritesBox');
    service = FavoritesService();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Initially favorites box is empty and post is not favorite', () {
    expect(service.getFavorites(), isEmpty);
    expect(service.isFavorite(1), isFalse);
  });

  test('toggleFavorite adds post to favorites and isFavorite returns true', () async {
    final post = Post(id: 1, title: 'Title 1', body: 'Body 1', userId: 101);
    await service.toggleFavorite(post);

    expect(service.isFavorite(1), isTrue);
    final favs = service.getFavorites();
    expect(favs.length, 1);
    expect(favs.first.id, 1);
    expect(favs.first.title, 'Title 1');
  });

  test('toggleFavorite twice removes post from favorites', () async {
    final post = Post(id: 1, title: 'Title 1', body: 'Body 1', userId: 101);
    await service.toggleFavorite(post);
    expect(service.isFavorite(1), isTrue);

    await service.toggleFavorite(post);
    expect(service.isFavorite(1), isFalse);
    expect(service.getFavorites(), isEmpty);
  });

  test('HiveObject single-box rule: toggling post from another box creates a copy and does not throw', () async {
    final postsBox = await Hive.openBox<Post>('postsBox');
    final postInPostsBox = Post(id: 42, title: 'Test', body: 'Content', userId: 1);
    await postsBox.put(42, postInPostsBox);

    // postInPostsBox is registered in 'postsBox'.
    // Toggling it into 'favoritesBox' must create a separate copy and not throw HiveError.
    await service.toggleFavorite(postInPostsBox);

    expect(service.isFavorite(42), isTrue);
    expect(service.getFavorites().length, 1);
    expect(postsBox.containsKey(42), isTrue);
    // Verify that the post in postsBox and the post in favoritesBox are distinct instances
    final favPost = service.getFavorites().first;
    expect(identical(favPost, postInPostsBox), isFalse);
  });
}
