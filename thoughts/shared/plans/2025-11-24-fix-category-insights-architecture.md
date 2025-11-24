# Fix Category Insights Architecture - Remove Direct Repository Access

## Overview

Refactor the category insights feature to follow proper clean architecture by introducing a controller layer between the UI and repository. Currently, the `CategoryInsightDetailScreen` directly accesses the repository for write operations, which violates the established architectural patterns used throughout the Kairos codebase.

## Current State Analysis

### Architectural Violation

The category insights feature has an architectural inconsistency where the presentation layer directly calls repository methods:

**Current Flow:**
```
CategoryInsightDetailScreen (line 26-30)
    ↓ [Direct access - bypasses controller]
ref.read(categoryInsightRepositoryProvider)
    ↓
repository.generateInsight()
    ↓
CategoryInsightRemoteDataSourceImpl
    ↓
Firebase Cloud Function
```

**Location:** [category_insight_detail_screen.dart:26-30](lib/features/category_insights/presentation/screens/category_insight_detail_screen.dart#L26-L30)

```dart
final repository = ref.read(categoryInsightRepositoryProvider);
await repository.generateInsight(
  widget.category.value,
  forceRefresh: forceRefresh,
);
```

### Why This Is Wrong

1. **Violates layered architecture** - Screen should interact with controllers, not repositories directly
2. **Inconsistent with codebase patterns** - All other features (auth, journal, profile, settings) use StateNotifier controllers
3. **Manual state management** - Screen manages its own `_isRefreshing` flag instead of using proper state classes
4. **Missing use case layer** - No business logic encapsulation
5. **Poor error handling** - Generic try-catch with raw error messages instead of domain failure mapping

### Existing Proper Architecture (Used in Other Features)

```
Screen
    ↓ [ref.watch / ref.listen / ref.read().notifier]
StateNotifierProvider<Controller, State>
    ↓ [Controller method called]
Controller (StateNotifier)
    ↓ [Calls use case]
UseCase
    ↓ [Business logic, calls repository]
Repository
    ↓ [Delegates to data source]
DataSource
    ↓ [Performs I/O]
External Service
```

Examples:
- Message creation: [message_controller.dart:26-258](lib/features/journal/presentation/controllers/message_controller.dart#L26-L258)
- Auth operations: [auth_controller.dart:14-108](lib/features/auth/presentation/providers/auth_controller.dart#L14-L108)
- Profile creation: [profile_controller.dart:30-183](lib/features/profile/presentation/controllers/profile_controller.dart#L30-L183)

## Desired End State

After this refactor:

```
CategoryInsightDetailScreen
    ↓ [ref.watch for state, ref.read().notifier for actions]
categoryInsightControllerProvider (StateNotifierProvider)
    ↓
CategoryInsightController (StateNotifier)
    ↓
GenerateCategoryInsightUseCase
    ↓
CategoryInsightRepository
    ↓
CategoryInsightRemoteDataSource
    ↓
Firebase Cloud Function
```

### Key Features

1. **Sealed state classes** for type-safe state management (Initial, Generating, Success, Error)
2. **StateNotifier controller** managing generation operations
3. **Use case layer** encapsulating business logic
4. **Screen listens to state** via `ref.listen` for side effects (snackbars)
5. **Proper error mapping** from domain failures to user messages
6. **Consistent with codebase** patterns and conventions

### Verification

To verify the fix is complete:

1. Screen no longer has `ref.read(categoryInsightRepositoryProvider)` call
2. Screen no longer manages local `_isRefreshing` state
3. Controller exists in `lib/features/category_insights/presentation/controllers/`
4. Use case exists in `lib/features/category_insights/domain/usecases/`
5. Screen uses `ref.watch(categoryInsightControllerProvider)` for state
6. Screen uses `ref.read(categoryInsightControllerProvider.notifier).generateInsight()` for actions
7. All existing functionality works (generate, refresh, cooldown)

## What We're NOT Doing

1. **Not modifying the read operations** - StreamProviders for watching insights are correctly implemented
2. **Not changing the data layer** - Repository and data source implementations remain the same
3. **Not modifying the category insights list screen** - Only affects the detail screen
4. **Not adding new features** - Pure architectural refactor, no functionality changes
5. **Not migrating to AsyncNotifier** - Using StateNotifier to maintain consistency with existing codebase patterns

## Implementation Approach

We'll follow the established patterns from the journal and profile features:

1. **Create sealed state classes** following the pattern in [message_controller.dart:19-26](lib/features/journal/presentation/controllers/message_controller.dart#L19-L26)
2. **Create use case** following the pattern in [create_text_message_usecase.dart](lib/features/journal/domain/usecases/create_text_message_usecase.dart)
3. **Create controller** following the pattern in [message_controller.dart:28-258](lib/features/journal/presentation/controllers/message_controller.dart#L28-L258)
4. **Update providers file** to include controller provider
5. **Update screen** to use controller instead of direct repository access

## Phase 1: Create Use Case Layer

### Overview
Add the missing use case layer to encapsulate business logic for generating category insights.

### Changes Required

#### 1. Create Use Case Interface
**File**: `lib/features/category_insights/domain/usecases/generate_category_insight_usecase.dart`
**Changes**: Create new file

```dart
import 'package:kairos/core/error/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/category_insights/domain/repositories/category_insight_repository.dart';

/// Use case for generating category insights
class GenerateCategoryInsightUseCase {
  GenerateCategoryInsightUseCase({required this.repository});

  final CategoryInsightRepository repository;

  /// Execute the use case
  ///
  /// [category] - The category value to generate insights for
  /// [forceRefresh] - Whether to force regeneration even if recently generated
  Future<Result<void>> call(String category, {bool forceRefresh = true}) async {
    try {
      await repository.generateInsight(category, forceRefresh: forceRefresh);
      return const Result.success(null);
    } catch (e) {
      // Map exceptions to domain failures
      if (e.toString().contains('network')) {
        return Result.error(NetworkFailure(message: 'Network error occurred'));
      } else if (e.toString().contains('permission')) {
        return Result.error(ServerFailure(message: 'Permission denied'));
      } else {
        return Result.error(
          ServerFailure(message: 'Failed to generate insight: ${e.toString()}'),
        );
      }
    }
  }
}
```

#### 2. Create Use Case Provider
**File**: `lib/features/category_insights/presentation/providers/category_insight_providers.dart`
**Changes**: Add use case provider after repository provider

```dart
// Add after line 22 (after categoryInsightRepositoryProvider)

// Use case provider
final generateCategoryInsightUseCaseProvider = Provider<GenerateCategoryInsightUseCase>((ref) {
  final repository = ref.watch(categoryInsightRepositoryProvider);
  return GenerateCategoryInsightUseCase(repository: repository);
});
```

### Success Criteria

#### Automated Verification:
- [x] Use case file exists: `lib/features/category_insights/domain/usecases/generate_category_insight_usecase.dart`
- [x] Code compiles without errors: `flutter analyze`
- [x] No linting errors: `flutter analyze`

#### Manual Verification:
- [x] Use case follows Result type pattern used in codebase
- [x] Use case provider properly wired in providers file
- [x] Use case can be imported and resolved by Riverpod

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that the structure looks correct before proceeding to the next phase.

---

## Phase 2: Create Controller Layer

### Overview
Create the StateNotifier controller that will manage the state for insight generation operations.

### Changes Required

#### 1. Create State Classes
**File**: `lib/features/category_insights/presentation/controllers/category_insight_controller.dart`
**Changes**: Create new file with sealed state hierarchy

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/error/failures.dart';
import 'package:kairos/features/category_insights/domain/usecases/generate_category_insight_usecase.dart';
import 'package:kairos/features/category_insights/presentation/providers/category_insight_providers.dart';

/// State for category insight generation operations
sealed class CategoryInsightState {
  const CategoryInsightState();
}

/// Initial state - no operation in progress
class CategoryInsightInitial extends CategoryInsightState {
  const CategoryInsightInitial();
}

/// Generating insights
class CategoryInsightGenerating extends CategoryInsightState {
  const CategoryInsightGenerating();
}

/// Insight generation succeeded
class CategoryInsightGenerateSuccess extends CategoryInsightState {
  const CategoryInsightGenerateSuccess();
}

/// Insight generation failed
class CategoryInsightGenerateError extends CategoryInsightState {
  const CategoryInsightGenerateError(this.message);
  final String message;
}

/// Controller for category insight operations
class CategoryInsightController extends StateNotifier<CategoryInsightState> {
  CategoryInsightController({
    required this.generateInsightUseCase,
  }) : super(const CategoryInsightInitial());

  final GenerateCategoryInsightUseCase generateInsightUseCase;

  /// Generate or refresh category insight
  Future<void> generateInsight(String category, {bool forceRefresh = true}) async {
    state = const CategoryInsightGenerating();

    final result = await generateInsightUseCase(category, forceRefresh: forceRefresh);

    result.when<void>(
      success: (_) {
        state = const CategoryInsightGenerateSuccess();
      },
      error: (Failure failure) {
        state = CategoryInsightGenerateError(_getErrorMessage(failure));
      },
    );
  }

  /// Reset controller to initial state
  void reset() {
    state = const CategoryInsightInitial();
  }

  /// Map failure to user-friendly error message
  String _getErrorMessage(Failure failure) {
    return switch (failure) {
      ValidationFailure(:final message) => message,
      NetworkFailure(:final message) => 'Network error. Please check your connection.',
      ServerFailure(:final message) => message,
      CacheFailure(:final message) => message,
      _ => 'An unexpected error occurred: ${failure.message}',
    };
  }
}

/// Provider for category insight controller
final categoryInsightControllerProvider =
    StateNotifierProvider<CategoryInsightController, CategoryInsightState>((ref) {
  final generateInsightUseCase = ref.watch(generateCategoryInsightUseCaseProvider);
  return CategoryInsightController(generateInsightUseCase: generateInsightUseCase);
});
```

### Success Criteria

#### Automated Verification:
- [x] Controller file exists: `lib/features/category_insights/presentation/controllers/category_insight_controller.dart`
- [x] Code compiles without errors: `flutter analyze`
- [x] No linting errors: `flutter analyze`
- [x] Controller properly exported from providers file

#### Manual Verification:
- [x] Sealed state classes follow pattern from message_controller.dart
- [x] Controller extends StateNotifier
- [x] Uses Result type pattern for error handling
- [x] Has reset() method for state cleanup
- [x] Provider properly wired with dependencies

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to update the screen.

---

## Phase 3: Update Screen to Use Controller

### Overview
Refactor the `CategoryInsightDetailScreen` to use the controller instead of directly accessing the repository.

### Changes Required

#### 1. Remove Direct Repository Access
**File**: `lib/features/category_insights/presentation/screens/category_insight_detail_screen.dart`
**Changes**: Remove lines 19-48 (entire `_CategoryInsightDetailScreenState` state management)

Remove:
```dart
class _CategoryInsightDetailScreenState extends ConsumerState<CategoryInsightDetailScreen> {
  bool _isRefreshing = false;

  Future<void> _generateOrRefreshInsight({bool forceRefresh = true}) async {
    setState(() => _isRefreshing = true);

    try {
      final repository = ref.read(categoryInsightRepositoryProvider);
      await repository.generateInsight(
        widget.category.value,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insight generated successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate insight: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }
```

#### 2. Add Controller Import
**File**: `lib/features/category_insights/presentation/screens/category_insight_detail_screen.dart`
**Changes**: Add import after line 5

```dart
import 'package:kairos/features/category_insights/presentation/controllers/category_insight_controller.dart';
```

#### 3. Refactor State Class
**File**: `lib/features/category_insights/presentation/screens/category_insight_detail_screen.dart`
**Changes**: Replace the entire `_CategoryInsightDetailScreenState` class

Replace lines 19-388 with:

```dart
class _CategoryInsightDetailScreenState extends ConsumerState<CategoryInsightDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insightAsync = ref.watch(categoryInsightProvider(widget.category));
    final controllerState = ref.watch(categoryInsightControllerProvider);

    // Listen for controller state changes for side effects
    ref.listen<CategoryInsightState>(categoryInsightControllerProvider, (previous, next) {
      if (next is CategoryInsightGenerateSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Insight generated successfully')),
          );
        }
        // Reset controller state
        ref.read(categoryInsightControllerProvider.notifier).reset();
      } else if (next is CategoryInsightGenerateError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to generate insight: ${next.message}'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
        // Reset controller state
        ref.read(categoryInsightControllerProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.displayName),
      ),
      body: insightAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (insight) {
          final isEmpty = insight == null || insight.isEmpty();
          final bool canRefresh;
          if (isEmpty) {
            canRefresh = true;
          } else {
            canRefresh = insight.canRefresh(const Duration(hours: 1));
          }

          // Check if currently generating
          final isGenerating = controllerState is CategoryInsightGenerating;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon and title
                Row(
                  children: [
                    Text(
                      widget.category.icon,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.displayName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isEmpty)
                            Text(
                              '${insight.memoryCount} memories',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Generate/Refresh button
                if (isEmpty)
                  // First time: Show "Generate Insights" button
                  Column(
                    children: [
                      Text(
                        _getCategoryDescription(widget.category),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: isGenerating ? null : () => _handleGenerateInsight(),
                          icon: isGenerating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            isGenerating ? 'Generating...' : 'Generate Insights',
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  // After first generation: Show "Refresh" button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isGenerating || !canRefresh ? null : () => _handleGenerateInsight(),
                      icon: isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        isGenerating
                            ? 'Refreshing...'
                            : canRefresh
                                ? 'Refresh Insight'
                                : 'Available in ${_getTimeUntilRefresh(insight)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Summary
                  _buildSection(
                    theme,
                    'Summary',
                    Icons.insights,
                    Text(
                      insight.summary,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Key Patterns
                  if (insight.keyPatterns.isNotEmpty) ...[
                    _buildSection(
                      theme,
                      'Key Patterns',
                      Icons.pattern,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: insight.keyPatterns
                            .map(
                              (pattern) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• ',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Expanded(
                                      child: Text(
                                        pattern,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Strengths
                  if (insight.strengths.isNotEmpty) ...[
                    _buildSection(
                      theme,
                      'Strengths',
                      Icons.star,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: insight.strengths
                            .map(
                              (strength) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '✓ ',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        strength,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Opportunities
                  if (insight.opportunities.isNotEmpty) ...[
                    _buildSection(
                      theme,
                      'Opportunities for Growth',
                      Icons.trending_up,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: insight.opportunities
                            .map(
                              (opportunity) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '→ ',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Expanded(
                                      child: Text(
                                        opportunity,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],

                  // Last updated
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      'Last updated: ${_formatDate(insight.lastRefreshedAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Handle generate/refresh insight button press
  void _handleGenerateInsight() {
    ref.read(categoryInsightControllerProvider.notifier).generateInsight(
          widget.category.value,
          forceRefresh: true,
        );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    IconData icon,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        content,
      ],
    );
  }

  String _getCategoryDescription(InsightCategory category) {
    return switch (category) {
      InsightCategory.mindsetWellbeing =>
        'Kairos will generate insights here once you talk about your emotions, stress, or mental well-being.',
      InsightCategory.productivityFocus =>
        'Kairos will generate insights here once you talk about your work, focus, or productivity.',
      InsightCategory.relationshipsConnection =>
        'Kairos will generate insights here once you talk about your relationships and connections.',
      InsightCategory.careerGrowth =>
        'Kairos will generate insights here once you talk about your career, goals, or professional growth.',
      InsightCategory.healthLifestyle =>
        'Kairos will generate insights here once you talk about your health, habits, or lifestyle.',
      InsightCategory.purposeValues =>
        'Kairos will generate insights here once you talk about your values, purpose, or life vision.',
    };
  }

  String _getTimeUntilRefresh(CategoryInsightEntity insight) {
    final now = DateTime.now();
    final nextRefreshTime = insight.lastRefreshedAt.add(const Duration(hours: 1));
    final difference = nextRefreshTime.difference(now);

    if (difference.inMinutes < 1) {
      return 'less than a minute';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes';
    } else {
      return '1 hour';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
```

### Success Criteria

#### Automated Verification:
- [x] Code compiles without errors: `flutter analyze`
- [x] No linting errors: `flutter analyze`
- [ ] App builds successfully: `flutter build apk --debug`

#### Manual Verification:
- [x] Screen no longer has `ref.read(categoryInsightRepositoryProvider)` call
- [x] Screen no longer has local `_isRefreshing` state variable
- [ ] "Generate Insights" button works and shows loading state
- [ ] "Refresh Insight" button works and shows loading state
- [ ] Success snackbar appears after successful generation
- [ ] Error snackbar appears on failure with proper error message
- [ ] Cooldown timer still works correctly
- [ ] UI updates automatically after generation completes (via stream)
- [ ] No regressions in any other category insights functionality

**Implementation Note**: After completing this phase, thoroughly test all user flows (first generation, refresh, cooldown, errors) to ensure the refactor maintains all existing functionality.

---

## Testing Strategy

### Unit Tests

Create tests for the new layers:

1. **Use Case Tests** (`test/features/category_insights/domain/usecases/generate_category_insight_usecase_test.dart`):
   - Test successful insight generation
   - Test error handling and failure mapping
   - Test forceRefresh parameter

2. **Controller Tests** (`test/features/category_insights/presentation/controllers/category_insight_controller_test.dart`):
   - Test state transitions (Initial → Generating → Success)
   - Test state transitions (Initial → Generating → Error)
   - Test reset() method
   - Test error message mapping

### Integration Tests

Manual testing checklist:

1. **First-time Generation**:
   - Navigate to empty category
   - Tap "Generate Insights"
   - Verify loading indicator appears
   - Verify success snackbar appears
   - Verify insights are displayed

2. **Refresh Flow**:
   - Navigate to category with existing insights
   - Tap "Refresh Insight"
   - Verify loading indicator appears
   - Verify success snackbar appears
   - Verify insights are updated

3. **Cooldown Period**:
   - Generate insights
   - Immediately try to refresh
   - Verify button is disabled with countdown text

4. **Error Handling**:
   - Disable network
   - Try to generate insights
   - Verify error snackbar with proper message
   - Re-enable network and verify can retry

5. **Navigation**:
   - Generate insights and navigate away during loading
   - Navigate back and verify state is correct

### Manual Testing Steps

1. Open the app and navigate to Insights screen
2. Tap on each category and verify "Generate Insights" button appears
3. Tap "Generate Insights" for a category with no insights
4. Verify loading indicator appears on button
5. Wait for generation to complete
6. Verify success snackbar appears
7. Verify insights are displayed correctly
8. Tap "Refresh Insight" button
9. Verify it's disabled with countdown text if within cooldown period
10. Wait for cooldown to expire and tap "Refresh Insight"
11. Verify loading indicator appears
12. Verify insights update after generation
13. Test with airplane mode on to verify error handling

## Performance Considerations

- **No performance impact expected** - This is purely an architectural refactor
- State management moves from local setState to Riverpod StateNotifier, which has minimal overhead
- UI updates still driven by StreamProvider watching Firestore, no change
- Controller layer adds negligible overhead (single object in memory)

## Migration Notes

This is a pure code refactor with no data migration needed:

- **Database schema**: Unchanged
- **API contracts**: Unchanged
- **User data**: Unchanged
- **Backward compatibility**: Not applicable (single app version)

## References

- Current implementation: [category_insight_detail_screen.dart:22-48](lib/features/category_insights/presentation/screens/category_insight_detail_screen.dart#L22-L48)
- Pattern examples:
  - Message controller: [message_controller.dart:26-258](lib/features/journal/presentation/controllers/message_controller.dart#L26-L258)
  - Auth controller: [auth_controller.dart:14-108](lib/features/auth/presentation/providers/auth_controller.dart#L14-L108)
  - Profile controller: [profile_controller.dart:30-183](lib/features/profile/presentation/controllers/profile_controller.dart#L30-L183)
