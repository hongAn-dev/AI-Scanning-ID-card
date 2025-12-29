# Hướng dẫn sử dụng Responsive Framework cho iPad

## Tổng quan
Ứng dụng đã được cấu hình để hỗ trợ responsive design cho iPad và các thiết bị khác nhau sử dụng thư viện `responsive_framework`.

## Cấu hình chính

### 1. Main App (main.dart)
```dart
builder: (context, child) {
  ScreenUtils.init(context);
  return ResponsiveBreakpoints.builder(
    breakpoints: [
      const Breakpoint(start: 0, end: 450, name: MOBILE),
      const Breakpoint(start: 451, end: 800, name: TABLET),
      const Breakpoint(start: 801, end: 1920, name: DESKTOP),
      const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
    ],
    child: ResponsiveWrapper.builder(
      ClampingWidthWrapper(
        maxWidth: 1200,
        child: child!,
      ),
      defaultScale: true,
      breakpoints: [
        const ResponsiveBreakpoint.resize(450, name: MOBILE),
        const ResponsiveBreakpoint.autoScale(800, name: TABLET),
        const ResponsiveBreakpoint.autoScale(1000, name: DESKTOP),
        const ResponsiveBreakpoint.autoScale(1200, name: 'XL'),
      ],
    ),
  );
}
```

### 2. ScreenUtils Helper
File `lib/utils/screen_utils.dart` cung cấp các helper functions:

#### Kiểm tra loại màn hình
```dart
ScreenUtils.isMobile(context)    // true nếu là mobile
ScreenUtils.isTablet(context)    // true nếu là tablet (iPad)
ScreenUtils.isDesktop(context)   // true nếu là desktop
```

#### Responsive values
```dart
// Padding tự động điều chỉnh
ScreenUtils.getResponsivePadding(context)

// Margin tự động điều chỉnh
ScreenUtils.getResponsiveMargin(context)

// Font size tự động điều chỉnh
ScreenUtils.getResponsiveFontSize(context, 16.0)

// Icon size tự động điều chỉnh
ScreenUtils.getResponsiveIconSize(context, 24.0)

// Số cột grid tự động điều chỉnh
ScreenUtils.getResponsiveColumns(context) // 1 cho mobile, 2 cho tablet, 3 cho desktop

// Spacing tự động điều chỉnh
ScreenUtils.getResponsiveSpacing(context, 16.0)

// Border radius tự động điều chỉnh
ScreenUtils.getResponsiveBorderRadius(context, 8.0)

// Button height tự động điều chỉnh
ScreenUtils.getResponsiveButtonHeight(context)

// Card width tự động điều chỉnh
ScreenUtils.getResponsiveCardWidth(context)
```

#### Responsive value selector
```dart
ScreenUtils.responsiveValue(
  context,
  mobile: 'Mobile Value',
  tablet: 'Tablet Value',
  desktop: 'Desktop Value',
)
```

## Sử dụng trong Widgets

### 1. ResponsiveContainer
```dart
ResponsiveContainer(
  child: Text('Nội dung'),
  // Padding và margin sẽ tự động điều chỉnh
)
```

### 2. ResponsiveText
```dart
ResponsiveText(
  'Tiêu đề',
  fontSize: 20.0, // Sẽ tự động scale cho tablet/desktop
  fontWeight: FontWeight.bold,
)
```

### 3. ResponsiveButton
```dart
ResponsiveButton(
  'Nhấn tôi',
  onPressed: () {},
  // Kích thước và padding sẽ tự động điều chỉnh
)
```

### 4. ResponsiveGrid
```dart
ResponsiveGrid(
  children: [
    // Các widget con
  ],
  // Số cột sẽ tự động: 1 cho mobile, 2 cho tablet, 3 cho desktop
)
```

### 5. ResponsiveCard
```dart
ResponsiveCard(
  child: Text('Nội dung card'),
  onTap: () {},
  // Kích thước và styling sẽ tự động điều chỉnh
)
```

## Ví dụ thực tế

### GridView responsive
```dart
GridView.builder(
  padding: ScreenUtils.getResponsivePadding(context),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: ScreenUtils.getResponsiveColumns(context),
    childAspectRatio: ScreenUtils.responsiveValue(
      context,
      mobile: 0.65,
      tablet: 0.7,
      desktop: 0.75,
    ),
    crossAxisSpacing: ScreenUtils.getResponsiveSpacing(context, 12),
    mainAxisSpacing: ScreenUtils.getResponsiveSpacing(context, 12),
  ),
  itemBuilder: (context, index) => ProductCard(),
)
```

### Layout responsive
```dart
Widget build(BuildContext context) {
  if (ScreenUtils.isTablet(context) || ScreenUtils.isDesktop(context)) {
    // Layout cho iPad/Desktop
    return Row(
      children: [
        // Sidebar
        Container(
          width: ScreenUtils.getResponsiveDrawerWidth(context),
          child: SidebarWidget(),
        ),
        // Main content
        Expanded(
          child: MainContentWidget(),
        ),
      ],
    );
  }
  
  // Layout cho Mobile
  return Column(
    children: [
      MainContentWidget(),
      BottomNavigationBar(),
    ],
  );
}
```

## Breakpoints

| Thiết bị | Kích thước | Breakpoint |
|----------|------------|------------|
| Mobile | 0 - 450px | MOBILE |
| Tablet (iPad) | 451 - 800px | TABLET |
| Desktop | 801 - 1920px | DESKTOP |
| 4K | 1921px+ | 4K |

## Lưu ý quan trọng

1. **Luôn khởi tạo ScreenUtils**: Gọi `ScreenUtils.init(context)` trong builder của MaterialApp
2. **Sử dụng responsive values**: Thay vì hardcode values, sử dụng các helper functions
3. **Test trên nhiều kích thước**: Kiểm tra trên mobile, tablet, và desktop
4. **Tối ưu cho iPad**: iPad sẽ sử dụng tablet breakpoint với autoScale
5. **Performance**: ResponsiveWrapper với ClampingWidthWrapper giúp tối ưu performance

## Tips cho iPad

- Sử dụng 2 cột cho grid trên iPad
- Tăng font size và icon size cho dễ đọc
- Sử dụng sidebar navigation thay vì bottom navigation
- Tăng padding và margin cho thoải mái hơn
- Sử dụng autoScale để tự động scale content
