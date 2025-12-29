import 'package:flutter/material.dart';

import '../../utils/screen_utils.dart';

/// Widget container responsive với padding và margin tự động
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? borderRadius;
  final BoxDecoration? decoration;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? ScreenUtils.getResponsivePadding(context),
      margin: margin ?? ScreenUtils.getResponsiveMargin(context),
      decoration: decoration ??
          BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
              borderRadius ?? ScreenUtils.getResponsiveBorderRadius(context, 8),
            ),
          ),
      child: child,
    );
  }
}

/// Text responsive với font size tự động điều chỉnh
class ResponsiveText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize != null
            ? ScreenUtils.getResponsiveFontSize(context, fontSize!)
            : null,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Button responsive với kích thước tự động điều chỉnh
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;
  final double? borderRadius;
  final Widget? icon;

  const ResponsiveButton(
    this.text, {
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.padding,
    this.borderRadius,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ScreenUtils.getResponsiveButtonHeight(context),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: ScreenUtils.getResponsiveSpacing(context, 16),
                vertical: ScreenUtils.getResponsiveSpacing(context, 8),
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              borderRadius ?? ScreenUtils.getResponsiveBorderRadius(context, 8),
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              SizedBox(width: ScreenUtils.getResponsiveSpacing(context, 8)),
            ],
            ResponsiveText(
              text,
              fontSize: fontSize ?? 16,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid responsive với số cột tự động điều chỉnh
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final double? runSpacing;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing,
    this.runSpacing,
    this.crossAxisCount,
    this.childAspectRatio,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final columns = crossAxisCount ?? ScreenUtils.getResponsiveColumns(context);
    final spacingValue =
        spacing ?? ScreenUtils.getResponsiveSpacing(context, 16);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: childAspectRatio ?? 1.0,
        crossAxisSpacing: crossAxisSpacing ?? spacingValue,
        mainAxisSpacing: mainAxisSpacing ?? spacingValue,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Card responsive với kích thước tự động điều chỉnh
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final double? borderRadius;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ScreenUtils.getResponsiveCardWidth(context),
      margin: margin ?? ScreenUtils.getResponsiveMargin(context),
      child: Card(
        color: color,
        elevation: elevation ?? 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            borderRadius ?? ScreenUtils.getResponsiveBorderRadius(context, 8),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            borderRadius ?? ScreenUtils.getResponsiveBorderRadius(context, 8),
          ),
          child: Padding(
            padding: padding ?? ScreenUtils.getResponsivePadding(context),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Responsive value selector widget
class ResponsiveValueBuilder<T> extends StatelessWidget {
  final T mobile;
  final T? tablet;
  final T? desktop;
  final Widget Function(BuildContext context, T value) builder;

  const ResponsiveValueBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final value = ScreenUtils.responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
    return builder(context, value);
  }
}
