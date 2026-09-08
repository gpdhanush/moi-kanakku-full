import 'package:flutter/material.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class PromotionPage extends StatefulWidget {
  const PromotionPage({super.key});

  @override
  State<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<Map<String, String>> testimonials = [
    {
      'text':
          '"எங்கள் ஊரில் 50 வருட பழைய மொய் நோட்டுகள் எல்லாம் இந்த சேவை மூலம் டிஜிட்டல் ஆக்கினோம்."',
      'author': 'திருவண்ணாமலை மொய் குழு',
      'location': 'திருவண்ணாமலை, தமிழ்நாடு',
    },
    {
      'text':
          '"மிகவும் நம்பகமான சேவை. எங்கள் அனைத்து ஆவணங்களும் பாதுகாப்பாக இருக்கின்றன."',
      'author': 'ராமாநுஜன் சாமி',
      'location': 'சேலம் மொய் பொறுமையாளர்',
    },
    {
      'text':
          '"இந்த டிஜிட்டல் சேவை நமக்கு பெரிய உதவி. எப்போது வேண்டுமானாலும் பயன்படுத்த முடிகிறது."',
      'author': 'கோவை மொய் நிர்வாகம்',
      'location': 'கோவை, தமிழ்நாடு',
    },
    {
      'text':
          '"செலவு மிகக் குறைவு ஆனால் தரம் மிக அதிகம். பரிந்துரை செய்கிறேன்!"',
      'author': 'தேவதாள்',
      'location': 'மதுரை சமூக சேவை',
    },
    {
      'text':
          '"தகவல் பாதுகாப்பு, வேகமான சேவை, அவசர கால ஆவணங்களுக்கு சிறந்த தீர்வு."',
      'author': 'நாராயணன் அய்யர்',
      'location': 'விருத்தாச்சலம், தமிழ்நாடு',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      // ensure controller is attached to a PageView before using it
      if (_pageController.hasClients) {
        try {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } catch (_) {
          // sometimes page is null if view not yet built; ignore
        }
      }
      _startAutoScroll();
    });
  }

  void _contactUs() {
    Navigator.pushNamed(context, 'contact_us');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBarWidget(
        title: context.read<LanguageProvider>().tr('promotion.title'),
        action: [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 1.0),

            // Features List
            _buildFeaturesList(colorScheme),
            const SizedBox(height: 16),
            // Price Section
            _buildPriceSection(colorScheme),
            const SizedBox(height: 25),

            // Testimonial Carousel
            _buildTestimonialCarousel(colorScheme),
            const SizedBox(height: 25),
            // Coverage Info (moved before button)
            _buildCoverageInfo(colorScheme),
            const SizedBox(height: 5),
            // CTA Button
            _buildCTAButton(colorScheme, size),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.7),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Service Label
          Text(
            context.read<LanguageProvider>().tr('promotion.serviceFee'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          // Price Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Original Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '₹2,999',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontFamily: 'amountFont',
                        ),
                      ),
                      CustomPaint(
                        size: const Size(72, 40),
                        painter: RedXPainter(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      context.read<LanguageProvider>().tr('promotion.discount'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.green[700],
                        fontFamily: 'amountFont',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Arrow
              Icon(
                Icons.arrow_forward_outlined,
                color: colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 20),
              // Offer Price
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'amountFont',
                      ),
                    ),
                    Text(
                      '999',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'amountFont',
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Savings Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              context.read<LanguageProvider>().tr('promotion.savings'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(ColorScheme colorScheme) {
    final features = [
      {
        'icon': Icons.document_scanner,
        'text': context.read<LanguageProvider>().tr(
          'promotion.featureDigitize',
        ),
      },
      {
        'icon': Icons.sort_by_alpha,
        'text': context.read<LanguageProvider>().tr(
          'promotion.featureOrganize',
        ),
      },
      {
        'icon': Icons.security,
        'text': context.read<LanguageProvider>().tr('promotion.featureSecure'),
      },
      {
        'icon': Icons.visibility,
        'text': context.read<LanguageProvider>().tr('promotion.featureAccess'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.read<LanguageProvider>().tr('promotion.featuresTitle'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    feature['text'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCTAButton(ColorScheme colorScheme, Size size) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: AppButton(
        title: context.read<LanguageProvider>().tr('promotion.contactNow'),
        onPressed: _contactUs,
      ),
      // child: Material(
      //   color: Colors.transparent,
      //   child: InkWell(
      //     onTap: _contactUs,
      //     borderRadius: BorderRadius.circular(16),
      //     child: Row(
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       children: [
      //         Icon(Icons.contact_phone, color: Colors.white, size: 20),
      //         const SizedBox(width: 10),
      //         Text(
      //           'இப்போது தொடர்பு கொள்ளுங்கள்',
      //           style: TextStyle(
      //             fontSize: 16,
      //             fontWeight: FontWeight.w900,
      //             color: Colors.white,
      //
      //             letterSpacing: 0.5,
      //           ),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }

  Widget _buildCoverageInfo(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.location_on, color: colorScheme.primary, size: 14),
        const SizedBox(width: 4),
        Text(
          context.read<LanguageProvider>().tr('promotion.coverage'),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonialCarousel(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.read<LanguageProvider>().tr('promotion.testimonialsTitle'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: PageController(
              initialPage: testimonials.length * 50,
              viewportFraction: 0.9,
            ),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index % testimonials.length;
              });
            },
            itemBuilder: (context, index) {
              final actualIndex = index % testimonials.length;
              final testimonial = testimonials[actualIndex];

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: Colors.amber.shade200, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_outlined,
                      color: colorScheme.primary.withAlpha(153),
                      size: 22,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        testimonial['text']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                          //
                        ),
                      ),
                    ),
                    // const SizedBox(height: 12),
                    // Row(
                    //   children: List.generate(
                    //     5,
                    //     (i) => Icon(
                    //       Icons.star_outlined,
                    //       color: Colors.amber[700],
                    //       size: 16,
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 10),
                    Text(
                      testimonial['author']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      testimonial['location']!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              testimonials.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _currentPage == index ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? colorScheme.primary
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RedXPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Draw diagonal line from top-left to bottom-right
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.8),
      paint,
    );

    // Draw diagonal line from top-right to bottom-left
    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.2, size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
