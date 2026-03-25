import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/post.dart';

class AddEditPostScreen extends StatefulWidget {
  final Post? post;

  const AddEditPostScreen({super.key, this.post});

  @override
  State<AddEditPostScreen> createState() => _AddEditPostScreenState();
}

class _AddEditPostScreenState extends State<AddEditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _authorController;
  bool _isSaving = false;

  bool get _isEditing => widget.post != null;
  static const _primaryColor = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _titleController  = TextEditingController(text: widget.post?.title  ?? '');
    _bodyController   = TextEditingController(text: widget.post?.body   ?? '');
    _authorController = TextEditingController(text: widget.post?.author ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      if (_isEditing) {
        await DatabaseHelper.instance.updatePost(widget.post!.copyWith(
          title:  _titleController.text.trim(),
          body:   _bodyController.text.trim(),
          author: _authorController.text.trim(),
        ));
      } else {
        await DatabaseHelper.instance.insertPost(Post(
          title:     _titleController.text.trim(),
          body:      _bodyController.text.trim(),
          author:    _authorController.text.trim(),
          createdAt: dateStr,
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(_isEditing ? 'Post updated!' : 'Post created!'),
            ]),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: _primaryColor,
            title: Text(
              _isEditing ? 'Edit Post' : 'New Post',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8E85FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Text(
                        _isEditing ? 'Edit Post' : 'New Post',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 26,
                          fontWeight: FontWeight.bold, letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Post Title'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Enter a catchy title...',
                        prefixIcon: Icon(Icons.title, color: _primaryColor),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Title cannot be empty';
                        if (v.trim().length < 3) return 'Title must be at least 3 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Author'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        hintText: 'Who wrote this?',
                        prefixIcon: Icon(Icons.person_outline, color: _primaryColor),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Author cannot be empty';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Content'),
                    const SizedBox(height: 8),
                    ValueListenableBuilder(
                      valueListenable: _bodyController,
                      builder: (context, value, _) {
                        return TextFormField(
                          controller: _bodyController,
                          decoration: InputDecoration(
                            hintText: 'Write your post content here...',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 120),
                              child: Icon(Icons.article_outlined, color: _primaryColor),
                            ),
                            alignLabelWithHint: true,
                            counterText: '${_bodyController.text.length} chars',
                          ),
                          maxLines: 10,
                          minLines: 6,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Content cannot be empty';
                            if (v.trim().length < 10) return 'Content must be at least 10 characters';
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(_isEditing ? Icons.save_outlined : Icons.add_circle_outline),
                        label: Text(_isEditing ? 'Update Post' : 'Create Post'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      color: Color(0xFF6C63FF),
      letterSpacing: 0.5,
    ),
  );
}
