import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../models/category.dart';
import '../../models/task.dart';
import '../../models/recurring_transaction.dart';
import '../../providers/expense_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/recurring_provider.dart';

import '../../utils/constants_shared.dart';
import '../../utils/helpers.dart';
import '../../utils/notification_helper.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown_field.dart';
import '../../widgets/date_picker_trigger.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  String? _receiptImagePath;
  String? _linkedTaskId;

  // Recurring options
  bool _isRecurring = false;
  String _recurringFrequency = 'monthly';

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // Expenses cannot be logged in the future
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final XFile? file = await _imagePicker.pickImage(source: source);
      if (file != null) {
        setState(() {
          _receiptImagePath = file.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick receipt: $e')));
    }
  }

  void _showImagePickerSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLarge),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: Text(
                  'Attach Receipt',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Capture with Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickReceipt(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickReceipt(ImageSource.gallery);
                },
              ),
              const SizedBox(height: AppConstants.spacingL),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    final expenseState = ref.read(expenseProvider);
    final category = expenseState.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
    );

    final String expenseId = const Uuid().v4();

    // 1. Create and Save Expense Object
    final expense = Expense(
      id: expenseId,
      amount: amount,
      categoryId: _selectedCategoryId!,
      categoryName: category.name,
      description: _descriptionController.text.trim(),
      notes: _notesController.text.trim(),
      date: _selectedDate,
      receiptImagePath: _receiptImagePath,
      linkedTaskId: _linkedTaskId,
      isRecurring: _isRecurring,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(expenseProvider.notifier).addExpense(expense);

    // 2. Task Linkage Integration
    if (_linkedTaskId != null) {
      await ref
          .read(taskProvider.notifier)
          .linkExpenseToTask(_linkedTaskId!, expenseId);
    }

    // 3. Setup Recurring transaction rule
    if (_isRecurring) {
      final recurringRule = RecurringTransaction(
        id: const Uuid().v4(),
        title: expense.description.isNotEmpty
            ? expense.description
            : expense.categoryName,
        amount: expense.amount,
        categoryId: expense.categoryId,
        type: RecurringType.expense,
        frequency: _recurringFrequency,
        startDate: expense.date,
        nextExecutionDate: expense.date.add(
          const Duration(days: 30),
        ), // initial advance
        isActive: true,
      );
      await ref.read(recurringProvider.notifier).addRecurring(recurringRule);
    }

    // 4. Budget Warning Check (Reactive Notification Alerts)
    final budgetState = ref.read(budgetProvider);
    final activeBudget = budgetState.currentBudget;
    if (activeBudget != null && activeBudget.monthlyTotalBudget > 0) {
      final monthlyLimit = activeBudget.monthlyTotalBudget;
      final monthlySpent = ref.read(monthlySpentProvider(expense.date));
      final spentPercentage = (monthlySpent / monthlyLimit) * 100;

      if (spentPercentage >= 100) {
        await NotificationHelper.triggerBudgetWarning(
          spentPercentage,
          monthlyLimit,
        );
      } else if (spentPercentage >= 80) {
        await NotificationHelper.triggerBudgetWarning(
          spentPercentage,
          monthlyLimit,
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense logged successfully'),
          backgroundColor: AppConstants.secondaryColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseState = ref.watch(expenseProvider);
    final tasks = ref.watch(taskProvider);

    final expenseCategories = expenseState.categories
        .where((c) => c.type == CategoryType.expense)
        .toList();
    final pendingTasks = tasks
        .where((t) => t.status == TaskStatus.pending)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
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
                          color: AppConstants.expenseColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: theme.textTheme.displayMedium?.copyWith(
                            color: AppConstants.expenseColor.withValues(alpha: 0.5),
                          ),
                          prefixText: '\$ ',
                          prefixStyle: theme.textTheme.displayMedium?.copyWith(
                            color: AppConstants.expenseColor,
                            fontWeight: FontWeight.bold,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
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

              // Description
              CustomTextField(
                label: 'Description',
                hint: 'e.g. Dinner with friends',
                controller: _descriptionController,
                prefixIcon: const Icon(Icons.description_outlined),
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
                items: expenseCategories.map((c) {
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
                onTap: _selectDate,
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Notes
              CustomTextField(
                label: 'Notes (Optional)',
                hint: 'Add extra details...',
                controller: _notesController,
                prefixIcon: const Icon(Icons.notes),
                maxLines: 3,
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Receipt Attachment Container
              Text(
                'Receipt',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
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
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_receiptImagePath != null) ...[
                      Container(
                        height: 160,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.receipt,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: SecondaryButton(
                        text: _receiptImagePath == null
                            ? 'Attach Receipt Image'
                            : 'Change Receipt Image',
                        icon: Icons.add_a_photo_outlined,
                        onPressed: _showImagePickerSheet,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Link to Todo Task
              if (pendingTasks.isNotEmpty) ...[
                CustomDropdownField<String?>(
                  label: 'Link to Task (Optional)',
                  hint: 'No Linked Task',
                  value: _linkedTaskId,
                  prefixIcon: const Icon(Icons.link),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No Linked Task'),
                    ),
                    ...pendingTasks.map(
                      (t) => DropdownMenuItem<String?>(
                        value: t.id,
                        child: Text(t.title, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _linkedTaskId = val;
                    });
                  },
                ),
                const SizedBox(height: AppConstants.spacingL),
              ],

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
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Recurring Expense',
                        style: theme.textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        'Log automatically',
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
                    if (_isRecurring) ...[
                      Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        child: CustomDropdownField<String>(
                          label: 'Frequency',
                          value: _recurringFrequency,
                          items: ['daily', 'weekly', 'monthly', 'yearly']
                              .map(
                                (freq) => DropdownMenuItem<String>(
                                  value: freq,
                                  child: Text(freq.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _recurringFrequency = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingXxl),

              // Save Button
              PrimaryButton(text: 'Save Expense', onPressed: _saveExpense),
              const SizedBox(height: AppConstants.spacingXl),
            ],
          ),
        ),
      ),
    );
  }
}
