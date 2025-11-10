import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kairos/core/routing/app_routes.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/core/widgets/app_button.dart';
import 'package:kairos/core/widgets/app_error_view.dart';
import 'package:kairos/core/widgets/app_text.dart';
import 'package:kairos/core/widgets/app_text_field.dart';
import 'package:kairos/features/profile/presentation/controllers/profile_controller.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _genderController = TextEditingController();
  final _mainGoalController = TextEditingController();
  final _experienceLevelController = TextEditingController();
  final _interestsController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  File? _selectedAvatar;

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _genderController.dispose();
    _mainGoalController.dispose();
    _experienceLevelController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profileController = ref.read(profileControllerProvider.notifier);

    // Listen for successful profile creation
    ref.listen<ProfileState>(profileControllerProvider, (previous, next) {
      if (next is ProfileSuccess) {
        // Navigate to home after successful profile creation
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const AppText(
          'Create Profile',
          style: AppTextStyle.headlineSmall,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Section
                _buildAvatarSection(profileController),

                const SizedBox(height: AppSpacing.sectionSpacing),

                // Name Field (Required)
                AppTextField(
                  controller: _nameController,
                  label: 'Name *',
                  hint: 'Enter your display name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Date of Birth (Optional)
                _buildDateOfBirthField(),

                const SizedBox(height: AppSpacing.lg),

                // Country (Optional)
                AppTextField(
                  controller: _countryController,
                  label: 'Country',
                  hint: 'Enter your country',
                ),

                const SizedBox(height: AppSpacing.lg),

                // Gender (Optional)
                _buildGenderDropdown(),

                const SizedBox(height: AppSpacing.lg),

                // Main Goal (Optional)
                AppTextField(
                  controller: _mainGoalController,
                  label: 'Main Goal',
                  hint: 'e.g., reduce stress, improve focus',
                ),

                const SizedBox(height: AppSpacing.lg),

                // Experience Level (Optional)
                _buildExperienceLevelDropdown(),

                const SizedBox(height: AppSpacing.lg),

                // Interests (Optional)
                AppTextField(
                  controller: _interestsController,
                  label: 'Interests',
                  hint: 'e.g., gratitude, motivation, sleep (comma-separated)',
                  maxLines: 2,
                ),

                const SizedBox(height: AppSpacing.sectionSpacing),

                // Error Display
                if (profileState is ProfileError)
                  AppErrorView(
                    message: profileState.message,
                    onRetry: profileController.reset,
                  ),

                const SizedBox(height: AppSpacing.lg),

                // Submit Button
                AppButton(
                  text: 'Create Profile',
                  onPressed: profileState is ProfileLoading ? null : _onSubmit,
                  isLoading: profileState is ProfileLoading,
                  fullWidth: true,
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(ProfileController profileController) {
    return Column(
      children: [
        const AppText.bodyMedium('Profile Picture'),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _selectedAvatar != null ? FileImage(_selectedAvatar!) : null,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: _selectedAvatar == null
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () => _showAvatarPicker(profileController),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateOfBirthField() {
    return InkWell(
      onTap: _selectDateOfBirth,
      child: IgnorePointer(
        child: AppTextField(
          controller: TextEditingController(
            text: _selectedDateOfBirth != null
                ? '${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.year}'
                : '',
          ),
          label: 'Date of Birth',
          hint: 'Select your date of birth',
          suffixIcon: const Icon(Icons.calendar_today),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _genderController.text.isNotEmpty ? _genderController.text : null,
      decoration: const InputDecoration(
        labelText: 'Gender',
        hintText: 'Select your gender',
      ),
      items: const [
        DropdownMenuItem(value: 'male', child: Text('Male')),
        DropdownMenuItem(value: 'female', child: Text('Female')),
        DropdownMenuItem(value: 'non-binary', child: Text('Non-binary')),
        DropdownMenuItem(
          value: 'prefer-not-to-say',
          child: Text('Prefer not to say'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _genderController.text = value ?? '';
        });
      },
    );
  }

  Widget _buildExperienceLevelDropdown() {
    return DropdownButtonFormField<String>(
      initialValue:
          _experienceLevelController.text.isNotEmpty ? _experienceLevelController.text : null,
      decoration: const InputDecoration(
        labelText: 'Experience Level',
        hintText: 'Select your experience level',
      ),
      items: const [
        DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
        DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
        DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
      ],
      onChanged: (value) {
        setState(() {
          _experienceLevelController.text = value ?? '';
        });
      },
    );
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  void _showAvatarPicker(ProfileController controller) {
    showModalBottomSheet<Widget>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.of(context).pop();
                await controller.pickAvatarFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.of(context).pop();
                await controller.pickAvatarFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final profileController = ref.read(profileControllerProvider.notifier);

    // Parse interests from comma-separated string
    final interests = _interestsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    profileController.createProfile(
      name: _nameController.text.trim(),
      dateOfBirth: _selectedDateOfBirth,
      country: _countryController.text.trim().isNotEmpty ? _countryController.text : null,
      gender: _genderController.text.trim().isNotEmpty ? _genderController.text : null,
      mainGoal: _mainGoalController.text.trim().isNotEmpty ? _mainGoalController.text : null,
      experienceLevel: _experienceLevelController.text.trim().isNotEmpty
          ? _experienceLevelController.text
          : null,
      interests: interests.isNotEmpty ? interests : null,
    );
  }
}
