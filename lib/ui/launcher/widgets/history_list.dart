import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:signals_hooks/signals_hooks.dart';
import '../../../store/url_history.dart';
import 'history_card.dart';

class UrlHistoryList extends HookWidget {
  final void Function(String url, String path) onOpen;
  final void Function(String url, String path) onTap;
  final void Function(String url, String path) onLongPress;
  final void Function(bool isEditMode)? onEditModeChanged;

  /// When parent calls this, child exits edit mode (e.g. back key).
  final void Function(void Function() requestExit)? onRegisterExitEditMode;

  const UrlHistoryList({
    super.key,
    required this.onOpen,
    required this.onTap,
    required this.onLongPress,
    this.onEditModeChanged,
    this.onRegisterExitEditMode,
  });

  @override
  Widget build(BuildContext context) {
    final urls = urlHistorySignal.watch(context);
    final isEditMode = useSignal(false);
    final selectedEntries = useSignal<Set<UrlHistoryEntry>>(
      <UrlHistoryEntry>{},
    );
    final isDragging = useSignal(false);

    void exitEditMode() {
      if (isEditMode.value) {
        isEditMode.value = false;
        selectedEntries.value = <UrlHistoryEntry>{};
        onEditModeChanged?.call(false);
      }
    }

    useEffectOnce(() {
      onRegisterExitEditMode?.call(exitEditMode);
      return () => onRegisterExitEditMode?.call(() {});
    });

    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }

    Future<void> handleClear() async {
      final confirmed = await _showClearHistoryDialog(context);

      if (confirmed == true) {
        clearUrlHistory();
        isEditMode.value = false;
        selectedEntries.value = <UrlHistoryEntry>{};
      }
    }

    void handleDelete(UrlHistoryEntry entry) {
      removeUrlHistoryEntry(entry);
      selectedEntries.value = {...selectedEntries.value}..remove(entry);
    }

    Future<void> handleBatchDelete() async {
      if (selectedEntries.value.isEmpty) return;

      final confirmed = await _showBatchDeleteDialog(
        context,
        selectedEntries.value.length,
      );
      if (confirmed == true) {
        for (final entry in selectedEntries.value) {
          removeUrlHistoryEntry(entry);
        }
        selectedEntries.value = <UrlHistoryEntry>{};
      }
    }

    void handleReorder(int oldIndex, int newIndex) {
      reorderUrlHistoryEntries(oldIndex, newIndex);
    }

    void toggleSelection(UrlHistoryEntry entry) {
      final current = {...selectedEntries.value};
      if (current.contains(entry)) {
        current.remove(entry);
      } else {
        current.add(entry);
      }
      selectedEntries.value = current;
    }

    void toggleSelectAll() {
      if (selectedEntries.value.length == urls.length) {
        selectedEntries.value = <UrlHistoryEntry>{};
      } else {
        selectedEntries.value = urls.toSet();
      }
    }

    final theme = Theme.of(context);
    final hasSelection = selectedEntries.value.isNotEmpty;
    final isAllSelected = selectedEntries.value.length == urls.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        // Drag target for deletion
        if (isDragging.value)
          DragTarget<UrlHistoryEntry>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              handleDelete(details.data);
              isDragging.value = false;
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 60,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isHovering
                      ? theme.colorScheme.error.withValues(alpha: 0.2)
                      : theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHovering
                        ? theme.colorScheme.error
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: isHovering
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isHovering
                            ? 'Release to delete'
                            : 'Drag here to delete',
                        style: TextStyle(
                          color: isHovering
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: isHovering
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent URLs',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () {
                isEditMode.value = !isEditMode.value;
                if (!isEditMode.value) {
                  selectedEntries.value = <UrlHistoryEntry>{};
                }
                onEditModeChanged?.call(isEditMode.value);
              },
              icon: Icon(
                isEditMode.value ? Icons.check : Icons.edit_outlined,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: isEditMode.value ? 'Done' : 'Edit',
            ),
          ],
        ),
        if (isEditMode.value)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (hasSelection)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: TextButton.icon(
                      onPressed: handleBatchDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text('Delete (${selectedEntries.value.length})'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: TextButton.icon(
                    onPressed: toggleSelectAll,
                    icon: Icon(
                      isAllSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                    ),
                    label: Text(isAllSelected ? 'Deselect' : 'Select'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                if (!hasSelection)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: TextButton.icon(
                      onPressed: handleClear,
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: const Text('Clear All'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: TextButton.icon(
                      onPressed: () {
                        isEditMode.value = false;
                        selectedEntries.value = {};
                        onEditModeChanged?.call(false);
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (isEditMode.value)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: urls.length,
            onReorder: handleReorder,
            buildDefaultDragHandles: false,
            itemBuilder: (context, index) {
              final entry = urls[index];
              final isLast = index == urls.length - 1;
              final isSelected = selectedEntries.value.contains(entry);

              return Padding(
                key: ValueKey('${entry.url}_${entry.path}'),
                padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                child: HistoryCard(
                  entry: entry,
                  index: index,
                  isLatest: index == 0,
                  isEditMode: true,
                  isSelected: isSelected,
                  onOpen: () => onOpen(entry.url, entry.path),
                  onTap: () => onTap(entry.url, entry.path),
                  onLongPress: () => onLongPress(entry.url, entry.path),
                  onDelete: () => handleDelete(entry),
                  onToggleSelect: () => toggleSelection(entry),
                ),
              );
            },
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: urls.length,
            itemBuilder: (context, index) {
              final entry = urls[index];
              final isLast = index == urls.length - 1;

              return Dismissible(
                key: ValueKey('${entry.url}_${entry.path}_dismissible'),
                direction: DismissDirection.startToEnd,
                background: Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.onError,
                    size: 24,
                  ),
                ),
                confirmDismiss: (direction) async {
                  handleDelete(entry);
                  return true;
                },
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                  child: HistoryCard(
                    entry: entry,
                    index: index,
                    isLatest: index == 0,
                    isEditMode: false,
                    isSelected: false,
                    onOpen: () => onOpen(entry.url, entry.path),
                    onTap: () => onTap(entry.url, entry.path),
                    onLongPress: () => onLongPress(entry.url, entry.path),
                    onDelete: () => handleDelete(entry),
                    onToggleSelect: () {},
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

Future<bool?> _showClearHistoryDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear History'),
      content: const Text('Are you sure you want to clear all history?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Clear'),
        ),
      ],
    ),
  );
}

Future<bool?> _showBatchDeleteDialog(BuildContext context, int count) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Selected'),
      content: Text(
        'Are you sure you want to delete $count selected item${count > 1 ? 's' : ''}?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
