import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnimatedRingChart extends StatefulWidget {
  final double percentage;
  final String title;
  final String centerText;
  final Color primaryColor;
  final Color? bgColor;
  final String? metric;
  final String? subInfo;
  final String? badgeText;
  final Color? badgeColor;
  final IconData? icon;
  final double chartSize;
  final bool isExpanded;
  final VoidCallback? onTap;

  const AnimatedRingChart({
    super.key,
    required this.percentage,
    required this.title,
    required this.centerText,
    required this.primaryColor,
    this.bgColor,
    this.metric,
    this.subInfo,
    this.badgeText,
    this.badgeColor,
    this.icon,
    this.chartSize = 100,
    this.isExpanded = false,
    this.onTap,
  });

  @override
  State<AnimatedRingChart> createState() => _AnimatedRingChartState();
}

class _AnimatedRingChartState extends State<AnimatedRingChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = Tween<double>(begin: 0, end: widget.percentage).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedRingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation = Tween<double>(begin: _animation.value, end: widget.percentage).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRichCard = widget.metric != null || widget.badgeText != null || widget.icon != null;

    final content = AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final ringWidget = SizedBox(
          height: widget.chartSize,
          width: widget.chartSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: 270,
                  sectionsSpace: 0,
                  centerSpaceRadius: widget.chartSize * 0.35,
                  sections: [
                    PieChartSectionData(
                      value: _animation.value.clamp(0.01, 100),
                      color: widget.primaryColor,
                      radius: 11,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: (100 - _animation.value).clamp(0, 100),
                      color: const Color(0xFFF1F5F9),
                      radius: 8,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
              Text(
                widget.centerText,
                style: TextStyle(
                  fontSize: widget.chartSize * 0.21,
                  fontWeight: FontWeight.w900,
                  color: widget.primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        );

        if (!isRichCard) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ringWidget,
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }

        final cardBody = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: widget.isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
          mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // Top Row: Icon + Title + Badge
            Row(
              children: [
                if (widget.icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(4.5),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(widget.icon, size: 14, color: widget.primaryColor),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (widget.badgeText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (widget.badgeColor ?? widget.primaryColor).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.badgeText!,
                      style: TextStyle(
                        color: widget.badgeColor ?? widget.primaryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Ring Chart Centered
            if (widget.isExpanded)
              Expanded(
                child: Center(child: ringWidget),
              )
            else ...[
              Center(child: ringWidget),
              const SizedBox(height: 8),
            ],

            // Big Metric Value & Subtitle
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.metric != null) ...[
                  Center(
                    child: Text(
                      widget.metric!,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
                if (widget.subInfo != null) ...[
                  const SizedBox(height: 2),
                  Center(
                    child: Text(
                      widget.subInfo!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: cardBody,
        );
      },
    );

    if (widget.onTap != null) {
      return InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: content,
      );
    }

    return content;
  }
}
