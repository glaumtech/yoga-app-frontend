import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher.dart';

/// Matches only http:// and https:// URLs in plain text.
final RegExp descriptionUrlRegex = RegExp(
  r'https?:\/\/[^\s<>]+',
  caseSensitive: false,
);

final RegExp _trailingPunctuation = RegExp(r'[.,;:!?)\]\}>]+$');

class DescriptionUrlMatch {
  const DescriptionUrlMatch({required this.url, required this.display});

  final String url;
  final String display;
}

bool _startsWithHttp(String value) {
  final lower = value.toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

List<DescriptionUrlMatch> extractDescriptionUrls(String text) {
  if (text.trim().isEmpty) return const [];
  final seen = <String>{};
  final urls = <DescriptionUrlMatch>[];
  for (final match in descriptionUrlRegex.allMatches(text)) {
    final parsed = _splitUrlMatch(match.group(0) ?? '');
    if (parsed == null) continue;
    if (seen.add(parsed.url.toLowerCase())) {
      urls.add(parsed);
    }
  }
  return urls;
}

DescriptionUrlMatch? _splitUrlMatch(String raw) {
  final trailing = _trailingPunctuation.firstMatch(raw);
  final url = trailing == null ? raw : raw.substring(0, trailing.start);
  if (url.isEmpty || !_startsWithHttp(url)) return null;
  return DescriptionUrlMatch(url: url, display: url);
}

Uri? descriptionUrlToUri(String raw) {
  final value = raw.trim();
  if (value.isEmpty || !_startsWithHttp(value)) return null;
  return Uri.tryParse(value);
}

Future<void> openDescriptionUrl(String rawUrl) async {
  final uri = descriptionUrlToUri(rawUrl);
  if (uri == null) return;
  await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: kIsWeb ? '_blank' : null,
  );
}

/// Stops wheel/trackpad events from scrolling a parent once this view
/// can scroll. At the start or end of the content, scrolling stops.
class IsolatedScrollListener extends StatelessWidget {
  const IsolatedScrollListener({
    super.key,
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth != 0) return false;
        if (notification is OverscrollNotification) return true;
        if (notification is ScrollUpdateNotification &&
            notification.dragDetails != null) {
          return true;
        }
        return false;
      },
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is! PointerScrollEvent) return;
          if (!controller.hasClients) return;
          final position = controller.position;
          if (!position.hasContentDimensions || !position.hasPixels) return;
          if (position.maxScrollExtent <= position.minScrollExtent) return;

          GestureBinding.instance.pointerSignalResolver.register(
            pointerSignal,
            (resolvedEvent) {
              if (resolvedEvent is! PointerScrollEvent) return;
              if (!controller.hasClients) return;
              final pos = controller.position;
              final next = (pos.pixels + resolvedEvent.scrollDelta.dy).clamp(
                pos.minScrollExtent,
                pos.maxScrollExtent,
              );
              if (next != pos.pixels) {
                controller.jumpTo(next);
              }
            },
          );
        },
        child: child,
      ),
    );
  }
}

/// Clickable URL that uses a real HTML anchor on Flutter web.
class DescriptionUrlLink extends StatelessWidget {
  const DescriptionUrlLink({
    super.key,
    required this.url,
    required this.style,
  });

  final String url;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final uri = descriptionUrlToUri(url);
    if (uri == null) {
      return Text(url, style: style);
    }

    return Link(
      uri: uri,
      target: LinkTarget.blank,
      builder: (context, followLink) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (followLink != null) {
                followLink();
                return;
              }
              openDescriptionUrl(url);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                url,
                style: style,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Competition description with isolated inner scroll and tappable links.
class LinkifiedDescription extends StatefulWidget {
  const LinkifiedDescription({
    super.key,
    required this.text,
    this.maxHeight = 180,
    this.style,
    this.linkStyle,
  });

  final String text;
  final double maxHeight;
  final TextStyle? style;
  final TextStyle? linkStyle;

  @override
  State<LinkifiedDescription> createState() => _LinkifiedDescriptionState();
}

class _LinkifiedDescriptionState extends State<LinkifiedDescription> {
  final ScrollController _scrollController = ScrollController();
  bool _canScroll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCanScroll());
  }

  @override
  void didUpdateWidget(LinkifiedDescription oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.maxHeight != widget.maxHeight) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncCanScroll());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncCanScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final canScroll =
        _scrollController.position.maxScrollExtent >
        _scrollController.position.minScrollExtent;
    if (canScroll != _canScroll) {
      setState(() => _canScroll = canScroll);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        widget.style ??
        TextStyle(
          fontSize: 15,
          height: 1.65,
          color: Colors.grey.shade800,
        );
    final linkStyle =
        widget.linkStyle ??
        baseStyle.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        );

    return IsolatedScrollListener(
      controller: _scrollController,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: _canScroll,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildBody(baseStyle, linkStyle),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(TextStyle baseStyle, TextStyle linkStyle) {
    final lines = widget.text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines) _buildLine(line, baseStyle, linkStyle),
      ],
    );
  }

  Widget _buildLine(String line, TextStyle baseStyle, TextStyle linkStyle) {
    if (line.trim().isEmpty) {
      final fontSize = baseStyle.fontSize ?? 15;
      final height = baseStyle.height ?? 1.5;
      return SizedBox(height: fontSize * height * 0.45);
    }

    final trimmed = line.trim();
    final onlyUrl = _splitUrlMatch(trimmed);
    if (onlyUrl != null && onlyUrl.url == trimmed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.open_in_new,
                size: 16,
                color: linkStyle.color,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: DescriptionUrlLink(url: onlyUrl.url, style: linkStyle),
            ),
          ],
        ),
      );
    }

    final matches = descriptionUrlRegex.allMatches(line).toList();
    if (matches.isEmpty) {
      return Text(line, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: line.substring(start, match.start)));
      }
      final raw = match.group(0) ?? '';
      final parsed = _splitUrlMatch(raw);
      final url = parsed?.url ?? '';
      final suffix = raw.length > url.length ? raw.substring(url.length) : '';
      if (url.isEmpty) {
        spans.add(TextSpan(text: raw));
      } else {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: DescriptionUrlLink(url: url, style: linkStyle),
          ),
        );
        if (suffix.isNotEmpty) {
          spans.add(TextSpan(text: suffix));
        }
      }
      start = match.end;
    }
    if (start < line.length) {
      spans.add(TextSpan(text: line.substring(start)));
    }
    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}

class DescriptionUrlChips extends StatelessWidget {
  const DescriptionUrlChips({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final urls = extractDescriptionUrls(text);
    if (urls.isEmpty) return const SizedBox.shrink();
    final style = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
      fontSize: 13,
      height: 1.4,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          for (final item in urls)
            DescriptionUrlLink(url: item.url, style: style),
        ],
      ),
    );
  }
}
