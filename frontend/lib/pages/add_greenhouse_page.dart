import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import 'package:greenhouse_app/core/providers/greenhouse_provider.dart';

class AddGreenhousePage extends StatefulWidget {
  const AddGreenhousePage({super.key});

  @override
  State<AddGreenhousePage> createState() => _AddGreenhousePageState();
}

class _AddGreenhousePageState extends State<AddGreenhousePage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      await context.read<GreenhouseProvider>().addGreenhouse(name);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                onPressed: _isSaving ? null : _save,
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
