import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/models/menu_card_item.dart';
import '../widgets/home_footer_widget.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/menu_card_widget.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  final List<MenuCardItem> _items = MenuCardItem.items;

  void _onCardTap(BuildContext context, MenuCardItem item) {
    if (item.routeName == '/artist-registration') {
      final isLoggedIn = sl<StorageService>().getBool('is_logged_in') ?? false;
      if (!isLoggedIn) {
        context.push(RouteNames.login);
        return;
      }
    }
    context.push(item.routeName);
  }

  @override
  Widget build(BuildContext context) {
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
              Color(0xFF55209D), // Upper middle purple
              Color(0xFF431A94), // Center deep royal purple
              Color(0xFF36188E), // Lower middle indigo
              Color(0xFF4D229E), // Bottom luminous purple
            ],
            stops: [0.0, 0.25, 0.55, 0.80, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = (constraints.maxWidth * 0.04).clamp(12.0, 20.0);
              final gap = (constraints.maxHeight * 0.014).clamp(8.0, 14.0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Auto-scaling Top Header
                  const HomeHeaderWidget(),
                  SizedBox(height: gap * 0.5),

                  // 2. Auto-fitting 4-Row Grid (Takes exactly available height with 0 scroll)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        children: [
                          // Row 1: About Us, Artists
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: MenuCardWidget(
                                    item: _items[0],
                                    onTap: () => _onCardTap(context, _items[0]),
                                  ),
                                ),
                                SizedBox(width: gap),
                                Expanded(
                                  child: MenuCardWidget(
                                    item: _items[1],
                                    onTap: () => _onCardTap(context, _items[1]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: gap),

                          // Row 2: Government, Artist Registration
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: MenuCardWidget(
                                    item: _items[2],
                                    onTap: () => _onCardTap(context, _items[2]),
                                  ),
                                ),
                                SizedBox(width: gap),
                                Expanded(
                                  child: MenuCardWidget(
                                    item: _items[3],
                                    onTap: () => _onCardTap(context, _items[3]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: gap),

                          // Row 3: Events Competition, Galleries Art Center
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: MenuCardWidget(
                                    item: _items[4],
                                    onTap: () => _onCardTap(context, _items[4]),
                                  ),
                                ),
                                SizedBox(width: gap),
                                Expanded(
                                  child: MenuCardWidget(
                                    item: _items[5],
                                    onTap: () => _onCardTap(context, _items[5]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: gap),

                          // Row 4: Events Photos, Galleries Registration
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: MenuCardWidget(
                                    item: _items[6],
                                    onTap: () => _onCardTap(context, _items[6]),
                                  ),
                                ),
                                SizedBox(width: gap),
                                Expanded(
                                  child: MenuCardWidget(
                                    item: _items[7],
                                    onTap: () => _onCardTap(context, _items[7]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Auto-scaling Bottom Footer
                  const HomeFooterWidget(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
