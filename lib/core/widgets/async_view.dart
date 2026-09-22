import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import 'states.dart';

/// One place that turns an [AsyncValue] into a screen.
///
/// Without it every screen invents its own three-way switch and they drift:
/// one shows a spinner where another shows skeletons, one swallows an error.
/// [ErrorView] already knows which failures deserve a retry button, so a
/// permission problem does not offer one and a network blip does.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    required this.value,
    required this.builder,
    this.onRetry,
    this.loading,
    this.skipLoadingOnRefresh = true,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final Widget? loading;

  /// A pull-to-refresh keeps the old list on screen rather than blanking it.
  final bool skipLoadingOnRefresh;

  @override
  Widget build(BuildContext context) => value.when(
        skipLoadingOnRefresh: skipLoadingOnRefresh,
        skipLoadingOnReload: skipLoadingOnRefresh,
        data: (data) => builder(context, data),
        loading: () => loading ?? const LoadingList(),
        error: (error, _) {
          // A cancelled request is not a failure anyone should read about: the
          // store or branch changed and the screen is already being rebuilt.
          if (error is CancelledException) {
            return const Center(child: CircularProgressIndicator());
          }
          return ErrorView(error: error, onRetry: onRetry);
        },
      );
}

/// Shows an [ApiException] as a snack bar, in the words the server chose.
///
/// Business-rule refusals ("Not enough stock for Napa 500mg (4 left)") are
/// already written for a person; rewording them in the app would only make them
/// vaguer.
void showApiError(BuildContext context, Object error) {
  if (error is CancelledException) return;
  final message = error is ApiException
      ? error.message
      : 'Something went wrong.';
  final scheme = Theme.of(context).colorScheme;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: scheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
}

void showNote(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
