import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh mục'),
        centerTitle: true,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveBreakpoints.of(context).isTablet ||
                  ResponsiveBreakpoints.of(context).isDesktop
              ? 3
              : 2,
          childAspectRatio: ResponsiveBreakpoints.of(context).isTablet ||
                  ResponsiveBreakpoints.of(context).isDesktop
              ? 1.2
              : 1.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          final categories = [
            {
              'title': 'Electronics',
              'icon': Icons.devices,
              'color': Colors.blue
            },
            {
              'title': 'Jewelery',
              'icon': Icons.diamond,
              'color': Colors.purple
            },
            {
              'title': "Men's Clothing",
              'icon': Icons.shopping_bag,
              'color': Colors.orange
            },
            {
              'title': "Women's Clothing",
              'icon': Icons.checkroom,
              'color': Colors.pink
            },
          ];
          final category = categories[index];
          return _buildCategoryCard(
            context,
            category['title'] as String,
            category['icon'] as IconData,
            category['color'] as Color,
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to category products
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected: $title')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: ResponsiveBreakpoints.of(context).isTablet ||
                        ResponsiveBreakpoints.of(context).isDesktop
                    ? 56
                    : 48,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveBreakpoints.of(context).isTablet ||
                        ResponsiveBreakpoints.of(context).isDesktop
                    ? 18
                    : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
