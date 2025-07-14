import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _loading = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    _user = FirebaseAuth.instance.currentUser;
    await _user?.reload();
    _user = FirebaseAuth.instance.currentUser;
    _nameController.text = _user?.displayName ?? '';
    setState(() {});
  }

  Future<void> _updateDisplayName() async {
    if (_user == null) return;
    final newName = _nameController.text.trim();

    if (newName.toLowerCase() == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('"Admin" is a reserved name')),
      );
      return;
    }

    setState(() => _loading = true);

    await _user!.updateDisplayName(newName);
    await _user!.reload();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .update({'displayName': newName});

    setState(() {
      _user = FirebaseAuth.instance.currentUser;
      _loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Display name updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _updateDisplayName,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Update'),
            )
          ],
        ),
      ),
    );
  }
}
