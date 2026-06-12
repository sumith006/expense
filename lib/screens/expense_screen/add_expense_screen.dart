import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../models/expense.dart';
import '../../models/category.dart';
import '../../models/task.dart';
import '../../models/recurring_transaction.dart';
import '../../providers/expense_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/recurring_provider.dart';
import '../../services/image_service.dart';

import '../../utils/constants_shared.dart';
import '../../utils/helpers.dart';
import '../../utils/notification_helper.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown_field.dart';
import '../../widgets/date_picker_trigger.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';

import '../../providers/currency_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Expense? existingExpense;
  const AddExpenseScreen({super.key, this.existingExpense});

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

  bool _isPickingImage = false;

  bool get isEditing => widget.existingExpense != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final e = widget.existingExpense!;
      _amountController.text = e.amount.toStringAsFixed(2);
      _descriptionController.text = e.description;
      _notesController.text = e.notes;
      _selectedCategoryId = e.categoryId;
      _selectedDate = e.date;
      _receiptImagePath = e.receiptImagePath;
      _linkedTaskId = e.linkedTaskId;
      _isRecurring = e.isRecurring;
    }
  }

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

  Future<void> _handleReceiptAction() async {
    if (_receiptImagePath == null) {
      await _pickReceipt();
    } else {
      final action = await ImageService.showReceiptPreview(context, _receiptImagePath!);
      if (action == 'change') {
        await _pickReceipt();
      } else if (action == 'remove') {
        _removeReceipt();
      }
    }
  }

  Future<void> _pickReceipt() async {
    setState(() => _isPickingImage = true);
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    
    if (source != null) {
      final imagePath = source == ImageSource.camera
          ? await ImageService.pickFromCamera()
          : await ImageService.pickAndSaveReceipt();
          
      if (imagePath != null && mounted) {
        // If there was an old receipt (and not the same as existing one if editing), delete it
        if (_receiptImagePath != null && _receiptImagePath != widget.existingExpense?.receiptImagePath) {
          await ImageService.deleteReceipt(_receiptImagePath);
        }
        setState(() => _receiptImagePath = imagePath);
      }
    }
    
    setState(() => _isPickingImage = false);
  }

  void _removeReceipt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Receipt'),
        content: const Text('Are you sure you want to remove this receipt image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              if (_receiptImagePath != null && _receiptImagePath != widget.existingExpense?.receiptImagePath) {
                await ImageService.deleteReceipt(_receiptImagePath);
              }
              setState(() => _receiptImagePath = null);
              Navigator.pop(context);
            },
            child: const Text('REMOVE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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

    final String expenseId = isEditing ? widget.existingExpense!.id : const Uuid().v4();

    // If we removed or changed the original receipt image, delete the file if it's not being used elsewhere
    if (isEditing && widget.existingExpense!.receiptImagePath != null && widget.existingExpense!.receiptImagePath != _receiptImagePath) {
       // Only delete if it's definitely not the one we are currently keeping
       await ImageService.deleteReceipt(widget.existingExpense!.receiptImagePath);
    }

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
      recurringId: isEditing ? widget.existingExpense!.recurringId : null,
      createdAt: isEditing ? widget.existingExpense!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isEditing) {
      await ref.read(expenseProvider.notifier).updateExpense(expense);
    } else {
      await ref.read(expenseProvider.notifier).addExpense(expense);
    }

    // 2. Task Linkage Integration
    if (_linkedTaskId != null && (!isEditing || widget.existingExpense!.linkedTaskId != _linkedTaskId)) {
      await ref
          .read(taskProvider.notifier)
          .linkExpenseToTask(_linkedTaskId!, expenseId);
    }

    // 3. Setup Recurring transaction rule
    if (_isRecurring && !isEditing) {
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
        SnackBar(
          content: Text(isEditing ? 'Expense updated successfully' : 'Expense logged successfully'),
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
    final currencyCode = ref.watch(currencyProvider);
    final currencySymbol = getCurrencySymbol(currencyCode);

    final expenseCategories = expenseState.categories
        .where((c) => c.type == CategoryType.expense)
        .toList();
    final pendingTasks = tasks
        .where((t) => t.status == TaskStatus.pending)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppConstants.expenseColor),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Expense'),
                    content: const Text('Delete this expense permanently?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete', style: TextStyle(color: AppConstants.expenseColor)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  // Delete receipt image file if it exists
                  if (widget.existingExpense!.receiptImagePath != null) {
                    await ImageService.deleteReceipt(widget.existingExpense!.receiptImagePath);
                  }
                  await ref.read(expenseProvider.notifier).deleteExpense(widget.existingExpense!.id);
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
                          color: AppConstants.expenseColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: theme.textTheme.displayMedium?.copyWith(
                            color: AppConstants.expenseColor.withValues(alpha: 0.5),
                          ),
                          prefixText: '$currencySymbol ',
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
                      GestureDetector(
                        onTap: _handleReceiptAction,
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                             color: theme.colorScheme.surfaceContainerHighest,
                             borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                             image: DecorationImage(
                               image: FileImage(File(_receiptImagePath!)),
                               fit: BoxFit.cover,
                             ),
                          ),
                          child: Container(
                             decoration: BoxDecoration(
                               color: Colors.black.withValues(alpha: 0.3),
                               borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                             ),
                             child: const Center(
                               child: Icon(
                                 Icons.zoom_in_rounded,
                                 size: 32,
                                 color: Colors.white,
                               ),
                             ),
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
                        onPressed: _isPickingImage ? () {} : () => _pickReceipt(),
                      ),
                    ),
                    if (_receiptImagePath != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _removeReceipt,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Remove Receipt'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ),
                    ],
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
              PrimaryButton(text: isEditing ? 'Update Expense' : 'Save Expense', onPressed: _saveExpense),
              const SizedBox(height: AppConstants.spacingXl),
            ],
          ),
        ),
      ),
    );
  }
}
