# Mobile App Design Rules

## Scope

These rules apply ONLY to the Flutter mobile application.

Do not apply these rules to:
- Angular web application
- Node.js backend
- Backend APIs
- Database code
- Server-side code

This file is the single source of truth for the Flutter mobile application's UI/UX and visual design.

Before creating, modifying, refactoring, or reviewing any Flutter UI code, read and follow this file completely.

---

# Design Philosophy

Create a modern, clean, premium and human-friendly mobile UI.

The app should feel trustworthy, premium, and easy to use on a daily basis. All screens should balance clarity, comfort, and visual consistency across both light and dark mode.

The product should feel professional, friendly, minimal, and reliable with subtle depth and polished interaction states.

---

## Core Visual Direction

- Use a premium mobile-first aesthetic with soft surfaces, strong hierarchy, and balanced spacing.
- Prioritize readability and touch-friendly interactions.
- Keep the interface clean and minimal without feeling empty or cold.
- Use color intentionally to guide attention, not to create visual noise.
- Maintain consistency across all screens, cards, buttons, inputs, dialogs, and sheets.
- Favor clarity and trust over flashy visual effects.

---

## Brand Theme

### Primary Brand Feel
- Premium technology brand
- Clean and confident
- Trustworthy and modern
- High contrast text with muted backgrounds
- Refined, calm, and polished interactions

### Recommended Brand Personality
- Professional
- Friendly
- Minimal but expressive
- Reliable and high-quality

---

## Color System

Use a centralized token-based palette so future screens and components stay consistent.

### Light Mode Palette

- Primary: #16A34A
- Brand Accent: #A3E635
- Background: #F7F8F3
- Surface: #FFFFFF
- Text: #102A2A
- Secondary Text: #64748B
- Border: #E2E8E5

### Dark Mode Palette

- Primary: #4ADE80
- Brand Accent: #BEF264
- Background: #0B1210
- Surface: #121C18
- Text: #F1F5F3
- Secondary Text: #A7B5AE
- Border: #26352E

### Additional Semantic Colors

- Received: Green
- Given: Amber
- Success: Green
- Warning: Yellow
- Error: Red
- Info: Blue

### Color Usage Rules

- Use green for success and positive status.
- Use amber for negative/paid/given-related emphasis where applicable.
- Use blue as a supporting brand or accent color when needed.
- Use red only for destructive actions or critical errors.
- Keep backgrounds soft and low-contrast; avoid harsh blacks or overly saturated tones.
- Preserve accessible contrast ratios for all text and interactive elements.
- Do not use bright lime as normal body text.
- Do not use white text on bright lime unless contrast has been intentionally verified.
- Do not use pure black as the complete dark-mode background.
- Do not introduce arbitrary colors outside the approved system.

---

## Typography

### Font Family

Use:
- English: Manrope
- Tamil: Noto Sans Tamil

Do not introduce another font unless explicitly requested.

### Type Scale

- Heading XL: 32 / 700
- Heading L: 28 / 700
- Heading M: 24 / 700
- Heading S: 20 / 600
- Title: 18 / 600
- Body Large: 16 / 500
- Body Regular: 14 / 400
- Label: 12 / 500
- Caption: 11 / 400

### Text Rules

- Use strong weight for headings and important labels.
- Keep body text readable with comfortable line height.
- Use medium or semibold for interactive text and field labels.
- Do not overuse uppercase; reserve for short labels and status chips only.
- Support both English and Tamil text length properly.
- Do not truncate important Tamil text.
- Avoid fixed-height text containers when localization requires more vertical space.

---

## Spacing System

Use the spacing system consistently.

Preferred values:
- 4
- 8
- 12
- 16
- 20
- 24
- 32
- 40
- 48

Avoid random values such as 7, 13, 17, 19, 23, 27, 31 unless there is a specific layout need.

Default screen horizontal padding:
- 24dp

Compact layouts may use:
- 16dp

---

## Button Design System

Button styling must remain consistent across all screens and actions.

### Border Radius Scale

All buttons must use a 5px border radius.

Required button radius:
- Button radius: 5dp
- Input radius: 16dp
- Card radius: 20dp
- Dialog radius: 24dp
- Bottom sheet radius: 28dp
- Chip radius: 999dp

### Light Mode Button Styling

Light mode primary buttons must use:
- Background: #16A34A
- Text: #FFFFFF
- Border radius: 5dp
- Height: 52dp

Secondary and tertiary light mode buttons should remain minimal and readable, but all standard buttons still use a 5dp radius.

### Dark Mode Button Styling

Dark mode button styling remains as currently defined and does not require any change.

### Button Styling Rules

- All standard buttons must use a 5dp radius.
- Light mode primary buttons must use green background with white text.
- Dark mode keeps the current design and should not be altered.
- Buttons should support default, pressed, disabled, loading, and focused states.
- Loading should not change overall size or cause layout jumping.
- Do not create random button designs for individual screens.
- Do not use a larger radius for buttons unless specifically approved for a rare non-standard case.

---

## Light Mode Design Standards

- Backgrounds should be airy and clean, with soft white or off-white surfaces.
- Cards should stand out with subtle borders and shadow.
- Text should be dark and high contrast for easy reading.
- Use green as the main success and positive signal.
- Keep surfaces light enough to feel premium and calm.
- Use soft, low-opacity shadows and minimal elevation.

### Example Light Theme Tokens

- App background: #F7F8F3
- Card surface: #FFFFFF
- Primary CTA: #16A34A
- Primary CTA Text: #FFFFFF
- Brand accent: #A3E635
- Primary text: #102A2A
- Secondary text: #64748B
- Border: #E2E8E5

---

## Dark Mode Design Standards

- Use deeper but soft backgrounds with layered surfaces instead of pure black.
- Maintain a premium dark theme with high readability and calm contrast.
- Use brighter green accents for key actions in dark mode.
- Keep text high-contrast and comfortable to read.
- Limit overly saturated colors to small highlights and status states.
- Prefer surface contrast and borders over heavy shadows.

### Example Dark Theme Tokens

- App background: #0B1210
- Card surface: #121C18
- Primary CTA: #4ADE80
- Brand accent: #BEF264
- Primary text: #F1F5F3
- Secondary text: #A7B5AE
- Border: #26352E

---

## Received vs Given

Moi Received and Moi Given must remain visually distinguishable.

Use:
- Received → Green
- Given → Amber

Do not represent these states using color alone.

Also use appropriate:
- Icons
- Labels
- Direction indicators
- Semantic text

This ensures the user understands the difference even without relying on color.

---

## Layout and Interaction Guidance

- Use rounded corners and soft shadows to create a premium mobile feel.
- Keep cards and containers consistent in shape and spacing.
- Preserve enough white space to avoid visual clutter.
- Favor clean surfaces over heavy ornamentation.
- Maintain consistent radius and elevation rules across all design components.
- Ensure responsive behavior across small phones, normal phones, large phones, and tablets.

---

## Theme Architecture

Maintain centralized theme management.

Prefer:
- lib/core/theme/app_theme.dart
- lib/core/theme/app_colors.dart
- lib/core/theme/app_typography.dart
- lib/core/theme/app_spacing.dart
- lib/core/theme/app_radius.dart
- lib/core/theme/app_shadows.dart

Use:
- AppTheme.light()
- AppTheme.dark()

Do not create screen-specific theme systems.
Do not hardcode colors inside individual screens.
Do not create a separate color palette for a single screen.

---

## Never Invent Design Tokens

Do NOT introduce arbitrary:
- Colors
- Font families
- Font sizes
- Font weights
- Border radii
- Shadows
- Gradients
- Spacing values
- Button styles
- Input styles
- Icon styles

Use the existing design system.

Bad:

```dart
Container(
  color: const Color(0xFF123456),
  borderRadius: BorderRadius.circular(13),
)
```

Good:

```dart
Container(
  color: Theme.of(context).colorScheme.surface,
  borderRadius: AppRadius.card,
)
```

If a required design token does not exist, first check whether an existing semantic token can be reused.
Only introduce a new token when there is a genuine design-system requirement.

---

## 40.1 Before Making UI Changes

Before modifying any Flutter screen:

1. Read design.md.
2. Inspect the existing screen and related reusable components.
3. Check the existing theme implementation.
4. Reuse existing components whenever possible.
5. Reuse existing design tokens.
6. Check both Light Mode and Dark Mode.
7. Check English and Tamil text compatibility when the screen contains user-facing text.
8. Preserve existing business logic unless the user explicitly asks to change it.
9. Do not immediately create new widgets or styles without checking the existing project structure.

---

## 40.2 Component Reuse

Before creating a new component, search the project for an existing equivalent.

Prefer reusable components such as:
- AppButton
- AppCard
- AppTextField
- AppSearchField
- AppSectionHeader
- AppListTile
- AppAmountText
- AppDialog
- AppBottomSheet
- AppLoading
- AppErrorState
- AppEmptyState
- AppSkeleton
- AppChip
- AppIconButton

If an equivalent component already exists, extend or reuse it instead of creating a duplicate.

Avoid duplicate widgets such as:
- TransactionCard
- TransactionCardNew
- TransactionCardModern
- TransactionCardUpdated
- TransactionCardV2

when one reusable component can serve the purpose.

---

## 40.3 Forms and Inputs

Use the standard input system.

Default:
- Height: 56–60dp
- Radius: 16dp

Inputs must provide clear:
- Label
- Placeholder
- Focus
- Error
- Disabled
- Validation

Use appropriate keyboard types for:
- Name
- Phone
- Email
- Amount
- Date
- Search
- Password

Do not use a generic keyboard configuration when a specialized keyboard is available.

---

## 40.4 Buttons

All standard buttons must follow the existing button system.

Default:
- Height: 52dp
- Radius: 16dp

Every interactive button should support:
- Default
- Pressed
- Disabled
- Loading
- Focused

Loading must not change the button's overall size or cause layout jumping.

Do not create random button designs for individual screens.

---

## 40.5 Lists and Large Data

For large collections:
- Use ListView.builder
- Use SliverList where appropriate
- Avoid rendering unnecessary widgets
- Avoid loading the entire dataset into the widget tree
- Use lazy loading/pagination where supported by the API
- Preserve smooth scrolling
- Avoid expensive rebuilds

Default pagination should prefer approximately:
- 30 records per request

when compatible with the existing backend API.

Load additional data progressively rather than blocking the entire screen.

---

## 40.6 Loading States

Do not leave blank screens while waiting for APIs.

Use appropriate:
- Skeleton
- Progress indicator
- Loading placeholder
- Pagination loader

For initial loading:
- Show meaningful skeleton/loading UI.

For loading more:
- Keep existing content visible.
- Show a small bottom loading indicator.

Do not replace an already-loaded list with a full-screen loader when fetching the next page.

---

## 40.7 Empty States

Every list-based screen should have a meaningful empty state.

Use:
- Illustration or icon
- Title
- Short explanation
- Primary action
- Optional secondary action

Example structure:

```
No transactions yet

Start recording your first Moi transaction.

[Add Transaction]
```

Do not create different empty-state designs for every screen.
Reuse the project's empty-state component.

---

## 40.8 Error States

API or data errors must be presented clearly.

Use:
- Icon
- Short title
- Human-readable explanation
- Retry action

Avoid exposing raw:
- Exception
- Stack trace
- HTTP response
- JSON
- Backend error

to normal users.

---

## 40.9 Performance

UI code must be performance-conscious.

Avoid:
- Unnecessary widget rebuilds
- Heavy operations inside build()
- Large synchronous computations on the UI thread
- Unnecessary animations
- Excessive blur effects
- Large image rendering without optimization
- Rendering hundreds of list items simultaneously
- Repeated API calls caused by widget rebuilds
- Unnecessary database queries during rebuilds

Prefer:
- const widgets
- Lazy lists
- Pagination
- Memoization where appropriate
- Selective rebuilds
- Efficient state management
- Cached data where appropriate

Do not introduce an architectural change unless it is required.

---

## 40.10 API and Business Logic Separation

UI widgets should not contain unnecessary:
- API calls
- Database operations
- Business calculations
- Large data transformations

Prefer the project's existing architecture:
- Repository
- Service
- Provider
- Controller
- Bloc
- Cubit
- ViewModel

Follow the architecture already present in the project.
Do not introduce a completely different state-management pattern for one screen.

---

## 40.11 Responsive Design

The UI must work on:
- Small Android phones
- Normal Android phones
- Large Android phones
- Tablet where applicable

Avoid fixed screen widths.

Prefer:
- Expanded
- Flexible
- LayoutBuilder
- ConstrainedBox
- MediaQuery
- SafeArea

Do not depend on hardcoded screen dimensions.

Always consider:
- Long names
- Large amounts
- Tamil text
- Dynamic text scaling
- Different screen sizes
- Keyboard visibility
- Safe areas

---

## 40.12 Accessibility

Every UI implementation must consider:
- Minimum 44x44dp touch targets
- Readable text
- Sufficient contrast
- Dynamic font scaling
- Semantic labels
- Screen readers
- Color-independent status communication

Do not rely only on color to communicate important information.

---

## 40.13 Icons

Use one consistent icon family throughout the app.

Prefer the existing icon library used by the project.

Do not mix:
- Material
- FontAwesome
- Lucide
- Phosphor
- Custom icons

randomly.

Default sizes:
- Small: 20dp
- Normal: 24dp
- Large: 28–32dp

Use semantic icon meanings consistently.

---

## 40.14 Animations

Animations should be subtle and purposeful.

Prefer:
- 100–150ms for button interaction
- 150–200ms for card interaction
- 250–300ms for page transition
- 250–350ms for bottom sheet

Prefer:
- Curves.easeOutCubic

Avoid:
- Excessive bouncing
- Continuous animations
- Large scaling
- Distracting transitions
- Animations that delay user interaction

---

## 40.15 Shadows and Elevation

Use minimal shadows.

In light mode:
- Soft shadow
- Low opacity
- Small elevation

In dark mode:
- Prefer surface contrast and border

Avoid:
- Heavy black shadows
- Large glow
- Neon glow

Do not add shadows to every card.

---

## 40.16 Images and Assets

Before adding a new image or illustration:

1. Check whether an existing asset can be reused.
2. Follow the established Moi Kanakku visual identity.
3. Avoid generic stock-style illustrations.
4. Optimize large images.
5. Support appropriate dark/light variants when required.

The logo may be more vivid and 3D than normal UI components.

---

## 40.17 UI Text

User-facing text should be:
- Short
- Clear
- Friendly
- Human
- Professional

Avoid technical wording.

Bad:

```
API request failed with status code 500
```

Good:

```
Something went wrong.
Please try again.
```

Do not unnecessarily change existing business terminology.

---

## 40.18 Tamil / Localization

The application must support English and Tamil.

Do not assume English text length.

Tamil text can occupy more vertical space.

Therefore:
- Avoid fixed-height text containers where possible.
- Allow text wrapping.
- Test buttons with Tamil labels.
- Test cards with Tamil content.
- Test dialogs with Tamil content.
- Do not truncate important Tamil text.

Use:
- Manrope → English
- Noto Sans Tamil → Tamil

---

## 40.19 Do Not Break Existing Functionality

When asked to improve UI:

Do not modify business logic unless explicitly requested.

Preserve:
- API contracts
- Models
- Database logic
- Authentication
- Navigation behavior
- Validation
- Existing functionality
- State management
- Backend integration

UI refactoring should not accidentally change application behavior.

---

## 40.20 Before Creating New Files

Before creating a new:
- Widget
- Component
- Theme
- Utility
- Service
- Controller
- Provider

search the project first.

If an existing implementation can be reused or extended, prefer that approach.

Avoid duplicate functionality.

---

## 40.21 Before Completing Any UI Task

Perform this checklist:

- [ ] Read design.md
- [ ] Reused existing components
- [ ] No random colors
- [ ] No random fonts
- [ ] No random border radii
- [ ] No unnecessary shadows
- [ ] Light mode checked
- [ ] Dark mode checked
- [ ] Tamil text considered
- [ ] Small screen considered
- [ ] Large screen considered
- [ ] Accessibility considered
- [ ] Loading state considered
- [ ] Empty state considered
- [ ] Error state considered
- [ ] API/business logic preserved
- [ ] Performance considered
- [ ] No unnecessary duplicate widgets
- [ ] No unnecessary architecture changes

---

## 40.22 AI Behavior

When working on Flutter UI:

DO:
- Read design.md first.
- Inspect existing code before changing it.
- Reuse components.
- Reuse theme tokens.
- Keep the UI consistent.
- Keep Light and Dark modes intentional.
- Preserve business logic.
- Keep code maintainable.
- Prefer simple solutions.
- Explain significant architectural changes before making them.

DO NOT:
- Invent new colors.
- Invent new fonts.
- Invent random spacing.
- Invent random radii.
- Create a new design language.
- Redesign unrelated screens.
- Change APIs without permission.
- Change backend code for a UI request.
- Change business logic unnecessarily.
- Add dependencies unnecessarily.
- Replace the existing architecture without a clear reason.
- Create duplicate reusable components.

---

## 40.23 Final Instruction to VS Code Copilot

Before generating or modifying Flutter UI code, treat this document as the project's design contract.

If existing code conflicts with this document:

1. Preserve application functionality.
2. Follow this design system for new UI.
3. Reuse existing architecture.
4. Refactor only what is necessary.
5. Do not introduce unrelated changes.

When the user asks for a UI improvement, improve the visual design within this design system rather than creating a completely different visual style.

Always produce production-quality Flutter code that is:
- Modern
- Clean
- Premium
- Accessible
- Responsive
- Performant
- Reusable
- Theme-aware
- Localization-friendly
- Consistent with Moi Kanakku

---

## Future Usage Rule

This file is the source of truth for app theme design in the Flutter mobile project.

When creating new screens, components, forms, bottom sheets, dialogs, or buttons:
- follow the defined light and dark mode palette
- use the assigned typography scale
- apply the button radius system consistently
- keep the visual language premium, clean, and user-friendly
- do not introduce ad-hoc colors, font styles, or border radii outside this system unless approved

This ensures the overall mobile app remains cohesive and scalable as new features are added.

---

## Summary

The app theme should feel modern, polished, and human-centered:
- premium green-based identity for Moi financial flows
- clean neutral backgrounds
- strong typography hierarchy
- soft rounded buttons with consistent radii
- consistent light and dark mode support for all future development
- localization-ready, accessible, and performance-conscious UI implementation

## 40.28 Reusable Widget Creation & Reuse

Before creating UI code, always check whether the required UI pattern already exists.

### Reuse First

If an existing reusable widget can satisfy the requirement:

* Reuse it.
* Configure it using parameters.
* Do not duplicate its UI implementation.
* Do not create another widget with the same responsibility.

### Create Reusable Widgets When Appropriate

If a UI pattern is likely to be used on multiple screens, **create a reusable widget instead of implementing the same UI directly inside each screen**.

Examples:

```text
AppButton
AppCard
AppTextField
AppSearchField
AppAmountText
AppSectionHeader
AppListTile
AppIconButton
AppChip
AppDialog
AppBottomSheet
AppLoading
AppSkeleton
AppEmptyState
AppErrorState
AppConfirmationDialog
AppDatePicker
AppDropdown
```

Reusable widgets should be:

* Generic enough to reuse
* Configurable through parameters
* Theme-aware
* Light/Dark mode compatible
* Localization-friendly
* Accessible
* Responsive
* Easy to maintain

### Example

Do NOT repeatedly create:

```dart
Container(
  height: 52,
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.primary,
    borderRadius: BorderRadius.circular(16),
  ),
  child: ...
)
```

on multiple screens.

Create a reusable:

```dart
AppButton(
  title: 'Save',
  onPressed: saveTransaction,
)
```

and use the same component throughout the application.

### Avoid Over-Abstraction

Do not create a reusable widget for every tiny piece of UI.

Create a reusable widget when:

1. The UI is used more than once, or
2. The UI represents an important common design pattern, or
3. Centralizing it improves consistency and maintainability.

Keep truly screen-specific UI inside the screen when creating a reusable component would add unnecessary complexity.

### Reusable Widget Location

Prefer organizing shared widgets under:

```text
lib/
  core/
    widgets/
```

or the project's existing shared-widget structure.

Example:

```text
lib/
  core/
    widgets/
      app_button.dart
      app_card.dart
      app_text_field.dart
      app_empty_state.dart
      app_error_state.dart
      app_loading.dart
```

Feature-specific reusable widgets may remain inside their feature folder when they are not appropriate for global reuse.

### Mandatory AI Rule

When implementing a new UI:

**First search for an existing reusable widget.**

If one exists → **reuse it.**

If one does not exist and the UI pattern is reusable → **create a reusable widget and use it.**

Do not duplicate the same UI implementation across multiple screens.

Before creating a new widget, search the project for similar widgets and avoid creating duplicates.
