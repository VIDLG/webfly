import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Combined URL input section with expandable advanced path options
class LauncherUrlInputSection extends HookWidget {
  const LauncherUrlInputSection({
    super.key,
    required this.urlController,
    required this.pathController,
    required this.errorMessage,
    required this.isHighlighted,
    required this.onClear,
    required this.onSubmitted,
    required this.onScan,
  });

  final TextEditingController urlController;
  final TextEditingController pathController;
  final String? errorMessage;
  final bool isHighlighted;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showAdvanced = useState(false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main URL input
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: urlController,
          builder: (context, value, child) {
            final hasText = value.text.isNotEmpty;

            return TextField(
              controller: urlController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Bundle URL',
                hintText: 'http://192.168.1.100:8080/dist/bundle.js',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isHighlighted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: isHighlighted ? 2.0 : 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isHighlighted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: isHighlighted ? 2.0 : 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2.0,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                errorText: errorMessage,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasText)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: onClear,
                        tooltip: 'Clear',
                      ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: onScan,
                      tooltip: 'Scan QR Code',
                    ),
                  ],
                ),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: onSubmitted,
            );
          },
        ),

        // Advanced toggle button
        const SizedBox(height: 4),
        InkWell(
          onTap: () => showAdvanced.value = !showAdvanced.value,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showAdvanced.value
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Advanced',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable path input
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: showAdvanced.value
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: pathController,
              builder: (context, value, child) {
                final hasText = value.text.isNotEmpty && value.text != '/';

                return TextField(
                  controller: pathController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'App Path (Route)',
                    hintText: '/led or /led?css=0',
                    helperText: 'WebF inner route (supports ?query and #hash)',
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: hasText
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => pathController.text = '/',
                            tooltip: 'Reset to /',
                          )
                        : null,
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.go,
                  onSubmitted: onSubmitted,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
