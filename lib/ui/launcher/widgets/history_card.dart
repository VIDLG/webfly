import 'package:flutter/material.dart';
import '../../../store/url_history.dart';

/// Individual history card widget
class HistoryCard extends StatelessWidget {
  final UrlHistoryEntry entry;
  final int index;
  final bool isLatest;
  final bool isEditMode;
  final bool isSelected;
  final VoidCallback onOpen;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onToggleSelect;

  const HistoryCard({
    super.key,
    required this.entry,
    required this.index,
    required this.isLatest,
    required this.isEditMode,
    required this.isSelected,
    required this.onOpen,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      color: isEditMode && isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : isSelected
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: isEditMode ? onToggleSelect : onTap,
        onLongPress: isEditMode ? null : onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (isEditMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleSelect(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isSelected
                          ? Icons.delete_outline
                          : (isLatest ? Icons.history : Icons.link),
                      color: isSelected
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      size: 16,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLatest && !isEditMode)
                      Text(
                        'Last visited',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      entry.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: isLatest && !isEditMode
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                    if (entry.path != '/')
                      Text(
                        entry.path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              if (isEditMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onDelete,
                      color: theme.colorScheme.error,
                      tooltip: 'Delete',
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.drag_handle,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                )
              else
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: onOpen,
                  color: theme.colorScheme.primary,
                  tooltip: 'Open',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
