import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';

/// A quiet, centred message. Used for "nothing here yet" and for errors, so the
/// two never look like different apps.
class MessageState extends StatelessWidget {
  const MessageState({
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.tone,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: tone ?? palette.muted),
            const SizedBox(height: Insets.s16),
            Text(
              title,
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: Insets.s8),
              Text(body!, style: text.bodySmall, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: Insets.s24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.title, this.body, this.icon, super.key});

  final String title;
  final String? body;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => MessageState(
        icon: icon ?? Icons.inbox_outlined,
        title: title,
        body: body,
      );
}

/// Presents an [ApiException] the way its type deserves.
///
/// A network problem invites a retry; a permission problem does not, because
/// trying again will fail the same way.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (icon, tone, retryable) = switch (error) {
      NetworkException() => (Icons.wifi_off_outlined, palette.muted, true),
      ForbiddenException() => (Icons.lock_outline, palette.muted, false),
      NotFoundException() => (Icons.search_off_outlined, palette.muted, false),
      ValidationException() => (Icons.error_outline, palette.warning, false),
      BusinessRuleException() => (Icons.info_outline, palette.warning, false),
      RateLimitedException() => (Icons.timer_outlined, palette.warning, true),
      MethodOverrideException() => (Icons.bug_report_outlined, palette.danger, false),
      _ => (Icons.error_outline, palette.danger, true),
    };

    return MessageState(
      icon: icon,
      tone: tone,
      title: error is ApiException
          ? (error as ApiException).message
          : 'Something went wrong.',
      action: (retryable && onRetry != null)
          ? OutlinedButton(onPressed: onRetry, child: const Text('Try again'))
          : null,
    );
  }
}

/// Skeleton rows, so a list does not jump when it loads.
class LoadingList extends StatelessWidget {
  const LoadingList({this.rows = 6, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListView.separated(
      padding: const EdgeInsets.all(Insets.gutter),
      itemCount: rows,
      separatorBuilder: (_, _) => const SizedBox(height: Insets.s12),
      itemBuilder: (_, _) => Container(
        height: 64,
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: BorderRadius.circular(Radii.row),
        ),
      ),
    );
  }
}

/// A small heading above a group of rows.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
          left: Insets.s4,
          right: Insets.s4,
          top: Insets.s24,
          bottom: Insets.s8,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.palette.muted,
                      letterSpacing: 0.6,
                    ),
              ),
            ),
            ?trailing,
          ],
        ),
      );
}

/// A bordered group of rows — this design's stand-in for a card with a shadow.
class AppCard extends StatelessWidget {
  const AppCard({required this.children, this.padding, super.key});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    // A Material rather than a decorated box: rows inside a card are usually
    // tappable, and ink splashes paint on the nearest Material — a container
    // with its own background would hide them.
    return Material(
      color: palette.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.row),
        side: BorderSide(color: palette.hairline),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(children: children),
      ),
    );
  }
}
