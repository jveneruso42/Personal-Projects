# Frontend Standards & Best Practices

**Version:** 2.2
**Last Updated:** November 4, 2025
**Status:** Active

**Design Reference:** [New York Times Mobile App](https://www.nytimes.com/) - Use as template for mobile-first UX patterns when in doubt

---

## 🎯 Core Principles

All code must be reviewed against these standards before deployment:
1. **WCAG 2.2 AA Compliance** - Accessibility for all users
2. **Mobile-First Design** - Works great on phones, scales to tablets/desktop
3. **Modern Elegance** - Clean, contemporary UX with purposeful design
4. **Performance First** - Sub-3-second load times, smooth 60fps interactions
5. **Dart/Flutter Best Practices** - Idiomatic, maintainable, type-safe code
6. **Modern APIs Only** - Use Flutter 3.7+ APIs, zero deprecated methods

---

## 📋 Table of Contents

1. [WCAG 2.2 AA Accessibility](#wcag-22-aa-accessibility)
2. [Typography & Readability](#typography--readability)
3. [Color & Contrast](#color--contrast)
4. [Interactive Elements](#interactive-elements)
   - [Semantic Identifiers (key & semanticLabel)](#semantic-identifiers-key--semanticlabel)
   - [Buttons & Actions](#buttons--actions)
   - [TextFields & Forms](#textfields--forms)
   - [Dropdowns & Pickers](#dropdowns--pickers)
   - [Navigation & Menus](#navigation--menus)
5. [Layout & Spacing](#layout--spacing)
6. [Viewport & Container Management](#viewport--container-management)
7. [Forms & Input](#forms--input)
8. [Images & Media](#images--media)
9. [Animation & Motion](#animation--motion)
10. [Flutter Best Practices](#flutter-best-practices)
    - [Widget Composition & Lifecycle](#widget-composition--lifecycle)
    - [Modern Flutter 3.7+ API Usage](#modern-flutter-37-api-usage)
    - [Building Responsive Layouts](#building-responsive-layouts)
    - [State Management Architecture](#state-management-architecture)
    - [Navigation & Routing](#navigation--routing)
11. [Riverpod State Management](#riverpod-state-management)
12. [HTTP Configuration with Dio](#http-configuration-with-dio)
13. [API Integration & CRUD Operations](#-api-integration--crud-operations)
    - [Data Models & Serialization](#data-models--serialization)
    - [CRUD Best Practices](#crud-best-practices)
    - [Error Handling Patterns](#error-handling-patterns)
    - [API Integration Checklist](#api-integration-checklist)
14. [Dart Code Quality](#-dart-code-quality)
15. [Mobile-First Responsive Design](#mobile-first-responsive-design)
16. [Performance Optimization](#performance-optimization)

---

## 🎨 WCAG 2.2 AA Accessibility

### Color Contrast Requirements

**Minimum Contrast Ratios (AA Standard):**
- **Normal text:** 4.5:1 (14px and below)
- **Large text:** 3:1 (18px+ or 14px+ bold)
- **UI components:** 3:1 (graphical objects, focus indicators, disabled states)
- **Borders & separators:** Visible against background (minimum 3:1)

**Implementation:**
```dart
// ✅ GOOD: Sufficient contrast (4.5:1+)
Text(
  'Important message',
  style: TextStyle(
    color: const Color(0xFF333333),  // Very dark gray
    fontSize: 14,
    fontWeight: FontWeight.normal,
  ),
)

// ❌ BAD: Insufficient contrast
Text(
  'Important message',
  style: TextStyle(
    color: const Color(0xFF999999),  // Medium gray on light bg
    fontSize: 14,
  ),
)
```

**How to Test:**
- Use WebAIM Contrast Checker (https://webaim.org/resources/contrastchecker/)
- Use Flutter DevTools to inspect widget colors
- Test with phone camera (simulate color blindness)

### Focus Indicators

**Requirements:**
- Focus state visible on all interactive elements (minimum 2px, 2:1 contrast with adjacent colors)
- Keyboard navigation supported (Tab, Shift+Tab, Enter, Space, Arrow keys)
- Focus order logical (top to bottom, left to right)
- No focus indicator hidden or impossible to see

**Implementation:**
```dart
// ✅ GOOD: Clear focus indicator
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: isFocused ? Colors.blue : Colors.grey,
      width: isFocused ? 3 : 1,
    ),
    borderRadius: BorderRadius.circular(8),
  ),
  child: TextField(
    onFocus: () => setState(() => isFocused = true),
    onBlur: () => setState(() => isFocused = false),
  ),
)

// ❌ BAD: No focus indicator
TextField(
  // No visual feedback on focus
)
```

### Semantic Structure

**Requirements:**
- Logical heading hierarchy (h1 → h2 → h3, no skipping levels)
- List items wrapped in proper List widgets
- Links distinguishable from body text
- Tables have proper headers and scope
- Form fields labeled clearly

**Implementation:**
```dart
// ✅ GOOD: Proper semantic structure
Column(
  children: [
    Semantics(
      header: true,
      child: Text(
        'Settings',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    ),
    ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(items[index].title),
      ),
    ),
  ],
)

// ❌ BAD: No semantic structure
Column(
  children: [
    Text('Settings', style: TextStyle(fontSize: 20)),  // Not marked as header
    Column(  // Should be ListView for list semantics
      children: items.map((e) => Text(e.title)).toList(),
    ),
  ],
)
```

### Alt Text & Descriptions

**Requirements:**
- All images have descriptive alt text
- Decorative images marked as `Semantics(enabled: false)`
- Alt text concise (max 125 characters)
- Important information conveyed in text, not image alone

**Implementation:**
```dart
// ✅ GOOD: Descriptive alt text
Semantics(
  image: true,
  label: 'Golden Retriever dog looking sad with pink toy',
  child: Image.asset('assets/images/sad_dog_with_toy.jpg'),
)

// ✅ GOOD: Decorative image hidden
Semantics(
  enabled: false,
  child: Icon(Icons.decorative_icon),
)

// ❌ BAD: No alt text
Image.asset('assets/images/sad_dog_with_toy.jpg')
```

### Motion & Animation

**Requirements:**
- Respect `MediaQuery.of(context).disableAnimations` (for users with motion sickness)
- No auto-playing animations longer than 5 seconds
- Users can pause, stop, or control speed of animations
- No flashing/flickering (more than 3 times per second)

**Implementation:**
```dart
// ✅ GOOD: Respects motion preferences
bool shouldAnimate = !MediaQuery.of(context).disableAnimations;

AnimatedOpacity(
  opacity: shouldAnimate ? targetOpacity : 1.0,
  duration: shouldAnimate 
    ? const Duration(milliseconds: 500) 
    : Duration.zero,
  child: widget,
)

// ❌ BAD: Ignores motion preferences
AnimatedOpacity(
  opacity: targetOpacity,
  duration: const Duration(milliseconds: 500),
  child: widget,
)
```

### Touch Target Size

**Requirements:**
- Minimum 48x48 dp (Material Design standard)
- Minimum 44x44 dp at absolute minimum
- Adequate spacing between touch targets (minimum 8dp)
- No smaller targets without surrounding space

**Implementation:**
```dart
// ✅ GOOD: 48x48 minimum touch target
GestureDetector(
  onTap: () {},
  child: SizedBox(
    width: 48,
    height: 48,
    child: Icon(Icons.add),
  ),
)

// ✅ GOOD: Padding provides touch area
Padding(
  padding: const EdgeInsets.all(12),  // Adds to button size
  child: Text('Tap me'),
)

// ❌ BAD: Too small
GestureDetector(
  onTap: () {},
  child: Icon(Icons.add),  // Default ~24x24
)
```

---

## 📝 Typography & Readability

### Font Sizes

**Minimum Sizes:**
- Body text: 14px (WCAG requires readable by default)
- Small text: 12px minimum (footnotes, captions)
- Large text (18px+) can use 3:1 contrast instead of 4.5:1

**Font Hierarchy:**
```dart
// Headline 1 (32px) - Page titles
// Headline 2 (28px) - Section titles
// Headline Small (24px) - Subsection titles
// Body Large (18px) - Primary content
// Body (16px) - Regular body text (recommended for app)
// Body Small (14px) - Secondary content
// Label (12px) - Captions, metadata
```

**Implementation:**
```dart
// ✅ GOOD: Using Material theme scales
Text(
  'Welcome to the Waiting Place',
  style: Theme.of(context).textTheme.headlineSmall,  // 24px
)

Text(
  'Your approval is on its way!',
  style: Theme.of(context).textTheme.bodyLarge,  // 18px
)

// ❌ BAD: Hard-coded sizes without system consistency
Text(
  'Welcome',
  style: TextStyle(fontSize: 28),  // Not using theme
)
```

### Line Height & Spacing

**Requirements:**
- Line height minimum 1.5 for body text (1.5x font size)
- Paragraph spacing minimum 1.5x the line height
- Letter spacing can increase readability for dyslexic readers

**Implementation:**
```dart
// ✅ GOOD: Proper spacing for readability
Text(
  'Your approval is on its way!\nWe\'re so glad you joined us.',
  style: TextStyle(
    fontSize: 16,
    height: 1.8,  // 1.8x font size = excellent readability
    letterSpacing: 0.5,  // Improved for some dyslexic readers
  ),
)

// ✅ GOOD: Using SizedBox for paragraph spacing
Column(
  children: [
    Text('Paragraph 1'),
    const SizedBox(height: 24),  // 1.5x of typical line height
    Text('Paragraph 2'),
  ],
)

// ❌ BAD: No spacing
Text('Paragraph 1\nParagraph 2')  // Cramped
```

### Font Families

**Recommended:**
- **Primary UI:** Roboto, Inter (geometric, modern)
- **Headings:** Comic Neue (Andromeda theme), Poppins
- **Body Text:** Roboto, Inter, Open Sans
- **Monospace:** Roboto Mono (code snippets)

**Do Not Use:**
- Purely decorative fonts for critical content
- Fonts smaller than 12px
- More than 2 font families per screen
- Script fonts for body text

### Mobile-Optimized Font Sizes

**Duolingo-Inspired Mobile Standards:**
Following Duolingo's compact and efficient mobile design, use these optimized font sizes for narrow mobile device views (360px minimum width):

**Font Size Hierarchy for Mobile (360x780 viewport):**
```dart
// Page Titles: 16-18px (compact, clear hierarchy)
// Section Headings: 14-15px (clear but not overwhelming)
// Subsection Titles: 13-14px (readable, efficient)
// Body Text: 14px (standard mobile readability)
// Secondary Text: 12-13px (compact but legible)
// Small Text/Labels: 11-12px (minimum readable size)
// Chip Labels: 11px (touch-friendly, readable)
```

**Duolingo Design Principles Applied:**
- **Compact Hierarchy:** Smaller size differences between levels (2px steps instead of 4-6px)
- **Information Density:** More content fits on screen without scrolling
- **Visual Breathing Room:** Achieved through spacing/padding, not oversized text
- **Touch-Friendly:** Labels sized for readability, not touch targets (padding provides tap area)
- **Modern Mobile UX:** Matches contemporary apps (Duolingo, Notion, Linear)

**Implementation Examples:**

```dart
// ✅ GOOD: Duolingo-style compact page title
Text(
  'Student Management',
  style: TextStyle(
    fontSize: 18,  // Compact, not overwhelming (was 20px)
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
)

// ✅ GOOD: Compact section heading
Text(
  'Filters',
  style: TextStyle(
    fontSize: 14,  // Clear hierarchy (was 16px)
    fontWeight: FontWeight.bold,
  ),
)

// ✅ GOOD: Subsection titles
Text(
  'Age Filter',
  style: TextStyle(
    fontSize: 14,  // Readable, efficient (was 15px)
    fontWeight: FontWeight.w600,
  ),
)

// ✅ GOOD: Body text
Text(
  'Student information',
  style: TextStyle(
    fontSize: 14,  // Standard mobile size
  ),
)

// ✅ GOOD: Secondary labels
Text(
  'Grade',
  style: TextStyle(
    fontSize: 12,  // Compact labels (was 13px)
    fontWeight: FontWeight.w600,
    color: Colors.white70,
  ),
)

// ✅ GOOD: Chip labels
FilterChip(
  label: Text('Single', style: TextStyle(fontSize: 11)),  // Readable
)

// ❌ BAD: Oversized for mobile
Text(
  'Page Title',
  style: TextStyle(fontSize: 24),  // Too large, overwhelming
)

Text(
  'Section',
  style: TextStyle(fontSize: 18),  // Takes too much space
)
```

**Mobile Font Size Reference Table (Duolingo-Inspired):**

| Element Type | Old Desktop | Old Mobile | New Mobile | Viewport | Design Goal |
|--------------|-------------|------------|------------|----------|-------------|
| Page Titles | 24px | 20px | **18px** | 360px | Compact, clear |
| Section Headings | 16px | 16px | **14px** | 360px | Efficient hierarchy |
| Subsection Titles | 14px | 15px | **13px** | 360px | Consistent, readable |
| Body Text | 14px | 15px | **12px** | 360px | Standard mobile |
| Table Headers | 14px | 15px | **13px** | 360px | Clear, compact |
| Secondary Text | 12px | 13-14px | **12px** | 360px | Space-efficient |
| Small Labels | 10px | 11-12px | **11px** | 360px | Minimum readable |
| Chip Labels | 10px | 11px | **11px** | 360px | Touch-friendly |

**Real-World Examples from Codebase:**

```dart
// student_management.dart - Compact page title
Text(
  'Student Management',
  style: TextStyle(
    fontSize: 18,  // Duolingo-style (was 20px)
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
)

// student_management.dart - Efficient section heading
Text(
  'Filters',
  style: TextStyle(
    fontSize: 14,  // Clear hierarchy (was 16px)
    fontWeight: FontWeight.bold,
  ),
)

// student_management.dart - Compact filter titles
Text(
  'Age',
  style: TextStyle(
    fontSize: 14,  // Readable, efficient (was 15px)
    fontWeight: FontWeight.w600,
  ),
)

// student_management.dart - Space-efficient labels
Text(
  'Age',
  style: TextStyle(
    fontSize: 12,  // Compact (was 13px)
    fontWeight: FontWeight.w600,
    color: Colors.white70,
  ),
)

// student_management.dart - Table headers
Text(
  'Name',
  style: TextStyle(
    fontSize: 14,  // Standard (was 15px)
    fontWeight: FontWeight.w600,
  ),
)

// student_form_screen.dart - Compact form title
Text(
  'Add Student',
  style: TextStyle(
    fontSize: 18,  // Efficient (was 20px)
    fontWeight: FontWeight.bold,
  ),
)

// student_form_dialog.dart - Dialog title
Text(
  'Edit Student',
  style: TextStyle(
    fontSize: 16,  // Very compact for dialogs (was 18px)
  ),
)
```

**Why Duolingo-Inspired Standards Work:**
- **Information Density:** Users see more content without scrolling
- **Reduced Cognitive Load:** Smaller size differences create cleaner visual hierarchy
- **Modern Mobile UX:** Matches user expectations from contemporary apps
- **Better Viewport Utilization:** More efficient use of 360px width
- **Accessibility Maintained:** Still meets WCAG AA standards (14px body text, 4.5:1 contrast)
- **Touch-Friendly:** Padding provides touch targets; text sized for reading

**Viewport Testing:**
```dart
// CRITICAL: Test at minimum supported viewport
tester.view.physicalSize = const Size(360, 780);  // Samsung Galaxy S23
tester.view.devicePixelRatio = 1.0;

// Verify layout doesn't overflow
expect(tester.takeException(), isNull);

// Verify fonts are Duolingo-style compact
final titleFinder = find.text('Student Management');
final titleWidget = tester.widget<Text>(titleFinder);
expect(titleWidget.style?.fontSize, equals(18));  // Not 20 or 24
```

**Design Trade-offs:**
- ✅ **Gained:** More content per screen, modern UX, better information density
- ✅ **Maintained:** Accessibility (WCAG AA), readability, touch targets
- ⚠️ **Consider:** Users with vision impairments may need to zoom (system-level, not app-level)

---

## 🎨 Color & Contrast

### Color Palette Guidelines

**Brand Colors:**
- **Primary:** Used for main actions, focus indicators
- **Secondary:** Used for supporting actions, secondary elements
- **Surface:** Background colors for cards, containers
- **Error/Warning:** Red (#D32F2F), Orange (#F57C00)
- **Success/Info:** Green (#388E3C), Blue (#1976D2)

**Semantic Colors:**
```dart
// ✅ GOOD: Semantic color usage
Container(
  color: Theme.of(context).colorScheme.surfaceVariant,  // Surface
  child: Text(
    'Success!',
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  ),
)

// ❌ BAD: Hard-coded colors
Container(
  color: Colors.grey[100],  // Not semantic
  child: Text(
    'Success!',
    style: TextStyle(color: Colors.green),  // No contrast guarantee
  ),
)
```

### Opacity Guidelines

**Contrast Requirements:**
- Ensure 4.5:1 contrast even with opacity
- Test opacity values against background colors
- Don't use opacity below 0.6 for text content
- **REQUIRED:** Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity()`

**Implementation:**
```dart
// ✅ GOOD: Use modern .withValues() API
Text(
  'Secondary text',
  style: TextStyle(
    color: colors[3].withValues(alpha: 0.95),  // Modern API
  ),
)

// ❌ BAD: Deprecated .withOpacity() method
Text(
  'Secondary text',
  style: TextStyle(
    color: colors[3].withOpacity(0.4),  // DEPRECATED - do not use
  ),
)
```

### Color Should Never Be Sole Indicator

**Requirements:**
- Use color + icon, color + text, or color + pattern
- Red/green alone insufficient for color-blind users
- Support pattern, shape, or text alternatives

**Implementation:**
```dart
// ✅ GOOD: Color + Icon
Row(
  children: [
    Icon(Icons.check_circle, color: Colors.green),
    Text('Approved'),
  ],
)

// ✅ GOOD: Color + Text
Container(
  color: Colors.red,
  child: Text('Error: Please fix this'),
)

// ❌ BAD: Color alone
Container(
  color: Colors.red,
  width: 20,
  height: 20,
)
```

---

## 🔘 Interactive Elements

### Semantic Identifiers (key & semanticLabel)

**Critical Requirement:**
All interactive UI elements **MUST** have semantic identifiers for testability, accessibility, and debugging. This includes buttons, text fields, icons, toggles, menu items, navigation items, and any widget users can interact with.

**Why This Matters:**
- **Testing:** Widget tests find elements via `find.byKey()` and `find.bySemanticsLabel()` instead of brittle text matching
- **Accessibility:** Screen readers use semantic labels to describe interactive elements
- **Debugging:** Semantic identifiers appear in error messages and debug output
- **Maintenance:** Makes code self-documenting and easier to maintain

**Naming Convention:**
```dart
// Use descriptive, semantic names
final submitButtonKey = Key('submit-button');
final emailFieldKey = Key('email-input-field');
final deleteMenuItemKey = Key('delete-menu-item');
final profileIconKey = Key('profile-icon-button');
final adminMenuKey = Key('admin-menu');

// For consistent naming across app, define as constants
const submitButtonKey = Key('submit-button');
const emailFieldKey = Key('email-input-field');
const deleteMenuItemKey = Key('delete-menu-item');
```

**Implementation for All Interactive Elements:**

```dart
// ✅ GOOD: Button with semantic identifier
ElevatedButton(
  key: const Key('save-button'),
  onPressed: _handleSave,
  child: const Text('Save'),
)

// ✅ GOOD: TextField with semantic identifier and label
TextField(
  key: const Key('email-input-field'),
  decoration: InputDecoration(
    label: const Text('Email'),
    semanticLabel: 'Email input field',  // For screen readers
  ),
  onChanged: _validateEmail,
)

// ✅ GOOD: IconButton with semantic identifier
IconButton(
  key: const Key('menu-button'),
  onPressed: _openMenu,
  icon: const Icon(Icons.menu),
  tooltip: 'Open menu',  // Screen reader label
)

// ✅ GOOD: Toggle/Checkbox with semantic identifier
Checkbox(
  key: const Key('agree-terms-checkbox'),
  value: _agreeToTerms,
  onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
  semanticLabel: 'I agree to the terms and conditions',  // Screen reader label
)

// ✅ GOOD: DropdownButton with semantic identifier
DropdownButton(
  key: const Key('status-dropdown'),
  value: _selectedStatus,
  items: statusOptions.map((status) => DropdownMenuItem(
    key: Key('status-option-${status.id}'),  // Each item also needs key
    value: status,
    child: Text(status.name),
  )).toList(),
  onChanged: _handleStatusChange,
)

// ✅ GOOD: Custom widget with semantic identifier
GestureDetector(
  key: const Key('delete-student-action'),
  onTap: _handleDelete,
  child: Container(
    padding: const EdgeInsets.all(16),
    child: const Text('Delete'),
  ),
)

// ❌ BAD: No semantic identifier
ElevatedButton(
  onPressed: _handleSave,
  child: const Text('Save'),
)

// ❌ BAD: TextField without semantic identifier
TextField(
  decoration: InputDecoration(
    label: const Text('Email'),
  ),
  onChanged: _validateEmail,
)

// ❌ BAD: Menu items without individual keys
PopupMenuButton(
  itemBuilder: (context) => [
    const PopupMenuItem(
      child: Text('Edit'),  // No key!
    ),
    const PopupMenuItem(
      child: Text('Delete'),  // No key!
    ),
  ],
)
```

**Semantic Identifier Checklist - Add to ALL:**
- ✅ Buttons (ElevatedButton, TextButton, OutlinedButton)
- ✅ Text fields (TextField, TextFormField)
- ✅ Icon buttons (IconButton, InkWell, GestureDetector with tap handlers)
- ✅ Checkboxes, switches, toggles
- ✅ Dropdowns and pickers (DropdownButton, showDatePicker, etc.)
- ✅ Menu items (PopupMenuButton children, each item needs unique key)
- ✅ Navigation items (BottomNavigationBar items, NavigationBar destinations)
- ✅ Dialogs and bottom sheets (Dialog, AlertDialog, showDialog, showModalBottomSheet)
- ✅ Search bars and input fields
- ✅ Sliders and range selectors
- ✅ Custom interactive widgets (GestureDetector, InkWell)

**Testing Integration:**
With semantic identifiers, widget tests become robust and maintainable:

```dart
// ✅ GOOD: Test using semantic identifiers (robust)
testWidgets('saves student successfully', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  
  // Find by key (reliable, maintainable)
  await tester.enterText(find.byKey(const Key('email-input-field')), 'test@example.com');
  await tester.tap(find.byKey(const Key('save-button')));
  await tester.pumpAndSettle();
  
  // Verify result
  expect(find.text('Student saved'), findsOneWidget);
});

// ❌ BAD: Test using brittle text matching
testWidgets('saves student successfully', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  
  // Fragile - fails if label text changes
  await tester.enterText(find.byType(TextField), 'test@example.com');
  await tester.tap(find.byType(ElevatedButton));  // Wrong if multiple buttons!
  await tester.pumpAndSettle();
});
```

**Screen Reader Integration:**
Semantic labels help screen readers describe interactive elements:

```dart
// ✅ GOOD: Screen readers announce "Save button"
IconButton(
  key: const Key('save-button'),
  onPressed: _handleSave,
  icon: const Icon(Icons.save),
  tooltip: 'Save changes',
)

// ✅ GOOD: Screen readers announce "Delete student, Jane Doe"
Semantics(
  button: true,
  enabled: true,
  label: 'Delete student, ${student.name}',
  onTap: _handleDelete,
  child: GestureDetector(
    key: Key('delete-student-${student.id}'),
    onTap: _handleDelete,
    child: DeleteButton(),
  ),
)
```

**Verification Checklist:**
- [ ] All buttons have `key` property with semantic name
- [ ] All text fields have `key` property with semantic name
- [ ] All icon buttons have `tooltip` (for screen readers) + `key`
- [ ] All dropdown items have unique `key` values
- [ ] All menu items have individual keys
- [ ] All navigation destinations/items have keys
- [ ] Widget tests use `find.byKey()` instead of `find.byType()` or `find.text()`
- [ ] No brittle text-based widget finders in tests

---

### Buttons & Actions

**Requirements:**
- Minimum 48x48 dp touch target
- Clear label (no icon-only buttons without tooltips)
- Loading state visible (spinner, disabled state)
- Disabled state visually distinct
- Hover state on desktop

**Implementation:**
```dart
// ✅ GOOD: Complete button implementation
SizedBox(
  width: double.infinity,
  height: 48,
  child: ElevatedButton(
    onPressed: isLoading ? null : _handleSubmit,
    child: isLoading
      ? const CircularProgressIndicator()
      : const Text('Submit'),
  ),
)

// ❌ BAD: Missing states
FloatingActionButton(
  onPressed: _action,
  child: Icon(Icons.add),  // No label visible
)
```

### TextFields & Forms

**Requirements:**
- Clear, visible label (not placeholder-only)
- Error state visually distinct
- Helper text for guidance
- Input type appropriate (email keyboard for email, etc.)
- Validation as user types (with debounce)

**Implementation:**
```dart
// ✅ GOOD: Comprehensive form field
TextField(
  decoration: InputDecoration(
    label: Text('Email Address'),  // Always visible
    hintText: 'you@example.com',  // Example
    helperText: 'We\'ll never share your email',
    errorText: _emailError,  // Show validation errors
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  keyboardType: TextInputType.emailAddress,
  onChanged: _validateEmail,
)

// ❌ BAD: Placeholder-only, no error handling
TextField(
  decoration: InputDecoration(
    hintText: 'Email',  // Only hint, no label
  ),
)
```

### Dropdowns & Pickers

**Requirements:**
- Clear current selection visible
- All options visible or easily scrollable
- Keyboard navigation supported
- Option descriptions included for clarity

**Implementation:**
```dart
// ✅ GOOD: Accessible dropdown
DropdownButton(
  value: selectedValue,
  items: items.map((item) => DropdownMenuItem(
    value: item.id,
    child: Text(item.name),
  )).toList(),
  onChanged: _handleChange,
)

// ❌ BAD: No current value shown
DropdownButton(
  items: items.map((item) => DropdownMenuItem(
    value: item.id,
    child: Text(item.name),
  )).toList(),
)
```

### Navigation & Menus

**Requirements:**
- Current page/section highlighted
- Navigation structure logical
- Back button always available (except home)
- Menu accessible via multiple methods (menu button, tap, swipe)

**Implementation:**
```dart
// ✅ GOOD: Clear navigation state
NavigationBar(
  destinations: [
    NavigationDestination(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.people),
      label: 'Students',
    ),
  ],
  selectedIndex: _selectedIndex,
  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
)

// ❌ BAD: No indication of current page
Row(
  children: [
    ElevatedButton(child: Text('Home'), onPressed: () {}),
    ElevatedButton(child: Text('Students'), onPressed: () {}),
  ],
)
```

---

## 📐 Layout & Spacing

### Minimum Viewport & Mobile-First Design

**Critical Requirement:**
This app is designed **mobile-first** with over 90% of users on mobile devices.

**Minimum Supported Device:**
- **Samsung Galaxy S23**: 360×780 logical pixels
- All screens MUST be tested at this viewport size
- All widget tests MUST use this viewport configuration
- No content should require horizontal scrolling at 360px width

**Test Viewport Configuration:**
```dart
/// Configure test viewport to Samsung Galaxy S23 size (360x780 logical pixels)
/// This is the smallest phone the app needs to support
void configureTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1.0;
}
```

### Full-Screen Mobile UI Pattern

**Required Approach:**
All complex forms and data entry screens MUST use **full-screen mobile UI** instead of dialogs:

**✅ DO: Full-Screen Mobile UI**
- Use `Navigator.push()` or `context.go()` to dedicated pages
- Allows natural scrolling within the entire viewport
- Standard mobile pattern for complex forms
- Excellent UX - no cramming content into small dialogs
- AppBar for navigation and actions (Save, Cancel)
- Content area fills entire screen between AppBar and optional bottom buttons

**❌ DON'T: Dialog-Based Forms (for complex forms)**
- Dialogs limited to 600-800px height become cramped on mobile
- Requires aggressive padding reduction that compromises UX
- Buttons may end up off-screen requiring scroll
- Not standard mobile pattern for multi-field forms

**When to Use Dialogs vs Full-Screen:**
| Use Dialog | Use Full-Screen Page |
|------------|---------------------|
| Simple confirmation (1-3 buttons) | Student form (7+ fields) |
| Single text input | Multi-section forms |
| Password change (3 fields) | Profile editing |
| Delete confirmation | Settings configuration |
| Quick selection (dropdown) | Data entry with validation |

**Implementation Pattern:**
```dart
// ✅ GOOD: Full-screen mobile form
class StudentFormPage extends ConsumerStatefulWidget {
  const StudentFormPage({super.key, this.student});
  final Student? student;

  @override
  ConsumerState<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends ConsumerState<StudentFormPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student == null ? 'Add Student' : 'Edit Student'),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: Column(
            children: [
              // Profile image section
              // Basic info fields
              // Multi-select chips (behaviors, triggers, strategies)
              // All naturally scrollable
            ],
          ),
        ),
      ),
    );
  }
}

// Navigate to full-screen form
FloatingActionButton(
  onPressed: () => context.go('/students/add'),
  child: const Icon(Icons.add),
)
```

### Responsive Breakpoints

**Mobile-First Approach:**
```dart
// Phone: 360 - 599dp (default layout, Galaxy S23 minimum)
// Tablet: 600 - 1199dp
// Desktop: 1200dp+

bool isTablet(BuildContext context) =>
    MediaQuery.of(context).size.width >= 600;

bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= 1200;
```

### Padding & Margins

**Standard Spacing Scale:**
```dart
const double spacing4 = 4;    // Tiny gaps
const double spacing8 = 8;    // Small gaps
const double spacing12 = 12;  // Icon padding
const double spacing16 = 16;  // Standard padding
const double spacing20 = 20;  // Medium spacing
const double spacing24 = 24;  // Larger spacing
const double spacing32 = 32;  // Section spacing
const double spacing48 = 48;  // Major spacing
```

**Implementation:**
```dart
// ✅ GOOD: Using consistent spacing
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Text('Message'),
)

// ✅ GOOD: Using semantic spacing values
Container(
  padding: const EdgeInsets.all(16),  // Standard padding
  child: widget,
)

// ❌ BAD: Inconsistent spacing
Padding(
  padding: const EdgeInsets.only(left: 10, top: 5, right: 15),
  child: Text('Message'),
)
```

### Safe Areas & Notches

**Requirements:**
- Respect safe areas (notches, rounded corners)
- Critical content never hidden by notch
- Navigation never overlapped by system UI

**Implementation:**
```dart
// ✅ GOOD: Respect safe areas
Scaffold(
  body: SafeArea(
    child: ListView(
      children: items,
    ),
  ),
)

// ✅ GOOD: Explicit padding for notch awareness
Padding(
  padding: MediaQuery.of(context).padding,
  child: widget,
)

// ❌ BAD: Content extends behind notch
Column(children: items)
```

---

## �️ Viewport & Container Management

### Gradient & Background Container Sizing

**Key Finding:** When applying gradients or background decorations to content areas (especially in TabBarView), explicit sizing ensures proper viewport fill.

**Best Practice:**
```dart
// ✅ GOOD: Explicitly fill available space
body: Container(
  width: double.infinity,   // Fill available width
  height: double.infinity,  // Fill available height
  decoration: BoxDecoration(
    gradient: LinearGradient(...),
  ),
  child: TabBarView(
    children: [/* tabs */],
  ),
)

// ❌ PROBLEMATIC: May have sizing issues in some contexts
body: Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(...),
  ),
  child: TabBarView(
    children: [/* tabs */],
  ),
)
```

**Why This Matters:**
- Ensures gradient fills entire viewport between AppBar and BottomNav
- Prevents layout gaps or unwanted scrolling behavior
- Makes behavior predictable across devices and orientations
- TabBarView children scroll their content within this fixed container

### ScrollView Children in Containers

**Best Practice:** All TabBarView or other container children should use `SingleChildScrollView`:
```dart
// ✅ GOOD: ScrollView allows content to scroll within fixed container
@override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [/* content */],
      ),
    ),
  );
}

// ✅ ALSO GOOD: For complex layouts, use ListView
return ListView(
  padding: const EdgeInsets.all(20),
  children: [/* content */],
);
```

### NY Times Mobile App Reference

The New York Times mobile app demonstrates excellent viewport management:
- **Fixed AppBar** with compact navigation
- **Full-width content area** with gradient or color background
- **Scrollable content** using SingleChildScrollView within the viewport
- **Fixed BottomNav** for persistent navigation
- **No layout shifts** between pages during tab transitions

Apply this pattern when designing admin panels, content sections, and navigation-based pages.

---

## �📝 Forms & Input

### Validation

**Requirements:**
- Real-time validation (with debounce)
- Clear error messages (not error codes)
- Success confirmation
- Preserve valid input on form submission

**Implementation:**
```dart
// ✅ GOOD: Real-time validation with debounce
String? _emailError;
Timer? _validationTimer;

void _validateEmail(String value) {
  _validationTimer?.cancel();
  _validationTimer = Timer(const Duration(milliseconds: 500), () {
    setState(() {
      _emailError = _isValidEmail(value) ? null : 'Invalid email';
    });
  });
}

// ❌ BAD: Only validates on submit
void _handleSubmit() {
  if (!_isValidEmail(email)) {
    showError('Invalid email');  // Too late!
  }
}
```

### Password Input

**Requirements:**
- Show/hide toggle button (48x48 minimum)
- Real-time strength indicator
- Never save password in preferences
- Minimum 12 characters or 8+ with complexity

**Implementation:**
```dart
// ✅ GOOD: Complete password field
bool _showPassword = false;

TextField(
  obscureText: !_showPassword,
  decoration: InputDecoration(
    label: Text('Password'),
    suffixIcon: IconButton(
      icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
      onPressed: () => setState(() => _showPassword = !_showPassword),
    ),
  ),
)

// Display strength indicator
Text(
  _getPasswordStrength(password),
  style: TextStyle(color: _getStrengthColor(password)),
)
```

---

## 🖼️ Images & Media

### Image Optimization

**Requirements:**
- Maximum 100kb per image (mobile networks)
- Responsive sizes (srcset or picture element equivalent)
- Lazy loading for below-fold images
- Correct aspect ratio (no stretching)

**Implementation:**
```dart
// ✅ GOOD: Optimized image
Image.asset(
  'assets/images/icon.png',
  width: 48,
  height: 48,
  fit: BoxFit.contain,  // No distortion
)

// ✅ GOOD: Lazy loading
LazyLoad(
  child: Image.asset('assets/images/banner.jpg'),
)

// ❌ BAD: Over-sized image
Image.network(
  'https://example.com/huge-image-5mb.jpg',  // Too large!
)
```

### Video & Audio

**Requirements:**
- Captions for video content
- Transcript for audio content
- Auto-play disabled (requires user interaction)
- Volume control accessible

**Implementation:**
```dart
// ✅ GOOD: Video with captions
VideoPlayer(
  controller: _controller,
  subtitle: _buildSubtitles(),  // Captions/subtitles
)

// ✅ GOOD: Audio with transcript
Column(
  children: [
    AudioPlayer(controller: _audioController),
    ExpansionTile(
      title: Text('View Transcript'),
      children: [Text(_transcript)],
    ),
  ],
)
```

---

## ✨ Animation & Motion

### Appropriate Durations

**Guidelines:**
```dart
const Duration microInteraction = Duration(milliseconds: 200);  // Ripple, hover
const Duration shortTransition = Duration(milliseconds: 300);   // Page transition
const Duration mediumTransition = Duration(milliseconds: 500);  // Complex animation
// Never exceed 1000ms unless user explicitly triggered
```

**Implementation:**
```dart
// ✅ GOOD: Appropriate durations
AnimatedOpacity(
  opacity: isVisible ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 300),  // Not too long
  child: widget,
)

// ❌ BAD: Excessive animation
AnimatedOpacity(
  opacity: isVisible ? 1.0 : 0.0,
  duration: const Duration(seconds: 3),  // Too slow!
  child: widget,
)
```

### Curve & Easing

**Best Practices:**
- Use `Curves.easeOutCubic` for entering elements
- Use `Curves.easeInCubic` for exiting elements
- Use `Curves.easeInOutCubic` for continuous motion
- Avoid `Curves.linear` (feels mechanical)

**Implementation:**
```dart
// ✅ GOOD: Natural easing
ScaleTransition(
  scale: Tween(begin: 0, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
  ),
  child: widget,
)

// ❌ BAD: Linear/mechanical
ScaleTransition(
  scale: Tween(begin: 0, end: 1).animate(_controller),
  child: widget,
)
```

---

## � Flutter Best Practices

### Widget Composition & Lifecycle

**Best Practices:**
- Keep widgets small and focused (single responsibility principle)
- Extract repeated widgets into separate methods/classes
- Use `const` constructors where possible for performance
- Use `Key` only when list items order changes
- Never put multiple widgets in one method
- Prefer composition over inheritance
- Use proper widget lifecycle (initState, build, dispose)

**Implementation:**
```dart
// ✅ GOOD: Extracted, const constructors, proper lifecycle
class UserProfile extends StatelessWidget {
  const UserProfile({super.key, required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAvatar(),
        _buildName(),
        _buildBio(),
      ],
    );
  }

  Widget _buildAvatar() => const CircleAvatar(
    backgroundImage: NetworkImage('https://example.com/avatar.jpg'),
  );

  Widget _buildName() => Text(user.name);

  Widget _buildBio() => Text(user.bio);
}

// ❌ BAD: Everything in one method, no const
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      CircleAvatar(backgroundImage: NetworkImage(user.avatar)),
      Text(user.name),
      Text(user.bio),
      // ... 200 more lines
    ],
  );
}
```

### Modern Flutter 3.7+ API Usage

**Required Standard:**
All code **MUST** use modern Flutter 3.7+ APIs and avoid deprecated methods. This project requires Flutter SDK 3.7.0+.

**Key Modernizations:**

| Deprecated (Old) | Modern (3.7+) | Reason |
|------------------|---------------|--------|
| `Color.withOpacity(0.5)` | `Color.withValues(alpha: 0.5)` | Better composability, supports multiple channels |
| `Colors.black.withOpacity()` | `Colors.black.withValues(alpha: ...)` | Consistent naming, aligns with Material 3 |
| `WidgetStateProperty.all()` | `WidgetStateProperty.all()` | Already modern, but verify not using deprecated `MaterialStateProperty` |
| `FocusScope.of()` deprecated patterns | `Focus` widget with `FocusNode` | Better control and semantics |
| `Navigator.push()` (in most cases) | `context.go()` (via go_router) | Declarative routing, better state management |
| Direct color adjustments | `.withValues()` methods | Type-safe, supported across platforms |

**Implementation:**

```dart
// ✅ GOOD: Using modern Flutter 3.7+ API
Container(
  decoration: BoxDecoration(
    color: Colors.blue.withValues(alpha: 0.8),  // Modern API
    border: Border.all(
      color: Colors.grey.withValues(alpha: 0.5),  // Modern API
    ),
  ),
  child: Text(
    'Modern Flutter',
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.9),  // Modern API
    ),
  ),
)

// ❌ BAD: Using deprecated APIs
Container(
  decoration: BoxDecoration(
    color: Colors.blue.withOpacity(0.8),  // DEPRECATED
    border: Border.all(
      color: Colors.grey.withOpacity(0.5),  // DEPRECATED
    ),
  ),
  child: Text(
    'Old Flutter',
    style: TextStyle(
      color: Colors.white.withOpacity(0.9),  // DEPRECATED
    ),
  ),
)
```

**Verification:**
- Run `dart analyze` on all files - must show **zero** deprecation warnings
- Check Flutter changelog when updating SDK versions
- Use IDE inspections to flag deprecated APIs
- Never suppress deprecation warnings without discussion

**Current Project Status:**
- ✅ All files updated to Flutter 3.7+ API standards
- ✅ Zero deprecation warnings in production code
- ✅ Standard enforced in code reviews

### List Sorting with Explicit Comparators

**Required Standard:**
All `.sort()` calls on lists **MUST** include explicit comparator functions. This is critical for Flutter web compilation where minified JavaScript may not correctly infer comparison logic for typed lists.

**The Problem:**
When Flutter compiles Dart to minified JavaScript for web, calling `.sort()` without a comparator on typed lists (like `List<int>`) can fail with `NoSuchMethodError`. The minified JavaScript doesn't preserve the Dart type information needed to perform default comparisons.

**The Solution:**
Always provide an explicit comparison function to `.sort()`:

```dart
// ✅ GOOD: Explicit comparator for integers
final ages = [5, 3, 8, 1];
ages.sort((a, b) => a.compareTo(b));

// ✅ GOOD: Explicit comparator with cascade
final ages = students.map((s) => s.age).toSet().toList()
  ..sort((a, b) => a.compareTo(b));

// ✅ GOOD: Explicit comparator for strings
final names = ['Charlie', 'Alice', 'Bob'];
names.sort((a, b) => a.compareTo(b));

// ✅ GOOD: Reverse sort
final scores = [100, 85, 92];
scores.sort((a, b) => b.compareTo(a));  // Descending

// ❌ BAD: No comparator - fails in minified JavaScript
final ages = [5, 3, 8, 1];
ages.sort();  // NoSuchMethodError in production web build!

// ❌ BAD: Cascade without comparator
final ages = students.map((s) => s.age).toSet().toList()..sort();
```

**Why This Matters:**
- Works fine in debug mode and native platforms
- Fails silently in release web builds with cryptic minified errors
- Error appears as `NoSuchMethodError: method not found: 'gX'` where `gX` is minified method name
- Hard to debug without understanding the root cause

**Verification:**
- Always test web builds in release mode (`flutter build web --release`)
- Search codebase for `\.sort\(\)` regex pattern to find violations
- Code review must check all sort operations

**Related Dart/Flutter Issue:**
This is a known limitation of Dart-to-JavaScript compilation with aggressive minification. Explicit comparators ensure type-safe, predictable sorting across all platforms.

---

### Building Responsive Layouts

**Best Practices:**
- Use `MediaQuery.of(context).size` for responsive design
- Prefer `Flexible`/`Expanded` over fixed widths
- Test on multiple screen sizes (360px minimum, 600px tablet, 1200px desktop)
- Use `LayoutBuilder` for complex responsive behavior
- Ensure touch targets remain 48x48dp minimum

**Implementation:**
```dart
// ✅ GOOD: Responsive with breakpoints
class ResponsiveLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isPad = MediaQuery.of(context).size.width < 1200;
    
    return isMobile 
      ? _buildMobileLayout()
      : isPad ? _buildTabletLayout() : _buildDesktopLayout();
  }
}

// ✅ GOOD: Using LayoutBuilder
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 600) {
      return MobileWidget();
    }
    return DesktopWidget();
  },
)

// ❌ BAD: Hardcoded sizes
Container(width: 300, height: 500, child: MyContent())

// ❌ BAD: Nested Row with spaceBetween (causes overflow)
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(children: [Icon, Column]),  // Fixed width
    IconButton,
  ],
)

// ✅ GOOD: Flat Row with Expanded for flexible content
Row(
  children: [
    Icon,
    SizedBox(width: 12),
    Expanded(child: Column),  // Can shrink/wrap
    IconButton,
  ],
)
```

**Responsive Layout Anti-Patterns:**
- ❌ Nested `Row` widgets with `MainAxisAlignment.spaceBetween` (prevents content from shrinking)
- ❌ Fixed-width text containers in Rows (text can't wrap or shrink below minimum width)
- ❌ Using dialogs for complex multi-field forms on mobile (poor UX, cramped)
- ✅ Use flat `Row` structure with `Expanded` wrapping flexible content (text, forms)
- ✅ Use full-screen pages for complex forms instead of dialogs
- ✅ Test all screens at Galaxy S23 viewport (360×780) to catch overflow issues early

### State Management Architecture

**Best Practices:**
- Prefer stateless widgets when possible
- Use ConsumerStatefulWidget for screens combining local state + providers
- Use ConsumerWidget for read-only provider access
- Keep state close to where it's used
- Lift state up only when multiple widgets need it
- Never store provider instances in local variables

**Implementation:**
```dart
// ✅ GOOD: Proper state management layering
class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;  // Local state (lifecycle dependent)
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // Watch global state from Riverpod
    final authState = ref.watch(authProvider);
    final isAdmin = ref.watch(isAdminProvider);
    
    return Scaffold(
      appBar: AppBar(leading: _buildMenu()),
      body: TabBarView(controller: _tabController, children: [...]),
    );
  }

  Widget _buildMenu() => PopupMenuButton(
    itemBuilder: (context) => [
      PopupMenuItem(
        onTap: () {
          final service = ref.read(logoutServiceProvider);
          service.logout(context, ref);
        },
        child: const Text('Logout'),
      ),
    ],
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ❌ AVOID: Mixing too much logic, bad state placement
class BadPage extends StatefulWidget {
  // Global state mixed with local state - confusing!
}
```

### Navigation & Routing

**Best Practices:**
- Use `go_router` for all navigation
- Use named routes for consistency
- Pass data via route parameters, not constructors
- Handle navigation state properly in Riverpod
- Test navigation on web, mobile, desktop

**Implementation:**
```dart
// ✅ GOOD: Proper routing with go_router
import 'package:go_router/go_router.dart';

// Navigate
context.go('/admin');
context.go('/user/${userId}');
context.goNamed('admin');

// Pop
context.pop();

// Replace
context.go('/login', extra: {'reason': 'session_expired'});

// ❌ BAD: Navigator push/pop (old style)
Navigator.of(context).push(MaterialPageRoute(builder: ...))
```

---

## 🔄 Riverpod State Management

### Provider Types & Use Cases

**Choosing the Right Provider Type:**

| Provider Type | When to Use | Features |
|---------------|------------|----------|
| **`Provider`** | Read-only computed values | Immutable, rebuilds on dep changes |
| **`StateProvider`** | Simple mutable state | UI-driven state (toggles, counters) |
| **`StateNotifierProvider`** | Complex state logic | Logic encapsulation, methods |
| **`FutureProvider`** | Async operations (API calls) | Auto caching, loading/error states |
| **`StreamProvider`** | Real-time data streams | WebSockets, subscriptions |
| **`AsyncNotifierProvider`** | Complex async state | Like StateNotifierProvider but async |

**Implementation:**

```dart
// ✅ GOOD: Provider - read-only computed
final userDisplayNameProvider = Provider((ref) {
  final user = ref.watch(userProvider);
  return '${user.firstName} ${user.lastName}';
});

// ✅ GOOD: StateProvider - simple UI state
final isMenuOpenProvider = StateProvider((ref) => false);

// ✅ GOOD: StateNotifierProvider - complex state
final userNotifierProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<User?> {
  UserNotifier() : super(null);

  Future<void> login(String email, String password) async {
    try {
      state = await api.login(email, password);
    } catch (e) {
      state = null;
      rethrow;
    }
  }
}

// ✅ GOOD: FutureProvider - async data
final usersProvider = FutureProvider<List<User>>((ref) async {
  return await api.fetchUsers();
});

// ❌ BAD: Mixing different paradigms
final badProvider = Provider((ref) {
  // ❌ Don't do async work in Provider
  return Future.value(data);
});
```

### Watching & Reading Providers

**Best Practices:**
- Use `.watch()` in build() for reactive updates
- Use `.read()` in callbacks (onPressed, onTap)
- Never mix watch/read in callbacks (causes issues)
- Use `.select()` to watch only specific fields (performance)
- Invalidate providers only when necessary

**Implementation:**

```dart
// ✅ GOOD: Watching in build for reactive UI
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Rebuilds when user changes
  final user = ref.watch(userProvider);
  
  // Only watch age field (doesn't rebuild on name change)
  final age = ref.watch(userProvider.select((u) => u.age));
  
  return Text('${user.name}, Age: $age');
}

// ✅ GOOD: Reading in callbacks (one-time access)
onPressed: () {
  final user = ref.read(userProvider);
  final service = ref.read(logoutServiceProvider);
  service.logout(user.id);
}

// ❌ BAD: Watching in callbacks
onPressed: () {
  final user = ref.watch(userProvider);  // ❌ Wrong! Call outside build
}

// ❌ BAD: Invalidating too frequently
ref.invalidate(userProvider);  // Use sparingly!
```

### Provider Composition & Dependencies

**Best Practices:**
- Keep providers focused and composable
- Create derived providers instead of multiple parent providers
- Use `.family` modifier for parameterized providers
- Document provider dependencies clearly
- Test providers in isolation

**Implementation:**

```dart
// ✅ GOOD: Composable providers
final userProvider = FutureProvider<User>((ref) async {
  return await api.fetchUser();
});

// Derived provider - composes user provider
final userDisplayNameProvider = Provider((ref) {
  final user = ref.watch(userProvider);
  return user.when(
    data: (u) => '${u.firstName} ${u.lastName}',
    loading: () => 'Loading...',
    error: (err, stack) => 'Error',
  );
});

// ✅ GOOD: Parameterized provider with .family
final userByIdProvider = FutureProvider.family<User, String>((ref, userId) async {
  return await api.fetchUser(userId);
});

// Usage
ref.watch(userByIdProvider('user-123'));

// ✅ GOOD: Async state with proper error handling
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(api);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiClient api;
  
  AuthNotifier(this.api) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => api.login(email, password));
  }
}

// ❌ BAD: Overly complex provider chain
// Don't create providers that watch 10+ other providers
```

### Error Handling in Providers

**Best Practices:**
- Use `AsyncValue` for loading/error/data states
- Provide meaningful error messages to UI
- Log errors with context
- Retry failed operations when appropriate
- Never expose internal errors to users

**Implementation:**

```dart
// ✅ GOOD: Proper async error handling
final usersProvider = FutureProvider<List<User>>((ref) async {
  try {
    final users = await api.fetchUsers();
    return users;
  } on SocketException catch (e) {
    _logger.w('Network error: $e');
    throw 'No internet connection. Please check your connection.';
  } on UnauthorizedException catch (e) {
    _logger.e('Auth failed: $e');
    throw 'Session expired. Please login again.';
  } catch (e) {
    _logger.e('Unexpected error: $e');
    throw 'Something went wrong. Please try again.';
  }
});

// ✅ GOOD: Using AsyncValue in UI
@override
Widget build(BuildContext context, WidgetRef ref) {
  final usersAsync = ref.watch(usersProvider);
  
  return usersAsync.when(
    data: (users) => ListView(children: [...]),
    loading: () => const CircularProgressIndicator(),
    error: (error, stackTrace) => ErrorWidget(message: error.toString()),
  );
}

// ✅ GOOD: Retry logic
onPressed: () {
  ref.refresh(usersProvider);  // Retry by refreshing
}
```

### Provider Lifecycle & Disposal

**Best Practices:**
- Use `.autoDispose` for providers that should clean up
- Override `mayNeedUpdate()` for custom invalidation
- Clean up resources in StateNotifier `dispose()`
- Monitor provider rebuilds with DevTools

**Implementation:**

```dart
// ✅ GOOD: Auto-dispose provider
final userProvider = FutureProvider.autoDispose<User>((ref) async {
  // Cleaned up when no longer watched
  return await api.fetchUser();
});

// ✅ GOOD: Cleanup in StateNotifier
final streamProvider = StreamProvider.autoDispose<Data>((ref) {
  final subscription = api.subscribe();
  
  // Cleanup when done
  ref.onDispose(() {
    subscription.cancel();
  });
  
  return subscription.asStream();
});

// ✅ GOOD: StateNotifier with cleanup
class DataNotifier extends StateNotifier<Data> {
  final ApiClient api;
  late StreamSubscription subscription;

  DataNotifier(this.api) : super(Data.initial()) {
    _init();
  }

  void _init() {
    subscription = api.subscribe().listen((data) {
      state = data;
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }
}
```

### Testing Providers

**Best Practices:**
- Test providers in isolation with ProviderContainer
- Mock dependencies using `.overrideWith()`
- Test loading/error/success states
- Verify provider invalidation behavior

**Implementation:**

```dart
// ✅ GOOD: Provider testing
test('userProvider fetches user', () async {
  final container = ProviderContainer();
  
  final user = await container.read(userProvider.future);
  expect(user.name, 'John Doe');
});

test('userProvider with mock', () async {
  final container = ProviderContainer(
    overrides: [
      userProvider.overrideWith((ref) async => mockUser),
    ],
  );
  
  final user = await container.read(userProvider.future);
  expect(user.name, mockUser.name);
});
```

---

## 📡 HTTP Configuration with Dio

### Centralized HTTP Client Setup

**Overview:**
This project uses **Dio 5.9.0+** for all HTTP/HTTPS communication with a centralized configuration that ensures:
- Automatic Bearer token injection for authenticated requests
- Consistent error handling across all API calls
- Request/response logging in debug mode
- Unified base URL and timeout configuration
- Proper response data handling

**Architecture:**

The centralized Dio configuration is located in `services/dio_service.dart` with:
- **Base URL**: Configured via `ApiConfig.baseUrl` (http://localhost:8002/api/v1 for dev, https://ruckusrulers.com/api/v1 for prod)
- **Timeouts**: 30 seconds for connect and receive
- **Headers**: JSON content-type and Accept headers
- **Interceptors**: 
  - Auth interceptor for automatic Bearer token injection
  - Debug logging interceptor for request/response bodies in debug mode

**Usage in Providers:**

```dart
// ✅ GOOD: Using centralized Dio provider in FutureProvider
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated) {
    throw Exception('User not authenticated');
  }
  
  // Get dio instance - already has auth token injected via interceptor
  final dio = ref.read(dioProvider);
  
  try {
    final response = await dio.get('/analytics/dashboard-summary');
    return DashboardSummary.fromJson(response.data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      throw Exception('Unauthorized: Please log in again');
    }
    throw Exception('Failed to load dashboard data: ${e.message}');
  }
});
```

### HTTP Methods with Dio

**GET Requests:**

```dart
// ✅ GOOD: Simple GET request
final response = await dio.get('/students/');
final students = (response.data as List)
    .map((s) => Student.fromJson(s))
    .toList();

// ✅ GOOD: GET with query parameters
final response = await dio.get(
  '/students',
  queryParameters: {'grade': 'K', 'sort': 'name'},
);
```

**POST Requests:**

```dart
// ✅ GOOD: POST with data
final response = await dio.post(
  '/students/',
  data: student.toJson(),
);
final newStudent = Student.fromJson(response.data);

// ✅ GOOD: POST with error handling
try {
  final response = await dio.post('/auth/admin/approve-user', data: {
    'user_id': userId,
    'role': 'teacher',
    'approval_notes': notes,
  });
  // Handle success
} on DioException catch (e) {
  if (e.response?.statusCode == 409) {
    // Handle conflict
  }
}
```

**PUT/PATCH Requests:**

```dart
// ✅ GOOD: PUT request for updates
final response = await dio.put(
  '/users/$userId',
  data: {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
  },
);

// ✅ GOOD: PATCH for partial updates
final response = await dio.patch(
  '/students/$studentId',
  data: {'gened_teacher': newTeacherName},
);
```

**DELETE Requests:**

```dart
// ✅ GOOD: DELETE request
final response = await dio.delete('/students/$studentId');
// 204 No Content or 200 with data

// ✅ GOOD: DELETE with error handling
try {
  await dio.delete('/students/$studentId');
  // Student deleted successfully
} on DioException catch (e) {
  if (e.response?.statusCode == 404) {
    print('Student not found');
  }
}
```

### Response Handling

**Best Practices:**

```dart
// ✅ GOOD: Typed response handling
try {
  final response = await dio.get('/users/$userId');
  
  // response.data is automatically deserialized
  // For JSON endpoints, it's a Map<String, dynamic> or List
  final user = User.fromJson(response.data);
  
  // Check status code when needed
  if (response.statusCode == 200) {
    return user;
  }
} on DioException catch (e) {
  // DioException provides typed access to response
  if (e.response?.statusCode == 401) {
    throw UnauthorizedException();
  } else if (e.response?.statusCode == 404) {
    throw NotFoundException();
  } else if (e.type == DioExceptionType.connectionTimeout) {
    throw NetworkException('Connection timeout');
  } else {
    throw HttpException('HTTP error: ${e.message}');
  }
}

// ❌ BAD: Don't use jsonDecode with Dio
// Dio already deserializes JSON automatically
final data = jsonDecode(response.body);  // ❌ response has no .body
```

### Error Types and Handling

```dart
// ✅ GOOD: Handle DioException types
try {
  await dio.get('/data');
} on DioException catch (e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      print('Connection timeout - check network');
      break;
    case DioExceptionType.receiveTimeout:
      print('Server response timeout');
      break;
    case DioExceptionType.badResponse:
      print('Bad response - status: ${e.response?.statusCode}');
      break;
    case DioExceptionType.cancel:
      print('Request cancelled');
      break;
    case DioExceptionType.unknown:
      print('Unknown error: ${e.message}');
      break;
    default:
      print('Other error: ${e.message}');
  }
}
```

### DO's and DON'Ts

```dart
// ✅ DO: Always use dio instance from ref.read(dioProvider)
final dio = ref.read(dioProvider);
final response = await dio.get('/endpoint');

// ✅ DO: Use relative paths (base URL is configured)
await dio.get('/students/');
await dio.post('/auth/login', data: {...});

// ✅ DO: Access response data directly
final user = User.fromJson(response.data);

// ✅ DO: Handle DioException for network errors
try {
  await dio.get('/data');
} on DioException catch (e) {
  print('Error: ${e.message}');
}

// ❌ DON'T: Create new Dio instances
final newDio = Dio();  // Wrong! Use ref.read(dioProvider)

// ❌ DON'T: Manually add auth headers (interceptor does it)
await http.get(url, headers: {'Authorization': 'Bearer $token'});

// ❌ DON'T: Use jsonDecode/jsonEncode with Dio
final data = jsonDecode(response.body);  // Wrong! Use response.data

// ❌ DON'T: Use http package anymore (legacy)
import 'package:http/http.dart' as http;  // ❌ Deprecated pattern
```

---

## 🔌 API Integration & CRUD Operations

### Data Models & Serialization

**Critical Rule**: When sending PUT/PATCH requests, **exclude `id` from `toJson()`** - the ID belongs in the URL path, not the request body.

```dart
// ✅ GOOD: Exclude id from toJson() for updates
class Strategy {
  final int? id;
  final String name;
  final String? shortDescription;
  final String? frequency12Months;
  
  const Strategy({
    this.id,
    required this.name,
    this.shortDescription,
    this.frequency12Months,
  });
  
  // Factory for API responses (includes id)
  factory Strategy.fromJson(Map<String, dynamic> json) => Strategy(
    id: json['id'] as int?,
    name: json['name'] as String,
    shortDescription: json['short_description'] as String?,
    frequency12Months: json['frequency_12_months'] as String?,
  );
  
  // For PUT/POST requests - EXCLUDE id!
  Map<String, dynamic> toJson() => {
    'name': name,
    'short_description': shortDescription,
    'frequency_12_months': frequency12Months,
    // ✅ NO 'id' field - it goes in the URL path
  };
  
  // Optional: Include id for special cases (not for API updates)
  Map<String, dynamic> toJsonWithId() => {
    'id': id,
    ...toJson(),
  };
}


// ❌ BAD: Including id in toJson() causes Pydantic validation errors
class BadStrategy {
  final int? id;
  final String name;
  
  Map<String, dynamic> toJson() => {
    'id': id,  // ❌ Wrong! Backend expects id in URL path, not body
    'name': name,
  };
}
```

### CRUD Best Practices

#### CREATE (POST)

```dart
// ✅ GOOD: Create with validation and error handling
Future<void> _createStrategy() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }
  
  setState(() => _isLoading = true);
  
  try {
    final newStrategy = Strategy(
      name: _nameController.text.trim(),
      shortDescription: _descriptionController.text.trim(),
      frequency12Months: _frequencyController.text.trim(),
    );
    
    final dio = ref.read(dioProvider);
    final response = await dio.post(
      '/strategies',
      data: newStrategy.toJson(),  // No id field
    );
    
    final created = Strategy.fromJson(response.data);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Strategy created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, created);
    }
  } on DioException catch (e) {
    _showError('Create Failed', e.response?.data['detail'] ?? e.message);
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

#### READ (GET)

```dart
// ✅ GOOD: Read with loading state and error handling
final strategyProvider = FutureProvider.family<Strategy, int>((ref, id) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/strategies/$id');
  return Strategy.fromJson(response.data);
});

// In widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final strategyAsync = ref.watch(strategyProvider(widget.strategyId));
  
  return strategyAsync.when(
    data: (strategy) => _buildStrategyView(strategy),
    loading: () => Center(child: CircularProgressIndicator()),
    error: (error, stack) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text('Error: $error'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(strategyProvider(widget.strategyId)),
            child: Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
```

#### UPDATE (PUT) - Critical Pattern

```dart
// ✅ GOOD: Update with change detection and proper ID handling
Future<void> _saveStrategy() async {
  // Validate form
  if (!_formKey.currentState!.validate()) {
    return;
  }
  
  // Check for changes
  final hasChanges = _nameController.text != widget.strategy.name ||
      _descriptionController.text != widget.strategy.shortDescription ||
      _frequencyController.text != widget.strategy.frequency12Months;
  
  if (!hasChanges) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No changes to save')),
    );
    return;
  }
  
  setState(() => _isLoading = true);
  
  try {
    final updatedStrategy = Strategy(
      id: widget.strategy.id,  // ✅ Include id for the object
      name: _nameController.text.trim(),
      shortDescription: _descriptionController.text.trim(),
      frequency12Months: _frequencyController.text.trim(),
    );
    
    final dio = ref.read(dioProvider);
    
    // ✅ CRITICAL: ID in path, data in body (without id)
    final response = await dio.put(
      '/strategies/${updatedStrategy.id}',  // ID in URL path
      data: updatedStrategy.toJson(),        // Body WITHOUT id field
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Strategy updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  } on DioException catch (e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data['detail'] ?? e.message;
    
    if (statusCode == 500) {
      _showError('Server Error', 
        'Backend error occurred. Check backend logs for details.');
    } else {
      _showError('Update Failed', message ?? 'Unknown error');
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}


// ❌ BAD: Including id in request body
await dio.put(
  '/strategies/${strategy.id}',
  data: {
    'id': strategy.id,  // ❌ WRONG! Causes Pydantic validation error
    'name': strategy.name,
  },
);


// ❌ BAD: Not including id in URL path
await dio.put(
  '/strategies',  // ❌ WRONG! Backend expects /strategies/{id}
  data: strategy.toJson(),
);
```

#### DELETE

```dart
// ✅ GOOD: Delete with confirmation dialog
Future<void> _deleteStrategy(int id) async {
  // Show confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Strategy'),
      content: Text(
        'Are you sure you want to delete this strategy? '
        'This action cannot be undone.'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text('Delete'),
        ),
      ],
    ),
  );
  
  if (confirmed != true) return;
  
  setState(() => _isLoading = true);
  
  try {
    final dio = ref.read(dioProvider);
    await dio.delete('/strategies/$id');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Strategy deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  } on DioException catch (e) {
    _showError('Delete Failed', e.response?.data['detail'] ?? e.message);
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### Error Handling Patterns

```dart
// ✅ GOOD: Comprehensive error handling with specific messages
void _showError(String title, String? message) {
  if (!mounted) return;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$title: ${message ?? "Unknown error"}'),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {},
      ),
    ),
  );
}

// Handle different HTTP status codes
try {
  await dio.put('/strategies/${id}', data: data);
} on DioException catch (e) {
  final statusCode = e.response?.statusCode;
  final detail = e.response?.data['detail'];
  
  switch (statusCode) {
    case 400:
      _showError('Validation Error', detail ?? 'Invalid data');
      break;
    case 401:
      _showError('Unauthorized', 'Please log in again');
      // Navigate to login
      break;
    case 403:
      _showError('Forbidden', 'You do not have permission');
      break;
    case 404:
      _showError('Not Found', 'Resource does not exist');
      break;
    case 500:
      _showError('Server Error', 
        'Backend error. Check server logs for details.');
      break;
    default:
      _showError('Error', detail ?? e.message);
  }
}
```

### API Integration Checklist

**Data Models:**
- [ ] `toJson()` excludes `id` field for PUT/POST requests
- [ ] `fromJson()` includes `id` field for responses
- [ ] Field names match backend (snake_case ↔ camelCase conversion)
- [ ] All required fields are non-nullable
- [ ] Optional fields use nullable types (`String?`, `int?`)

**HTTP Requests:**
- [ ] Use `dio` from `dioProvider` (centralized instance)
- [ ] ID in URL path for GET/PUT/DELETE: `/resources/{id}`
- [ ] Data in body for POST/PUT (without id field)
- [ ] Query parameters for filtering/sorting
- [ ] Proper HTTP methods (GET/POST/PUT/DELETE)

**Error Handling:**
- [ ] Try-catch blocks around all API calls
- [ ] Handle specific HTTP status codes (400, 401, 403, 404, 500)
- [ ] User-friendly error messages in SnackBars
- [ ] Network error handling (timeout, connection failed)
- [ ] Loading states during API calls (`_isLoading`)

**Widget Integration:**
- [ ] Form validation before API calls (`_formKey.currentState!.validate()`)
- [ ] Loading indicators during requests
- [ ] Success feedback (SnackBar + navigation)
- [ ] Error feedback (SnackBar with retry option)
- [ ] Change detection for updates
- [ ] Confirmation dialogs for destructive actions (DELETE)
- [ ] Mounted checks before setState/navigation (`if (mounted)`)

**Common Mistakes to Avoid:**
- ❌ Including `id` in `toJson()` for PUT requests → causes Pydantic errors
- ❌ Forgetting ID in URL path: `/resources` instead of `/resources/{id}`
- ❌ Using wrong HTTP method (POST instead of PUT for updates)
- ❌ Not handling HTTP 500 errors properly
- ❌ Not converting between snake_case (backend) and camelCase (frontend)
- ❌ Missing null checks for optional fields
- ❌ Not showing loading states during async operations

---

## 🎯 Dart Code Quality

### Type Safety

**Requirements:**
- No `dynamic` types (use generics instead)
- No `var` for public APIs (use explicit types)
- Enable strict null safety (`// ignore: avoid_null_checks`)
- Use sealed classes for variant types

**Implementation:**
```dart
// ✅ GOOD: Explicit, safe types
List<User> getUsers() {
  return users;
}

final Map<String, dynamic> metadata = _parseJson(data);

// ✅ GOOD: Sealed classes for types
sealed class Result<T> {}
final class Success<T> extends Result<T> {
  Success(this.data);
  final T data;
}
final class Failure<T> extends Result<T> {
  Failure(this.error);
  final String error;
}

// ❌ BAD: Dynamic types
var getUsers() {
  return users;  // Type lost!
}

List<dynamic> items = [...];  // Type not enforced
```

### Naming Conventions

**Rules:**
```dart
// Classes: PascalCase
class UserProfile {}

// Variables & properties: lowerCamelCase (required)
String userEmail;
int studentCount;
bool isLoading;

// Methods & functions: lowerCamelCase (required)
void fetchUserData() {}
String getUserName() {}

// Constants: lowerCamelCase (required)
const int maxRetries = 3;
const double screenPaddingHorizontal = 16.0;

// Private members: _leadingUnderscore
String _privateEmail;
void _internalMethod() {}
final _cachedData = <String, dynamic>{};

// Boolean getters & variables: is/has prefix
bool isLoading;
bool hasError;
bool isVisible;
```

### Code Formatting

**Requirements:**
- Maximum line length: 80 characters (strict) or 120 (comfortable)
- Use `dart format` before commit
- Consistent indentation (2 spaces)
- One statement per line

**Implementation:**
```dart
// ✅ GOOD: Well-formatted
class User {
  const User({
    required this.id,
    required this.email,
    this.avatar,
  });

  final String id;
  final String email;
  final String? avatar;
}

// ❌ BAD: Poor formatting
class User{const User({required this.id,required this.email,this.avatar,});final String id;final String email;final String?avatar;}
```

### Documentation

**Requirements:**
- Document all public APIs (classes, methods, properties)
- Use triple-slash comments (`///`)
- Include examples for complex methods
- Link to related classes/methods

**Implementation:**
```dart
// ✅ GOOD: Complete documentation
/// Authenticates user with email and password.
///
/// Returns a [User] object on success, throws [UnauthorizedException]
/// if credentials are invalid.
///
/// Example:
/// ```dart
/// try {
///   final user = await auth.login('user@example.com', 'password');
/// } on UnauthorizedException {
///   print('Invalid credentials');
/// }
/// ```
Future<User> login(String email, String password) async {
  // ...
}

// ❌ BAD: No documentation
Future<User> login(String email, String password) async {
  // ...
}
```

### Production Code Quality - Debugging Output

**Critical Requirement:**
**DO NOT use `print()` in production code.** Console output clutters logs, impacts performance, and is unprofessional in released apps.

**Why This Matters:**
- `print()` outputs to console/logcat in all environments (debug, release, production)
- Accumulates clutter in user logs and analytics
- Can leak sensitive information (passwords, tokens, user data)
- Increases app overhead (I/O operations)
- Shows unprofessional behavior in console when users run apps from IDE

**Approved Alternatives:**

---

## 📦 Model Serialization & Backend Communication

### JSON Serialization Standard

**Critical Requirement:**
All model classes **MUST** serialize to **snake_case** when sending data to the backend via `toJson()`. The backend API expects snake_case field names per Python/FastAPI conventions.

**Why This Matters:**
- **Backend Compatibility:** Python/FastAPI uses snake_case naming conventions
- **API Validation:** Backend will reject camelCase fields with 422 validation errors
- **Consistency:** Prevents field naming mismatches that cause save/update failures
- **Maintainability:** Clear standard prevents confusion across frontend/backend boundary

### Implementation Pattern

**Required Structure:**
```dart
class Student {
  const Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.gradeLevel,
    required this.parentNames,
    this.profileImage,
  });

  final String id;
  final String firstName;      // camelCase in Dart
  final String lastName;       // camelCase in Dart
  final int age;
  final String gradeLevel;     // camelCase in Dart
  final List<String> parentNames;  // camelCase in Dart
  final Uint8List? profileImage;

  /// Serialize to JSON for backend API
  /// CRITICAL: Use snake_case field names for backend compatibility
  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,        // ✅ snake_case for backend
    'last_name': lastName,          // ✅ snake_case for backend
    'age': age,
    'grade_level': gradeLevel,      // ✅ snake_case for backend
    'parent_names': parentNames,    // ✅ snake_case for backend
    if (profileImage != null) 
      'profile_image': base64Encode(profileImage!),  // ✅ snake_case
  };

  /// Deserialize from JSON (backend response)
  /// Support BOTH snake_case (backend) and camelCase (legacy/flexibility)
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? '',
      // Accept both formats for robustness
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      age: json['age'] ?? 0,
      gradeLevel: json['grade_level'] ?? json['gradeLevel'] ?? '',
      parentNames: (json['parent_names'] ?? json['parentNames'] ?? [])
          .map<String>((e) => e.toString())
          .toList(),
      profileImage: json['profile_image'] != null
          ? base64Decode(json['profile_image'])
          : null,
    );
  }
}
```

### Field Naming Rules

**toJson() Output (to Backend):**
```dart
// ✅ CORRECT: snake_case for backend
Map<String, dynamic> toJson() => {
  'first_name': firstName,
  'last_name': lastName,
  'grade_level': gradeLevel,
  'parent_names': parentNames,
  'parent_contact_phone': parentContactPhone,
  'created_at': createdAt.toIso8601String(),
  'updated_at': lastModified?.toIso8601String(),
};

// ❌ WRONG: camelCase will cause 422 validation errors
Map<String, dynamic> toJson() => {
  'firstName': firstName,       // Backend won't accept this
  'lastName': lastName,         // Backend won't accept this
  'gradeLevel': gradeLevel,     // Backend won't accept this
};
```

**fromJson() Input (from Backend):**
```dart
// ✅ CORRECT: Accept both formats for flexibility
factory Student.fromJson(Map<String, dynamic> json) {
  return Student(
    // Try snake_case first (backend standard), fallback to camelCase
    firstName: json['first_name'] ?? json['firstName'] ?? '',
    lastName: json['last_name'] ?? json['lastName'] ?? '',
    gradeLevel: json['grade_level'] ?? json['gradeLevel'] ?? '',
  );
}

// ❌ PROBLEMATIC: Only accepting one format
factory Student.fromJson(Map<String, dynamic> json) {
  return Student(
    firstName: json['firstName'],  // Fails if backend sends 'first_name'
    lastName: json['lastName'],
    gradeLevel: json['gradeLevel'],
  );
}
```

### Common Field Name Mappings

| Dart Property (camelCase) | JSON Field (snake_case) |
|--------------------------|------------------------|
| `firstName` | `first_name` |
| `lastName` | `last_name` |
| `gradeLevel` | `grade_level` |
| `parentNames` | `parent_names` |
| `parentContactPhone` | `parent_contact_phone` |
| `createdAt` | `created_at` |
| `lastModified` | `updated_at` |
| `profileImage` | `profile_image` |
| `supportNeeds` | `support_needs` |

### API Communication Pattern

**POST/PUT Requests (Creating/Updating):**
```dart
// ✅ CORRECT: Use toJson() which outputs snake_case
Future<void> saveStudent(Student student) async {
  final apiService = ApiService();
  final response = await apiService.post(
    '/students/',
    body: student.toJson(),  // ✅ Automatically converts to snake_case
  );
}

// ❌ WRONG: Manually constructing JSON in camelCase
Future<void> saveStudent(Student student) async {
  final apiService = ApiService();
  final response = await apiService.post(
    '/students/',
    body: {
      'firstName': student.firstName,  // ❌ Backend rejects this
      'lastName': student.lastName,
    },
  );
}
```

**GET Requests (Fetching):**
```dart
// ✅ CORRECT: fromJson() handles both formats
Future<Student> fetchStudent(String id) async {
  final apiService = ApiService();
  final response = await apiService.get('/students/$id');
  return Student.fromJson(response);  // ✅ Handles snake_case from backend
}
```

### Validation Error Debugging

**422 Validation Errors:**
If you see errors like:
```
422 - {"detail":[{"type":"missing","loc":["body","first_name"],"msg":"Field required"}]}
```

**This means:**
- Backend is looking for `first_name` (snake_case)
- Frontend sent `firstName` (camelCase)
- **Fix:** Update model's `toJson()` to use snake_case

**Verification Checklist:**
- [ ] All `toJson()` methods use snake_case field names
- [ ] All `fromJson()` methods accept both snake_case and camelCase (defensive)
- [ ] DateTime fields serialize to ISO 8601 strings (`toIso8601String()`)
- [ ] Optional/nullable fields use conditional inclusion (`if (field != null)`)
- [ ] List fields properly serialize (not as comma-separated strings unless backend expects that)
- [ ] Enum fields serialize to backend-expected string values
- [ ] No field name mismatches between Dart properties and JSON keys

### Testing Serialization

**Unit Test Pattern:**
```dart
test('Student.toJson() uses snake_case field names', () {
  final student = Student(
    id: 'test-123',
    firstName: 'John',
    lastName: 'Doe',
    age: 10,
    gradeLevel: '5th',
    parentNames: ['Jane Doe'],
  );

  final json = student.toJson();

  // Verify snake_case output
  expect(json['first_name'], 'John');
  expect(json['last_name'], 'Doe');
  expect(json['grade_level'], '5th');
  expect(json['parent_names'], ['Jane Doe']);
  
  // Ensure no camelCase fields present
  expect(json.containsKey('firstName'), false);
  expect(json.containsKey('lastName'), false);
  expect(json.containsKey('gradeLevel'), false);
});

test('Student.fromJson() accepts snake_case from backend', () {
  final json = {
    'id': 'test-123',
    'first_name': 'John',
    'last_name': 'Doe',
    'age': 10,
    'grade_level': '5th',
    'parent_names': ['Jane Doe'],
  };

  final student = Student.fromJson(json);

  expect(student.firstName, 'John');
  expect(student.lastName, 'Doe');
  expect(student.gradeLevel, '5th');
});
```

### Documentation Template

**Add to Every Model Class:**
```dart
/// [ModelName] data model
///
/// Represents a [description] in the application.
///
/// **Serialization:**
/// - `toJson()`: Outputs snake_case for backend API compatibility
/// - `fromJson()`: Accepts both snake_case (backend) and camelCase (flexibility)
///
/// **Backend API Fields:**
/// - `first_name` (String): Student's first name
/// - `last_name` (String): Student's last name
/// - `grade_level` (String): Current grade level
/// - `created_at` (ISO 8601 DateTime): Record creation timestamp
///
class Student {
  // ...
}
```

---

| Use Case | Solution |
|----------|----------|
| **Development debugging** | Use IDE debugger (breakpoints, watches) or DevTools |
| **Development logging** | Use `developer.log()` (debug-only) or add conditional logging |
| **Error tracking** | Use logging framework (Firebase Crashlytics, Sentry) |
| **User notifications** | Use `ScaffoldMessenger.showSnackBar()` or dialogs |
| **Temporary testing** | Remove before committing (use IDE search to find) |

**Implementation:**

```dart
// ❌ BANNED: print() in production
void _loadUsers() {
  api.getUsers().then((users) {
    print('Users loaded: $users');  // ❌ DO NOT USE
    setState(() => this.users = users);
  });
}

// ✅ GOOD: Use debugPrint for development only
import 'package:flutter/foundation.dart';

void _loadUsers() {
  api.getUsers().then((users) {
    debugPrint('Users loaded: $users');  // Only prints in debug mode
    setState(() => this.users = users);
  });
}

// ✅ GOOD: Use developer.log for structured logging
import 'dart:developer' as developer;

void _loadUsers() {
  api.getUsers().then((users) {
    developer.log('Users loaded', name: 'app.services');  // Structured
    setState(() => this.users = users);
  });
}

// ✅ GOOD: Use error tracking for production errors
void _handleError(Object error, StackTrace stack) {
  // Send to Crashlytics or error tracking service
  FirebaseCrashlytics.instance.recordError(error, stack);
  
  // Show user-friendly message
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Something went wrong')),
  );
}

// ✅ GOOD: Conditional logging for development
void _logIfDebug(String message) {
  assert(() {
    print(message);  // Only executes in debug mode
    return true;
  }());
}
```

**Code Review Checklist:**
- [ ] Search for `print(` - all instances must be removed
- [ ] Search for `print ` - verify no print statements
- [ ] Use IDE "Find and Replace" to ensure zero print calls
- [ ] Exception: `debugPrint()` is acceptable for development

---

## 📱 Mobile-First Responsive Design

### Constraint-Based Layout

**Always:**
- Use `ConstrainedBox`, `SizedBox`, `Expanded`, `Flexible`
- Set maximum widths on containers (prevent unwieldy desktop layouts)
- Use `MediaQuery.of(context).size` sparingly

**Implementation:**
```dart
// ✅ GOOD: Constraint-based responsive
Center(
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: 600),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Content that scales nicely
        ],
      ),
    ),
  ),
)

// ❌ BAD: Hard-coded widths
SizedBox(
  width: 400,  // Doesn't adapt to screen size!
  child: widget,
)
```

### Orientation Handling

**Requirements:**
- Test on both portrait and landscape
- Hide/show content based on available space
- Use `MediaQuery.of(context).orientation`

**Implementation:**
```dart
// ✅ GOOD: Orientation-aware layout
OrientationBuilder(
  builder: (context, orientation) {
    final isTall = orientation == Orientation.portrait;
    return Column(
      children: [
        if (isTall) _buildHeader(),
        Expanded(child: _buildContent()),
      ],
    );
  },
)

// ✅ GOOD: Tablet layout detection
if (MediaQuery.of(context).size.width >= 600) {
  // Side-by-side layout for tablet
} else {
  // Stacked layout for phone
}
```

### ViewInsets & Keyboard

**Requirements:**
- Respect keyboard height (`MediaQuery.of(context).viewInsets.bottom`)
- Never hide important content behind keyboard
- Use `SingleChildScrollView` for forms

**Implementation:**
```dart
// ✅ GOOD: Accommodate keyboard
SingleChildScrollView(
  child: Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Form(
      child: Column(children: formFields),
    ),
  ),
)

// ❌ BAD: Content hidden by keyboard
Column(
  children: [
    TextFormField(),
    submitButton,  // Hidden behind keyboard!
  ],
)
```

---

## ⚡ Performance Optimization

### Build Performance

**Requirements:**
- Use `const` constructors everywhere possible
- Avoid `setState` when possible (use Riverpod)
- Don't rebuild large widget trees for small changes
- Profile with DevTools before optimizing

**Implementation:**
```dart
// ✅ GOOD: Const constructors
const SizedBox(height: 16)
const Padding(padding: EdgeInsets.all(8), child: Text('Hi'))

// ✅ GOOD: Selective rebuilding with Riverpod
@override
Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.watch(userProvider);  // Only rebuilds when user changes
  return Text(user.name);
}

// ❌ BAD: Forcing rebuilds
setState(() {
  // Rebuilds entire widget tree for one field change
})
```

### Memory Management

**Requirements:**
- Cancel timers and streams in `dispose()`
- Use `const` to reduce memory allocations
- Dispose of resources properly
- **CRITICAL:** Never hold references to `BuildContext` across async gaps (after `await`, delays, or callback returns)
- **LINT RULE:** `use_build_context_synchronously` - Don't use 'BuildContext's across async gaps. Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check.

**Why This Matters:**
When a widget is disposed, its context becomes invalid. Storing `BuildContext` and using it after an async operation (especially in callbacks) can cause crashes or memory leaks. Always read needed values before async operations or retrieve them after by using `mounted` check.

**Implementation:**
```dart
// ✅ GOOD: Extract needed values before async
Future<void> _fetchData() async {
  final savedContext = context;  // Read context BEFORE async
  final navigator = Navigator.of(savedContext);
  
  final data = await api.fetchData();  // Async operation
  
  // Safe to use savedContext after, but better to use mounted check
  if (mounted) {
    navigator.pop();
  }
}

// ✅ GOOD: Use mounted check after async operations
onPressed: () async {
  final result = await api.fetchData();
  
  // Check if widget still exists before using context
  if (!mounted) return;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Success: $result')),
  );
}

// ✅ GOOD: Use ref.read() instead for Riverpod providers
onPressed: () async {
  final service = ref.read(serviceProvider);  // Read before async
  final result = await service.fetchData();
  
  if (!mounted) return;
  // Safe to use context here
}

// ❌ BAD: Storing BuildContext across async gaps
Future<void> _fetchData() async {
  final result = await api.fetchData();
  // context is potentially invalid here!
  Navigator.of(context).pop();  // CRASH RISK
}

// ❌ BAD: Using context in async callbacks
onPressed: () {
  api.fetchDataAsync().then((result) {
    // context may be invalid by the time this executes
    ScaffoldMessenger.of(context).showSnackBar(...);
  });
}

// ❌ BAD: Resource leaks
StreamSubscription stream = api.listen((_) {});  // Never cancelled!
```

### Image Optimization

**Requirements:**
- Use appropriate image formats (JPEG for photos, PNG for graphics)
- Optimize before bundling (use ImageOptim, TinyPNG)
- Lazy load below-fold images
- Use caching

**Implementation:**
```dart
// ✅ GOOD: Cached images
Image.network(
  'https://example.com/photo.jpg',
  cacheHeight: 300,
  cacheWidth: 300,  // Cache at display size
)

// ✅ GOOD: Lazy loading
Visibility(
  visible: _isVisible,
  child: Image.asset('assets/below-fold-image.png'),
)
```

### Network Optimization

**Requirements:**
- Batch requests when possible
- Debounce rapid requests (search, filters)
- Show loading states
- Cache responses

**Implementation:**
```dart
// ✅ GOOD: Debounced search
Timer? _searchTimer;

void _onSearchChanged(String query) {
  _searchTimer?.cancel();
  _searchTimer = Timer(const Duration(milliseconds: 500), () {
    api.search(query);  // Called once after typing stops
  });
}

// ✅ GOOD: Loading state
if (isLoading) {
  return const Center(child: CircularProgressIndicator());
}
```

---

## ✅ Pre-Deployment Checklist

### Accessibility (WCAG 2.2 AA)
- [ ] All text 14px minimum (or 18px+ with 3:1 contrast)
- [ ] Color contrast 4.5:1 for normal text, 3:1 for large
- [ ] All interactive elements 48x48 dp minimum
- [ ] Focus indicators visible on all interactive elements
- [ ] Keyboard navigation works (Tab, Enter, Escape)
- [ ] All images have alt text
- [ ] Motion respects `disableAnimations` preference
- [ ] No flashing/flickering (>3 times/sec)
- [ ] Semantic structure proper (headers, lists, form labels)

### Visual Design
- [ ] Consistent spacing (using spacing scale)
- [ ] Consistent colors (no random hex values)
- [ ] No placeholder text without labels
- [ ] Error states visible and clear
- [ ] Loading states show progress
- [ ] Disabled states visually distinct
- [ ] Typography hierarchy clear

### Mobile-First
- [ ] Works on 320px width (iPhone SE)
- [ ] Works on 600px+ width (tablet)
- [ ] Tested portrait and landscape
- [ ] Keyboard doesn't hide important content
- [ ] Safe areas respected (notches)
- [ ] Touch targets minimum 48x48

### Performance
- [ ] Page loads in <3 seconds
- [ ] 60fps animations (use DevTools to check)
- [ ] No memory leaks (check DevTools Memory)
- [ ] Network requests optimized (batch, cache)
- [ ] Images optimized (<100kb each)
- [ ] `flutter analyze` returns 0 errors

### Code Quality
- [ ] No `dynamic` types
- [ ] No `// ignore` comments without reason
- [ ] All public APIs documented
- [ ] Error handling for all async operations
- [ ] Resources cleaned up in `dispose()`
- [ ] `dart format` applied
- [ ] No hardcoded strings (use constants or localization)

### Testing
- [ ] Works on Chrome, Safari, Firefox, Edge
- [ ] Tested on physical Android device
- [ ] Tested on physical iOS device (if applicable)
- [ ] All buttons/links clickable
- [ ] Forms submit correctly
- [ ] No console errors

---

## 📚 References & Resources

### Design References
- **New York Times Mobile App** https://www.nytimes.com/ - Reference implementation for mobile-first navigation, viewport management, and content layout
- **Material Design 3:** https://m3.material.io/
- **Material Design Spacing:** https://m3.material.io/foundations/layout/understanding-layout

### WCAG 2.2 AA Guidelines
- **Official:** https://www.w3.org/WAI/WCAG22/quickref/
- **Contrast Checker:** https://webaim.org/resources/contrastchecker/
- **Color Blindness Simulator:** https://www.color-blindness.com/

### Flutter & Dart
- **Flutter Docs:** https://flutter.dev/docs
- **Material Design 3:** https://m3.material.io/
- **Dart Style Guide:** https://dart.dev/guides/language/effective-dart/style
- **Riverpod:** https://riverpod.dev

### Performance & Testing
- **Flutter DevTools:** https://flutter.dev/docs/development/tools/devtools
- **Lighthouse:** https://developers.google.com/web/tools/lighthouse
- **WebAIM Accessibility Testing:** https://webaim.org/

### Design & UX
- **Mobile-First Design:** https://www.smashingmagazine.com/mobile-first-design
- **Material Design Spacing:** https://m3.material.io/foundations/layout/understanding-layout
- **Accessible Color Palettes:** https://coolors.co/

---

## 🔄 Standards Review Process

### Before Every Commit
1. Run `dart format`
2. Run `flutter analyze` (0 errors required)
3. Check WCAG 2.2 AA compliance (contrast, colors, touch targets)
4. Test on mobile device
5. Review against this standards file

### Code Review Checklist
- [ ] Follows naming conventions
- [ ] Proper error handling
- [ ] Type-safe (no dynamic)
- [ ] Documented (if public API)
- [ ] Resources cleaned up
- [ ] Accessibility verified
- [ ] Performance acceptable

### Post-Deployment
- Monitor error logs
- Gather user feedback on usability
- Track performance metrics
- Update standards based on learnings

---

**Last Review Date:** November 2, 2025
**Next Review Date:** December 2, 2025
**Maintainer:** Development Team
**Recent Updates:**
- Added Modern Flutter 3.7+ API Usage standard requiring all code use modern APIs with zero deprecated methods (Nov 4)
- Documented Color.withValues(alpha:) vs deprecated Color.withOpacity() replacement pattern (Nov 4)
- Updated core principles to include "Modern APIs Only" requirement (Nov 4)
- Expanded Flutter Best Practices section with widget composition, responsive design, state management, and navigation (Nov 2)
- Created comprehensive Riverpod State Management section with provider types, watching/reading, composition, error handling, lifecycle, and testing (Nov 2)
- Added Provider Types comparison table with use cases (Nov 2)
- Documented ConsumerStatefulWidget preference over StatefulWidget (Nov 2)
- Added Viewport & Container Management section (Nov 2)
- Documented gradient sizing best practices (Nov 2)
- Added New York Times mobile app as design reference (Nov 2)
