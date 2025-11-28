import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../core/theme/app_theme.dart';

class BannerSlider extends StatefulWidget {
  final List<String> bannerImages;
  final double? height;
  final Function(int index)? onBannerTap;

  const BannerSlider({
    super.key,
    required this.bannerImages,
    this.height,
    this.onBannerTap,
  });

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.bannerImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }

        final sliderHeight = widget.height ?? 300;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: sliderHeight,
              width: constraints.maxWidth,
              child: CarouselSlider.builder(
                itemCount: widget.bannerImages.length,
                itemBuilder: (context, index, realIndex) {
                  return Container(
                    width: constraints.maxWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (widget.onBannerTap != null) {
                              widget.onBannerTap!(index);
                            }
                          },
                          child: Image.asset(
                            widget.bannerImages[index],
                            fit: BoxFit.cover,
                            width: constraints.maxWidth,
                            height: sliderHeight,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback if image doesn't exist
                              return Container(
                                width: constraints.maxWidth,
                                height: sliderHeight,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.primaryColor,
                                      AppTheme.secondaryColor,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        size: 64,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Banner ${index + 1}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          'Add image: ${widget.bannerImages[index]}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.white70),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                  height: sliderHeight,
                  viewportFraction: 1.0,
                  autoPlay: widget.bannerImages.length > 1,
                  autoPlayInterval: const Duration(seconds: 4),
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enlargeCenterPage: false,
                  enableInfiniteScroll: widget.bannerImages.length > 1,
                  onPageChanged: (index, reason) {
                    if (mounted) {
                      setState(() {
                        _currentIndex = index;
                      });
                    }
                  },
                ),
              ),
            ),
            if (widget.bannerImages.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.bannerImages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentIndex == index
                          ? AppTheme.primaryColor
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
