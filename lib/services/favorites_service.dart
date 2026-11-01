import 'package:hive/hive.dart';
import '../models/post_model.dart';

class FavoritesService {
  static const String boxName = 'favoritesBox';

  Box<Post> get _box => Hive.box<Post>(boxName);

  /// Checks whether a post with the given [id] is marked as a favorite.
  bool isFavorite(int id) {
    return _box.containsKey(id);
  }

  /// Toggles favorite status for the given [post].
  /// If the post is already favorited, it is removed from the box.
  /// If not, a new copy of the post is created and saved to avoid the
  /// HiveObject single-box constraint.
  Future<void> toggleFavorite(Post post) async {
    if (isFavorite(post.id)) {
      await _box.delete(post.id);
    } else {
      // HiveObject can only belong to one box at a time.
      // Saving a copy prevents HiveError: The same instance cannot be stored in multiple boxes.
      final postCopy = Post(
        id: post.id,
        title: post.title,
        body: post.body,
        userId: post.userId,
      );
      await _box.put(post.id, postCopy);
    }
  }

  /// Returns all favorited posts synchronously from the open box.
  List<Post> getFavorites() {
    return _box.values.toList();
  }
}
