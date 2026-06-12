import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/income.dart';
import '../../models/category.dart';
import '../../providers/expense_provider.dart';
import '../../utils/constants_shared.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown_field.dart';
import '../../widgets/date_picker_trigger.dart';
import '../../widgets/primary_button.dart';

import '../../providers/currency_provider.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  final Income? existingIncome;
  const AddIncomeScreen({super.key, this.existingIncome});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  bool _isRecurring = false;
  bool _isSaving = false;

  bool get isEditing => widget.existingIncome != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final e = widget.existingIncome!;
      _amountController.text = e.amount.toStringAsFixed(2);
      _sourceController.text = e.source;
      _notesController.text = e.notes;
      _selectedDate = e.date;
      _isRecurring = e.isRecurring;
      _selectedCategoryId = e.categoryId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final expenseState = ref.read(expenseProvider);
    final category = expenseState.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
    );

    final income = Income(
      id: isEditing ? widget.existingIncome!.id : const Uuid().v4(),
      amount: double.parse(_amountController.text.replaceAll(',', '')),
      categoryId: category.id,
      categoryName: category.name,
      source: _sourceController.text.trim(),
      notes: _notesController.text.trim(),
      date: _selectedDate,
      isRecurring: _isRecurring,
      recurringId: isEditing ? widget.existingIncome!.recurringId : null,
      createdAt: isEditing ? widget.existingIncome!.createdAt : DateTime.now(),
    );

    if (isEditing) {
      await ref.read(expenseProvider.notifier).updateIncome(income);
    } else {
      await ref.read(expenseProvider.notifier).addIncome(income);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Income updated!' : 'Income added!'),
          backgroundColor: AppConstants.secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseState = ref.watch(expenseProvider);
    final currencyCode = ref.watch(currencyProvider);
    final currencySymbol = getCurrencySymbol(currencyCode);

    final incomeCategories = expenseState.categories
        .where((c) => c.type == CategoryType.income)
        .toList();

    // Auto-select category on first load if editing
    if (isEditing &&
        _selectedCategoryId == null &&
        incomeCategories.isNotEmpty) {
      _selectedCategoryId = incomeCategories.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Income' : 'Add Income'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppConstants.expenseColor,
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Income'),
                    content: const Text(
                      'Are you sure you want to delete this income record?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: AppConstants.expenseColor),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(expenseProvider.notifier)
                      .deleteIncome(widget.existingIncome!.id);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount Input (Large visual)
              Center(
                child: Column(
                  children: [
                    Text(
                      'Amount',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 100,
                        maxWidth: 300,
                      ),
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: AppConstants.secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: theme.textTheme.displayMedium?.copyWith(
                            color: AppConstants.secondaryColor.withValues(alpha: 0.5),
                          ),
                          prefixText: '$currencySymbol ',
                          prefixStyle: theme.textTheme.displayMedium?.copyWith(
                            color: AppConstants.secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          if (double.tryParse(val) == null) {
                            return 'Invalid amount';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingXl),

              // Source
              CustomTextField(
                label: 'Income Source',
                hint: 'e.g. Salary, Freelance, Business',
                controller: _sourceController,
                prefixIcon: const Icon(Icons.work_outline),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Category Selector
              CustomDropdownField<String>(
                label: 'Category',
                hint: 'Select Category',
                value: _selectedCategoryId,
                prefixIcon: const Icon(Icons.category_outlined),
                items: incomeCategories.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(
                          IconHelper.getIcon(c.iconCodePoint),
                          color: Color(c.colorValue),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                  });
                },
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Date
              DatePickerTrigger(
                label: 'Date',
                text: DateFormat('MMM d, y').format(_selectedDate),
                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                onTap: _pickDate,
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Notes
              CustomTextField(
                label: 'Notes (Optional)',
                hint: 'Any additional details...',
                controller: _notesController,
                prefixIcon: const Icon(Icons.notes),
                maxLines: 3,
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Recurring Options Container
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        theme.colorScheme.outlineVariant ??
                        AppConstants.borderLight,
                  ),
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Recurring Income',
                    style: theme.textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    'Mark as monthly recurring',
                    style: theme.textTheme.bodySmall,
                  ),
                  value: _isRecurring,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    setState(() {
                      _isRecurring = val;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppConstants.spacingXxl),

              // Save Button
              PrimaryButton(
                text: isEditing ? 'Update Income' : 'Save Income',
                isLoading: _isSaving,
                onPressed: _save,
              ),
              const SizedBox(height: AppConstants.spacingXl),
            ],
          ),
        ),
      ),
    );
  }
}
