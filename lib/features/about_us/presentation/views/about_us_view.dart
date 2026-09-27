import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';

class AboutUsView extends StatelessWidget {
  const AboutUsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final rh = ResponsiveHelper.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final aboutUsTitle = l10n?.aboutUsTitle ?? 'ABOUT US';
    final backText = l10n?.back ?? 'Back';
    final whatMeansArtistTitle = l10n?.aboutWhatMeansArtistTitle ?? 'What does it mean to be an artist?';
    final whatMeansArtistBody = l10n?.aboutWhatMeansArtistBody ??
        'The word artist has a long history. It is rooted in the idea of art and originally described people with exceptional knowledge, skills and abilities. Today, an artist is someone who creates, interprets and gives expression to ideas, emotions and visions.\n\nBut we believe art can be more.';
    final quoteText = l10n?.aboutQuoteText ?? '“Art does not reproduce the visible; rather, it makes visible.”';
    final connectBody = l10n?.aboutConnectBody ??
        'Our platform was created to connect artists across disciplines, cultures, languages and levels of experience. From photography, painting and music to sculpture, digital art and many other creative forms, our platform gives artists a place to discover, share, connect and collaborate.';
    final opportunitiesBody = l10n?.aboutOpportunitiesBody ??
        'Artists can explore different forms of art, discover galleries and art associations, connect directly with them, showcase their work and take part in events, competitions and creative challenges. Most importantly, the platform creates opportunities for meaningful exchange, inspiration and collaboration.';
    final fusionBody = l10n?.aboutFusionBody ??
        'Because when different artists, cultures and creative perspectives come together, something new can emerge.\n\nPerhaps even a form of art that has never existed before.';
    final dubaiVisionBody = l10n?.aboutDubaiVisionBody ??
        'Dubai is a unique place for this vision. With people from more than 180 nationalities, countless cultures, languages and perspectives meet here. Art has the power to connect these differences and create something that belongs to everyone.\n\nOur digital world allows us to bring these creative forces together beyond borders and distances.';
    final ourVisionBody = l10n?.aboutOurVisionBody ??
        'Our vision is more than simply creating a platform for artists.\n\nWe want to create a space where encounters become inspiration, inspiration becomes collaboration, and collaboration becomes new art.';
    final closingBorders = l10n?.aboutClosingBorders ?? 'Because art has no borders.';
    final closingImpossible = l10n?.aboutClosingImpossible ??
        'And when people, ideas and talents come together, artists have the power to make the impossible possible.';

    return Scaffold(
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: rh.horizontalPadding,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Navigation Button (Simple & Clean)
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteNames.home);
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRtl ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            backText,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sober & Dignified Title
                  Text(
                    aboutUsTitle,
                    style: TextStyle(
                      fontSize: rh.adaptiveFont(24),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 1: "What does it mean to be an artist?"
                  Text(
                    whatMeansArtistTitle,
                    style: TextStyle(
                      fontSize: rh.adaptiveFont(18),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    whatMeansArtistBody,
                    style: TextStyle(
                      fontSize: rh.adaptiveFont(15),
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFE9DCF8),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sober Quote Callout with subtle accent line
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: isRtl
                            ? BorderSide.none
                            : const BorderSide(color: Color(0xFFFFD700), width: 3.5),
                        right: isRtl
                            ? const BorderSide(color: Color(0xFFFFD700), width: 3.5)
                            : BorderSide.none,
                      ),
                    ),
                    child: Text(
                      quoteText,
                      style: TextStyle(
                        fontSize: rh.adaptiveFont(16.5),
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 2: Platform Connection
                  Text(
                    connectBody,
                    style: TextStyle(
                      fontSize: rh.adaptiveFont(15),
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFE9DCF8),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section 3: Exploration & Opportunities
                  Text(
                    opportunitiesBody,
                    style: TextStyle(
                      fontSize: rh.adaptiveFont(15),
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFE9DCF8),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 4: Emergence & Perspective
                  Text(
                    fusionBody,
                    style: TextStyle(
                      fontSize: rh.adaptiveFont(15),
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 5: Dubai Context
                  Text(
                    dubaiVisionBody,
                    style: TextStyle(
                      fontSize: rh.adaptiveFont(15),
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFE9DCF8),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 6: Our Vision
                  Text(
                    ourVisionBody,
                    style: TextStyle(
                      fontSize: rh.adaptiveFont(15),
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFE9DCF8),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Subtle Divider
                  Divider(
                    color: Colors.white.withValues(alpha: 0.15),
                    thickness: 1,
                  ),
                  const SizedBox(height: 24),

                  // Closing Creed (Clean, impactful, sober)
                  Text(
                    closingBorders,
                    style: TextStyle(
                      fontSize: rh.adaptiveFont(17),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    closingImpossible,
                    style: TextStyle(
                      fontSize: rh.adaptiveFont(15),
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFE9DCF8),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }
}
