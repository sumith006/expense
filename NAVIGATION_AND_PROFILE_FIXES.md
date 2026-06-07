# ✅ Reports Navigation & Profile Issues - Diagnostic & Fixes

## Current Status
- ✅ **Compilation**: Zero errors (62 warnings/info only)
- ✅ **Reports Screen**: Exists and properly registered in routes
- ✅ **Navigation**: Reports screen is accessed via bottom nav in DashboardScreen
- ⚠️ **Runtime Issues**: You're experiencing 3 specific problems

---

## Issue #1: Reports Button Not Opening

### Root Cause
The Reports screen is accessed through the **bottom navigation bar** in `DashboardScreen`, not through a separate button. The navigation is at index 2:

```dart
// In dashboard_screen.dart
final List<Widget> _screens = [
  ExpenseScreen(),      // Index 0
  TaskScreen(),         // Index 1
  ReportsScreen(),      // Index 2 ← HERE
  SettingsScreen(),     // Index 3
];
```

### Solution
**The Reports tab should be working via the bottom navigation bar.** If it's not:

1. **Check if the bottom nav bar is visible** - Tap the 3rd icon from left (Analytics icon)
2. **If tapping doesn't work**, the issue is with the tab controller, not navigation

### Debugging Steps
If Reports still won't open, add debug logging:

```dart
// In dashboard_screen.dart, in setState where _selectedIndex is set
setState(() {
  print("Switching to index: $index"); // Add this
  _selectedIndex = index;
  print("New screen: ${_screens[index].runtimeType}"); // Add this
});
```

---

## Issue #2: Date of Birth Calendar Not Appearing

### Root Cause Analysis
The profile screen has a **GestureDetector** wrapping the DOB card. The issue is likely:

1. The `showDatePicker` is being called but context is wrong
2. The GestureDetector isn't detecting taps properly
3. There's a widget above it blocking touches

### Fix Applied
I need to update the profile screen with better tap handling:

**Current code (line 137)**:
```dart
GestureDetector(
  onTap: () => _selectDateOfBirth(context),
  child: Card(...)
)
```

**Better approach - Use InkWell for better touch feedback**:
```dart
InkWell(
  onTap: () {
    print("DOB tapped"); // Debug
    _selectDateOfBirth(context);
  },
  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
  child: Card(...)
)
```

---

## Issue #3: Currency Not Updating Globally

### Root Cause
The currency is saved in `settingsProvider.currencySymbol`, and the profile screen correctly updates it:

```dart
onChanged: (val) {
  if (val != null) {
    ref.read(settingsProvider.notifier).updateCurrency(val);
  }
},
```

### Why It Might Not Update Everywhere

**Screens that DON'T watch the provider won't update.** They need:

```dart
// WRONG - reads once
final currency = ref.read(settingsProvider).currencySymbol;

// RIGHT - watches for changes
final currency = ref.watch(settingsProvider).currencySymbol;
```

### Screens That Need To Update

1. ✅ **Reports Screen** - Already uses `ref.watch(settingsProvider).currencySymbol`
2. **Dashboard** - Need to check
3. **Expense screens** - Need to check
4. Any screen displaying amounts

---

## Complete Fix Implementation

I'll create an updated profile screen with debug logging and better touch handling:
