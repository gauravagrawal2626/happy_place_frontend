import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../onboarding/model/question_model.dart';
import '../model/filter_model.dart';

/// Mini bottom sheet for a single question-based filter.
///
/// Shows the question's options as tappable chips. If the selected option
/// has inline sub-options, they appear below. Tapping an option calls
/// [onSelected] and auto-closes the sheet.
/// (A dedicated "Default" reset chip was removed; change selection via other options only.)
void showQuestionFilterSheet({
  required BuildContext context,
  required QuestionFilter filter,
  required String? currentSelection,
  required ValueChanged<String?> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _QuestionFilterSheetContent(
      filter: filter,
      currentSelection: currentSelection,
      onSelected: (value) {
        onSelected(value);
        Navigator.pop(ctx);
      },
    ),
  );
}

class _QuestionFilterSheetContent extends StatefulWidget {
  final QuestionFilter filter;
  final String? currentSelection;
  final ValueChanged<String?> onSelected;

  const _QuestionFilterSheetContent({
    required this.filter,
    required this.currentSelection,
    required this.onSelected,
  });

  @override
  State<_QuestionFilterSheetContent> createState() =>
      _QuestionFilterSheetContentState();
}

class _QuestionFilterSheetContentState
    extends State<_QuestionFilterSheetContent> {
  String? _selectedParent;
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.currentSelection;
    _selectedParent = widget.filter.parentIdForValue(widget.currentSelection);
    if (_selectedParent == null && _selectedValue != null) {
      for (final opt in widget.filter.options) {
        if (opt.id == _selectedValue) {
          _selectedParent = opt.isParent ? opt.id : null;
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = widget.filter;
    final hasInlineSubs = filter.uiConfig.showSubOptionsInline;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            filter.primaryText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          if (filter.text != null && filter.text != filter.primaryText) ...[
            const SizedBox(height: 4),
            Text(
              filter.text!,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textDark.withOpacity(0.6),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildOptions(filter.options, hasInlineSubs),
          if (hasInlineSubs && _selectedParent != null)
            _buildSubOptions(filter.options),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildOptions(List<QuestionOption> options, bool hasInlineSubs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isOptionSelected = _selectedValue == option.id ||
            (option.isParent && _selectedParent == option.id);

        return GestureDetector(
          onTap: () {
            if (hasInlineSubs && option.isParent && option.subOptions != null) {
              setState(() {
                _selectedParent =
                    _selectedParent == option.id ? null : option.id;
              });
            } else {
              widget.onSelected(option.id);
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isOptionSelected
                  ? AppColors.textDark
                  : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textDark.withOpacity(0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (option.imageUrl != null) ...[
                  Image.network(
                    option.imageUrl!,
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image, size: 20),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  option.text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isOptionSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: isOptionSelected
                        ? Colors.white
                        : AppColors.textDark,
                  ),
                ),
                if (option.isParent &&
                    hasInlineSubs &&
                    option.subOptions != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _selectedParent == option.id
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 16,
                    color: isOptionSelected
                        ? Colors.white
                        : AppColors.textDark,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubOptions(List<QuestionOption> parentOptions) {
    final parent = parentOptions
        .where((o) => o.id == _selectedParent && o.subOptions != null)
        .firstOrNull;
    if (parent == null || parent.subOptions == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.filter.uiConfig.expandedTitle ?? 'Choose specifically:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: parent.subOptions!.map((sub) {
              final isSubSelected = _selectedValue == sub.id;
              return GestureDetector(
                onTap: () {
                  widget.onSelected(sub.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSubSelected
                        ? AppColors.background
                        : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSubSelected
                          ? AppColors.background
                          : AppColors.textDark.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    sub.text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSubSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
