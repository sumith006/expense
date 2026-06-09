# Critical App Errors Fix Plan

This plan addresses performance issues, UI warnings, navigation bugs, data loading failures, and platform-specific configurations.

## User Review Required

> [!IMPORTANT]
> The app will now explicitly use **`android:enableOnBackInvokedCallback="true"`** in the Android Manifest.
> A global **`CurrencyProvider`** will be enforced to ensure all screens reflect currency changes instantly.

## Proposed Changes

### Performance Optimization

- Add `const` to all static widgets across screens and widgets.
- Implement `ListView.builder` for dynamic lists (Transactions, Tasks).
- Reduce `setState` calls by utilizing Riverpod providers more effectively.

---

### UI & UX (ListTile & Material)

- Wrap all `ListTile` instances in `Material` widgets with correct `borderRadius` and `color`.
- Ensure ink splashes are visible by providing a transparent Material background when inside decorated cards.

---

### Navigation & Lifecycle

- Fix `AnimatedBottomNav` and AppBars to ensure the back button correctly pops the navigation stack.
- Update `AndroidManifest.xml` with `android:enableOnBackInvokedCallback="true"`.

---

### Data & Services

- **Reports Screen**: Ensure correct Hive box names (`expenses_box`, etc.) are used and data is loaded after box initialization.
- **Currency Provider**: Centralize currency state and persist it to `SharedPreferences`.
- **Notification Service**: Stabilize timezone initialization to prevent UTC fallbacks.
- **Secure Storage**: Add error handling for cipher migration issues.

## Verification Plan

### Manual Verification
1. **Performance**: Monitor logcat for "Skipped frames" during rapid scrolling.
2. **ListTile**: Verify ink splashes on the Dashboard and Profile settings.
3. **Navigation**: Navigate to Tasks/Records and tap the Android back button; it should return to the Dashboard.
4. **Reports**: Verify non-zero data in the Reports tab.
5. **Currency**: Change currency to EUR in Profile; verify Dashboard immediately shows "€".
6. **Date Picker**: Tap "Date of Birth" in Profile; verify calendar appears.
