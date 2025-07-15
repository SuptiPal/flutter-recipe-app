import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';
import '../services/auth_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _commentsKey = GlobalKey();
  final TextEditingController _commentController = TextEditingController();
  final String userId = AuthService().currentUserId;
  int _servings = 1;
  Map<String, TextEditingController> _replyControllers = {};
  String? _activeReplyCommentId;

  Future<void> _submitRating(double rating) async {
    final docRef = FirebaseFirestore.instance.collection('recipes').doc(widget.recipe.id);
    if (rating == 0) {
      await docRef.update({'ratings.$userId': FieldValue.delete()});
    } else {
      await docRef.update({'ratings.$userId': rating});
    }
    final updatedSnapshot = await docRef.get();
    final ratings = Map<String, dynamic>.from(updatedSnapshot.data()?['ratings'] ?? {});
    double total = 0;
    ratings.forEach((_, r) => total += (r as num).toDouble());
    final avg = ratings.isEmpty ? 0.0 : total / ratings.length;

    await docRef.update({'rating': avg});
    setState(() {
      widget.recipe.rating = avg;
      if (rating == 0) {
        widget.recipe.ratings.remove(userId);
      } else {
        widget.recipe.ratings[userId] = rating;
      }
    });
  }

  Future<void> _submitComment(String text) async {
    if (text.trim().isEmpty) return;
    final user = await AuthService().getCurrentUser();
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? "User";

    // Prevent other users from using "Admin" as display name
    if (displayName.toLowerCase() == 'admin' && user?.email != 'suptipal03@gmail.com') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Display name 'Admin' is reserved.")),
      );
      return;
    }

    final newComment = {
      'userId': userId,
      'userEmail': user?.email ?? '',
      'displayName': displayName,
      'text': text,
      'timestamp': Timestamp.now(),
      'likes': 0,
      'dislikes': 0,
      'likedBy': [],
      'dislikedBy': [],
      'replies': []
    };

    final recipeRef = FirebaseFirestore.instance.collection('recipes').doc(widget.recipe.id);
    await recipeRef.update({'comments': FieldValue.arrayUnion([newComment])});
    _commentController.clear();
    await _reloadComments();
  }

  Future<void> _submitReply(Map<String, dynamic> parentComment, String replyText) async {
    if (replyText.trim().isEmpty) return;
    final user = await AuthService().getCurrentUser();
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? "User";

    final reply = {
      'userId': userId,
      'userEmail': user?.email ?? '',
      'displayName': displayName,
      'text': replyText,
      'timestamp': Timestamp.now(),
      'likes': 0,
      'dislikes': 0,
      'likedBy': [],
      'dislikedBy': [],
    };

    final updatedComments = widget.recipe.comments.map((c) {
      if (c['timestamp'] == parentComment['timestamp'] && c['userId'] == parentComment['userId']) {
        final replies = List<Map<String, dynamic>>.from(c['replies'] ?? []);
        replies.add(reply);
        return {...c, 'replies': replies};
      }
      return c;
    }).toList();

    final recipeRef = FirebaseFirestore.instance.collection('recipes').doc(widget.recipe.id);
    await recipeRef.update({'comments': updatedComments});
    _activeReplyCommentId = null;
    await _reloadComments();
  }

  Future<void> _updateReplies(
      Map<String, dynamic> parentComment, List<Map<String, dynamic>> newReplies) async {
    final recipeRef = FirebaseFirestore.instance.collection('recipes').doc(widget.recipe.id);
    final updatedComments = widget.recipe.comments.map((c) {
      if (c['timestamp'] == parentComment['timestamp'] && c['userId'] == parentComment['userId']) {
        return {...c, 'replies': newReplies};
      }
      return c;
    }).toList();
    await recipeRef.update({'comments': updatedComments});
    await _reloadComments();
  }

  Future<void> _deleteComment(Map<String, dynamic> comment) async {
    final recipeRef = FirebaseFirestore.instance.collection('recipes').doc(widget.recipe.id);
    await recipeRef.update({'comments': FieldValue.arrayRemove([comment])});
    await _reloadComments();
  }

  int _totalCommentsWithReplies = 0;

  @override
  void initState() {
    super.initState();
    _calculateTotalCommentsWithReplies();
  }

  Future<void> _calculateTotalCommentsWithReplies() async {
    final snapshot = await FirebaseFirestore.instance.collection('recipes').doc(widget.recipe.id).get();
    final comments = List<Map<String, dynamic>>.from(snapshot.data()?['comments'] ?? []);
    int replyCount = 0;
    for (var comment in comments) {
      final replies = comment['replies'];
      if (replies != null && replies is List) {
        replyCount += replies.length;
      }
    }
    setState(() {
      _totalCommentsWithReplies = comments.length + replyCount;
    });
  }

  Future<void> _reloadComments() async {
    final updatedSnapshot = await FirebaseFirestore.instance.collection('recipes').doc(widget.recipe.id).get();
    final updatedComments = List<Map<String, dynamic>>.from(updatedSnapshot.data()?['comments'] ?? []);
    setState(() {
      widget.recipe.comments.clear();
      widget.recipe.comments.addAll(updatedComments);
    });
    await _calculateTotalCommentsWithReplies();
  }

  Widget _buildReplies(List<dynamic> replies, Map<String, dynamic> parentComment) {
    return Column(
      children: replies.map((reply) {
        final name = reply['displayName'] ?? 'User';
        final text = reply['text'] ?? '';
        final email = reply['userEmail'] ?? '';
        final likedBy = List<String>.from(reply['likedBy'] ?? []);
        final dislikedBy = List<String>.from(reply['dislikedBy'] ?? []);
        final isMyReply = reply['userId'] == userId;
        final timestamp = (reply['timestamp'] as Timestamp?)?.toDate();
        final formattedTime = timestamp != null
            ? '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
            '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}'
            : '';

        return Padding(
          padding: const EdgeInsets.only(left: 48, top: 6, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 14, child: Text(name[0].toUpperCase())),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (email == 'suptipal03@gmail.com') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Admin',
                                style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ]
                      ],
                    ),
                    Text(text),
                    Text(formattedTime, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.thumb_up,
                              size: 18,
                              color: likedBy.contains(userId) ? Colors.blue : null),
                          onPressed: () async {
                            if (likedBy.contains(userId)) {
                              likedBy.remove(userId);
                            } else {
                              likedBy.add(userId);
                              dislikedBy.remove(userId);
                            }
                            final updated = List<Map<String, dynamic>>.from(replies);
                            final i = updated.indexOf(reply);
                            updated[i] = {
                              ...reply,
                              'likes': likedBy.length,
                              'dislikes': dislikedBy.length,
                              'likedBy': likedBy,
                              'dislikedBy': dislikedBy
                            };
                            await _updateReplies(parentComment, updated);
                          },
                        ),
                        Text('${likedBy.length}'),
                        IconButton(
                          icon: Icon(Icons.thumb_down,
                              size: 18,
                              color: dislikedBy.contains(userId) ? Colors.red : null),
                          onPressed: () async {
                            if (dislikedBy.contains(userId)) {
                              dislikedBy.remove(userId);
                            } else {
                              dislikedBy.add(userId);
                              likedBy.remove(userId);
                            }
                            final updated = List<Map<String, dynamic>>.from(replies);
                            final i = updated.indexOf(reply);
                            updated[i] = {
                              ...reply,
                              'likes': likedBy.length,
                              'dislikes': dislikedBy.length,
                              'likedBy': likedBy,
                              'dislikedBy': dislikedBy
                            };
                            await _updateReplies(parentComment, updated);
                          },
                        ),
                        Text('${dislikedBy.length}'),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _activeReplyCommentId =
                              '${parentComment['userId']}_${parentComment['timestamp']}';
                            });
                          },
                          child: const Text("Reply"),
                        ),
                        if (isMyReply)
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            onPressed: () async {
                              final updated = List<Map<String, dynamic>>.from(replies)..remove(reply);
                              await _updateReplies(parentComment, updated);
                            },
                          ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComment(Map<String, dynamic> comment) {
    final name = comment['displayName'] ?? 'User';
    final email = comment['userEmail'] ?? '';
    final text = comment['text'] ?? '';
    final likes = comment['likes'] ?? 0;
    final dislikes = comment['dislikes'] ?? 0;
    final likedBy = List<String>.from(comment['likedBy'] ?? []);
    final dislikedBy = List<String>.from(comment['dislikedBy'] ?? []);
    final replies = List<Map<String, dynamic>>.from(comment['replies'] ?? []);
    final isMyComment = comment['userId'] == userId;
    final commentId = '${comment['userId']}_${comment['timestamp']}';
    final timestamp = (comment['timestamp'] as Timestamp?)?.toDate();
    final formattedTime = timestamp != null
        ? '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}'
        : '';

    _replyControllers.putIfAbsent(commentId, () => TextEditingController());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Text(name[0].toUpperCase())),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (email == 'suptipal03@gmail.com') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Admin',
                                style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ]
                      ],
                    ),
                    Text(text),
                    Text(formattedTime, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.thumb_up,
                              size: 18,
                              color: likedBy.contains(userId) ? Colors.blue : null),
                          onPressed: () async {
                            if (likedBy.contains(userId)) {
                              likedBy.remove(userId);
                            } else {
                              likedBy.add(userId);
                              dislikedBy.remove(userId);
                            }
                            final updated = widget.recipe.comments.map((c) {
                              if (c['timestamp'] == comment['timestamp'] &&
                                  c['userId'] == comment['userId']) {
                                return {
                                  ...comment,
                                  'likes': likedBy.length,
                                  'dislikes': dislikedBy.length,
                                  'likedBy': likedBy,
                                  'dislikedBy': dislikedBy
                                };
                              }
                              return c;
                            }).toList();
                            final recipeRef = FirebaseFirestore.instance
                                .collection('recipes')
                                .doc(widget.recipe.id);
                            await recipeRef.update({'comments': updated});
                            await _reloadComments();
                          },
                        ),
                        Text('$likes'),
                        IconButton(
                          icon: Icon(Icons.thumb_down,
                              size: 18,
                              color: dislikedBy.contains(userId) ? Colors.red : null),
                          onPressed: () async {
                            if (dislikedBy.contains(userId)) {
                              dislikedBy.remove(userId);
                            } else {
                              dislikedBy.add(userId);
                              likedBy.remove(userId);
                            }
                            final updated = widget.recipe.comments.map((c) {
                              if (c['timestamp'] == comment['timestamp'] &&
                                  c['userId'] == comment['userId']) {
                                return {
                                  ...comment,
                                  'likes': likedBy.length,
                                  'dislikes': dislikedBy.length,
                                  'likedBy': likedBy,
                                  'dislikedBy': dislikedBy
                                };
                              }
                              return c;
                            }).toList();
                            final recipeRef = FirebaseFirestore.instance
                                .collection('recipes')
                                .doc(widget.recipe.id);
                            await recipeRef.update({'comments': updated});
                            await _reloadComments();
                          },
                        ),
                        Text('$dislikes'),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _activeReplyCommentId =
                              (_activeReplyCommentId == commentId) ? null : commentId;
                            });
                          },
                          child: const Text("Reply"),
                        ),
                        if (isMyComment)
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            onPressed: () => _deleteComment(comment),
                          ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
          if (replies.isNotEmpty) _buildReplies(replies, comment),
          if (_activeReplyCommentId == commentId)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyControllers[commentId],
                      decoration: const InputDecoration(
                          hintText: 'Write a reply...', border: OutlineInputBorder()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      _submitReply(comment, _replyControllers[commentId]?.text ?? '');
                      _replyControllers[commentId]?.clear();
                    },
                  )
                ],
              ),
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

    return Scaffold(
      appBar: AppBar(title: Text(recipe.title)),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(recipe.imageUrl,
                    height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('${recipe.rating.toStringAsFixed(1)}/5'),
                const SizedBox(width: 10),
                RatingBar.builder(
                  initialRating: recipe.ratings[userId]?.toDouble() ?? 0.0,
                  minRating: 0,
                  allowHalfRating: true,
                  itemSize: 24,
                  itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: _submitRating,
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Scrollable.ensureVisible(
                      _commentsKey.currentContext!,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.comment, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('$_totalCommentsWithReplies',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ingredients',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                        onPressed: () =>
                            setState(() => _servings = _servings > 1 ? _servings - 1 : 1),
                        icon: const Icon(Icons.remove)),
                    Text('$_servings'),
                    IconButton(
                        onPressed: () => setState(() => _servings++),
                        icon: const Icon(Icons.add)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recipe.ingredients.map((ing) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ing.name),
                  Text('${(ing.amount * _servings).toStringAsFixed(1)} ${ing.unit}'),
                ],
              ),
            )),
            const SizedBox(height: 24),
            const Text('Instructions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...recipe.instructions.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${entry.key + 1}. ${entry.value}'),
            )),
            const SizedBox(height: 24),
            Text('Comments',
                key: _commentsKey,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...recipe.comments.whereType<Map<String, dynamic>>().map(_buildComment),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Leave a comment...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _submitComment(_commentController.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}