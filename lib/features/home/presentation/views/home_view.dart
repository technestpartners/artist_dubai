import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/models/menu_card_item.dart';
import '../widgets/home_footer_widget.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/menu_card_widget.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  final List<MenuCardItem> _items = MenuCardItem.items;

  void _onCardTap(BuildContext context, MenuCardItem item) {
    context.push(item.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6B1C9B), // Top vibrant purple
              Color(0xFF58209B), // Mid royal purple
              Color(0xFF4D249E), // Bottom rich purple
            ],
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = rh.horizontalPadding;
              final gap = (constraints.maxHeight * 0.014).clamp(8.0, 16.0);

              // Tablet/Desktop: 2 rows × 4 cols  |  Mobile: 4 rows × 2 cols
              final rowCount = rh.isWide ? 2 : 4;
              final colCount = rh.isWide ? 4 : 2;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Header
                  const HomeHeaderWidget(),
                  SizedBox(height: gap * 0.5),

                  // 2. Adaptive Grid — centred on wide screens
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: _buildGrid(context, rowCount, colCount, gap),
                        ),
                      ),
                    ),
                  ),

                  // 3. Bottom Footer
                  const HomeFooterWidget(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    int rowCount,
    int colCount,
    double gap,
  ) {
    return Column(
      children: [
        for (int row = 0; row < rowCount; row++) ...[
          Expanded(
            child: Row(
              children: [
                for (int col = 0; col < colCount; col++) ...[
                  if (col > 0) SizedBox(width: gap),
                  Expanded(
                    child: _buildCard(context, row * colCount + col),
                  ),
                ],
              ],
            ),
          ),
          if (row < rowCount - 1) SizedBox(height: gap),
        ],
      ],
    );
  }

  Widget _buildCard(BuildContext context, int idx) {
    if (idx >= _items.length) return const SizedBox.expand();
    return MenuCardWidget(
      item: _items[idx],
      onTap: () => _onCardTap(context, _items[idx]),
    );
  }
}
