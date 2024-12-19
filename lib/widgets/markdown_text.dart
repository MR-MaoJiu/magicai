import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class MarkdownText extends StatelessWidget {
  final String data;
  final bool selectable;

  const MarkdownText({
    super.key,
    required this.data,
    this.selectable = false,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return selectable
        ? SelectableMarkdown(data: data)
        : MarkdownBody(
            data: data,
            selectable: false,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
                height: 1.5,
              ),
              code: TextStyle(
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                fontFamily: GoogleFonts.firaCode().fontFamily,
                fontSize: 13,
              ),
              codeblockDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              blockquote: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
              h1: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              h2: TextStyle(
                color: Theme.of(context).textTheme.titleMedium?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              h3: TextStyle(
                color: Theme.of(context).textTheme.titleSmall?.color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              listBullet: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
            ),
            builders: {
              'code': CodeBlockBuilder(),
            },
            onTapLink: (text, href, title) {
              if (href != null) {
                _launchUrl(href);
              }
            },
          );
  }
}

class SelectableMarkdown extends StatelessWidget {
  final String data;

  const SelectableMarkdown({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        children: [
          WidgetSpan(
            child: MarkdownBody(
              data: data,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14,
                  height: 1.5,
                ),
                code: TextStyle(
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  fontFamily: GoogleFonts.firaCode().fontFamily,
                  fontSize: 13,
                ),
                codeblockDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                blockquote: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              builders: {
                'code': CodeBlockBuilder(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag == 'code') {
      String language = '';
      if (element.attributes['class'] != null) {
        String lg = element.attributes['class'] as String;
        language = lg.substring(9);
      }
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF1E1E1E),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (language.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  language,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            SelectableText(
              element.textContent,
              style: TextStyle(
                fontFamily: GoogleFonts.firaCode().fontFamily,
                fontSize: 13,
                color: Colors.grey[300],
              ),
            ),
          ],
        ),
      );
    }
    return null;
  }
}
