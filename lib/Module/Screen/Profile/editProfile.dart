import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:poolqapp/Widget/reuse.dart';
import 'package:poolqapp/utils/avatar_url.dart';

class EditProfile extends StatefulWidget {
  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  File? _image;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final authProvider = Provider.of<AuthProviders>(context, listen: false);
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
    });
    authProvider.uploadImage(imagePath: _image!.path, context: context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviders>(context, listen: true);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _buildAvatarStack(authProvider)),
            const SizedBox(height: 32),
            _buildNameField(authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack(AuthProviders authProvider) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: const Color(0x1A063a73), // primaryBlue 10% opacity
          backgroundImage: _image != null
              ? FileImage(_image!) as ImageProvider
              : resolveAvatarImage(
                  photoUrl: authProvider.image.toString(),
                  email: FirebaseAuth.instance.currentUser?.email ??
                      authProvider.email,
                  size: 208,
                ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(AuthProviders authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Name',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                enabled: false,
                style: const TextStyle(color: AppTheme.onSurface),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    PhosphorIcons.user,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  labelText: authProvider.username,
                  labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                  disabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppTheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue),
              tooltip: 'Edit name',
              onPressed: _showEditNameSheet,
            ),
          ],
        ),
      ],
    );
  }

  void _showEditNameSheet() {
    final authProvider = Provider.of<AuthProviders>(context, listen: false);
    final nameController = TextEditingController(text: authProvider.username);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Display Name',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Display name',
                  hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primaryBlue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: AppTheme.primaryButtonStyle,
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      circularCustom(context);
                      final nav = Navigator.of(context);
                      final user = FirebaseAuth.instance.currentUser;
                      await user?.updateDisplayName(nameController.text);
                      authProvider.username = nameController.text;
                      nav.pop();
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
