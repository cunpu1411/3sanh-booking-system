import 'package:client_web/controllers/reservations/reservations_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaginationControls extends StatelessWidget {
  const PaginationControls({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReservationsController>();
    return Obx(() {
      // Return an empty container if there are no more items to load
      if (controller.totalItemsFiltered.value == 0) {
        return const SizedBox.shrink();
      }
      // Show pagination controls only if there are more items to load
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavigationButtons(controller),
            _buildDisplayInfo(controller),
          ],
        ),
      );
    });
  }

  Widget _buildNavigationButtons(ReservationsController controller) {
    return Row(
      children: [
        // First Page Button
        Obx(
          () => _buildNavButton(
            icon: Icons.first_page,
            tooltip: 'First Page',
            enable: controller.canGoToPreviousPage,
            onPressed: () => controller.goToPage(1),
          ),
        ),
        const SizedBox(width: 2),
        // Previous Page Button
        Obx(
          () => _buildNavButton(
            icon: Icons.chevron_left,
            tooltip: 'Previous page',
            enable: controller.canGoToPreviousPage,
            onPressed: controller.previousPage,
          ),
        ),
        // Previous Page Button
        const SizedBox(width: 2),
        Obx(() => _buildPageNumbers(controller)),
        const SizedBox(width: 16),

        // Next button
        Obx(
          () => _buildNavButton(
            icon: Icons.chevron_right,
            tooltip: 'Next page',
            enable: controller.canGoToNextPage,
            onPressed: controller.nextPage,
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String tooltip,
    required bool enable,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enable ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: enable ? onPressed : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: enable
                    ? const Color(0xFFF8F9FA)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: enable
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFF1F5F9),
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: enable
                    ? const Color(0xFF5697C6)
                    : const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageNumbers(ReservationsController controller) {
    final currentPage = controller.currentPage.value;
    final totalPages = controller.totalPages;
    final hasMore = controller.hasMoreData.value;
    print(
      '>> Building page numbers: currentPage=$currentPage, totalPages=$totalPages, hasMore=$hasMore',
    );
    // Generate list of page numbers to display
    final pages = _generatePageNumbers(currentPage, totalPages, hasMore);

    return Row(
      children: pages.map((page) {
        if (page == -1) {
          // Ellipsis (...)
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        // Page number button
        final isActive = page == currentPage;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => controller.goToPage(page),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF5697C6)
                      : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF5697C6)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  page.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Generate smart page numbers
  /// Example: [1, 2, 3, -1, 8, 9, 10] where -1 is ellipsis
  List<int> _generatePageNumbers(int current, int total, bool hasMore) {
    // If total pages are 7 or less, show all pages
    if (total <= 7) {
      List<int> pages = List.generate(total, (i) => i + 1);
      // If there are more items to load, add an ellipsis at the end
      if (hasMore) {
        pages.add(-1);
      }
      return pages;
    }

    // Always show first page
    List<int> pages = [1];

    if (current <= 4) {
      // Near start: [1, 2, 3, 4, 5, ...]
      pages.addAll([2, 3, 4, 5]);
      if (current < total || hasMore) {
        pages.add(-1); // ellipsis
      }
      if (current < total) {
        pages.add(total);
      }
    } else if (current >= total - 3) {
      // Near end: [1, ..., total-4, total-3, total-2, total-1, total]
      pages.add(-1);
      pages.addAll([total - 4, total - 3, total - 2, total - 1, total]);
      // If there are more items to load, add an ellipsis at the end
      if (hasMore) {
        pages.add(-1);
      }
    } else {
      // Middle: [1, ..., current-1, current, current+1, ...]
      pages.add(-1);
      pages.addAll([current - 1, current, current + 1]);
      if (current < total || hasMore) {
        pages.add(-1);
      }
      if (current < total) {
        pages.add(total);
      }
    }

    return pages;
  }

  /// Build display info (Showing X-Y of Z+)
  Widget _buildDisplayInfo(ReservationsController controller) {
    return Text(
      controller.displayedRange,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF64748B),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
