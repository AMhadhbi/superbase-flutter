import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../utils/constants.dart';
import 'login_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _usernameController = TextEditingController();
  final _websiteController = TextEditingController();

  String? _avatarUrl;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase.from('profiles').select().eq('id', userId).maybeSingle();
      if (data != null) {
        _usernameController.text = (data['username'] as String?) ?? '';
        _websiteController.text = (data['website'] as String?) ?? '';
        final path = data['avatar_url'] as String?;
        if (path != null && path.isNotEmpty) {
          _avatarUrl = await supabase.storage.from(avatarsBucket).createSignedUrl(path, 60 * 60);
        }
      }
    } on PostgrestException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('profiles').upsert({
        'id': userId,
        'username': _usernameController.text.trim(),
        'website': _websiteController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } on PostgrestException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final file = File(picked.path);
      final fileExt = picked.path.split('.').last;
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage.from(avatarsBucket).upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      await supabase.from('profiles').upsert({
        'id': userId,
        'avatar_url': fileName,
        'updated_at': DateTime.now().toIso8601String(),
      });

      final signedUrl = await supabase.storage.from(avatarsBucket).createSignedUrl(fileName, 60 * 60);
      if (mounted) setState(() => _avatarUrl = signedUrl);
    } on StorageException catch (error) {
      _showError(error.message);
    } on PostgrestException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          Center(
            child: GestureDetector(
              onTap: _isLoading ? null : _pickAndUploadAvatar,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null ? const Icon(Icons.camera_alt, size: 32) : null,
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _websiteController,
            decoration: const InputDecoration(labelText: 'Website'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _updateProfile,
            child: Text(_isLoading ? 'Saving...' : 'Update'),
          ),
        ],
      ),
    );
  }
}
