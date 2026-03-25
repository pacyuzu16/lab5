import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/post.dart';
import 'add_edit_post_screen.dart';
import 'post_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Post> _posts = [];
  List<Post> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();
  bool _searchActive = false;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadPosts();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_posts)
          : _posts.where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.author.toLowerCase().contains(q) ||
              p.body.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _loadPosts() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final posts = await DatabaseHelper.instance.getAllPosts();
      setState(() {
        _posts = posts;
        _filtered = List.from(posts);
        _isLoading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _deletePost(int id) async {
    try {
      await DatabaseHelper.instance.deletePost(id);
      _loadPosts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Post deleted'),
            ]),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDelete(Post post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Delete Post'),
        ]),
        content: Text('Are you sure you want to delete\n"${post.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _deletePost(post.id!); },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _avatarColor(String author) {
    final colors = [
      const Color(0xFF6C63FF), const Color(0xFFFF6584),
      const Color(0xFF43C6AC), const Color(0xFFFF8E53),
      const Color(0xFF4FACFE), const Color(0xFFA18CD1),
    ];
    return colors[author.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          if (_searchActive) _buildSearchBar(),
          SliverToBoxAdapter(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, _pageRoute(const AddEditPostScreen()));
          _loadPosts();
        },
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Post', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  SliverAppBar _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 190,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF6C63FF),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF8E85FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 62, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // logo + app name row
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(Icons.article_rounded,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PostVault',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              )),
                          const SizedBox(height: 2),
                          Text(
                            '${_posts.length} post${_posts.length != 1 ? 's' : ''} saved locally',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_searchActive ? Icons.search_off : Icons.search,
              color: Colors.white),
          onPressed: () {
            setState(() {
              _searchActive = !_searchActive;
              if (!_searchActive) {
                _searchController.clear();
                _filtered = List.from(_posts);
              }
            });
          },
          tooltip: 'Search',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadPosts,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search posts, authors...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF6C63FF)),
              const SizedBox(height: 16),
              Text('Loading posts...', style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text('Oops! Something went wrong.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadPosts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filtered.isEmpty) {
      return SizedBox(
        height: 380,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.article_outlined,
                    size: 56, color: Color(0xFF6C63FF)),
              ),
              const SizedBox(height: 20),
              Text(
                _searchActive && _searchController.text.isNotEmpty
                    ? 'No results found'
                    : 'No posts yet',
                style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A)),
              ),
              const SizedBox(height: 8),
              Text(
                _searchActive && _searchController.text.isNotEmpty
                    ? 'Try a different search term'
                    : 'Tap the button below to create\nyour first post',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeController,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _filtered.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildPostCard(_filtered[index]),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    final color = _avatarColor(post.author);
    final initials = post.author.isNotEmpty
        ? post.author.trim().split(' ').map((w) => w[0].toUpperCase()).take(2).join()
        : '?';

    return Dismissible(
      key: Key('post_${post.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        _confirmDelete(post);
        return false;
      },
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(context, _pageRoute(PostDetailScreen(post: post)));
            _loadPosts();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  radius: 22,
                  child: Text(initials,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D2D3A)),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(post.body,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 13, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(post.author,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(post.createdAt,
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  children: [
                    _ActionBtn(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF6C63FF),
                      onTap: () async {
                        await Navigator.push(context, _pageRoute(AddEditPostScreen(post: post)));
                        _loadPosts();
                      },
                    ),
                    const SizedBox(height: 6),
                    _ActionBtn(
                      icon: Icons.delete_outline,
                      color: Colors.redAccent,
                      onTap: () => _confirmDelete(post),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PageRoute _pageRoute(Widget page) => MaterialPageRoute(builder: (_) => page);
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
