import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../core/models.dart';
import '../core/storage.dart';

class AddGreenhousePage extends StatefulWidget {
  const AddGreenhousePage({super.key});

  @override
  State<AddGreenhousePage> createState() => _AddGreenhousePageState();
}

class _AddGreenhousePageState extends State<AddGreenhousePage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final id = 'gh_${const Uuid().v4().substring(0, 8)}';
    final greenhouse = Greenhouse(id: id, name: name);

    // persist and return created greenhouse
    Storage.addGreenhouse(greenhouse).then((_) {
      Navigator.pop(context, greenhouse);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Add Greenhouse',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Greenhouse name',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: AppColors.cardGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}