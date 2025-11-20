import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../controllers/history_controller.dart';

PreferredSizeWidget buildHistoryAppBar({
  required BuildContext context,
  required HistoryController controller,
  required TabController tabController,
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(96),
    child: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          const Text(
            'Histórico',
            style: TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          if (!controller.isLoading && controller.filteredMeasurements.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${controller.filteredMeasurements.length}',
                style: const TextStyle(
                  color: AppConstants.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Stack(
            children: [
              const Icon(Icons.filter_list, color: AppConstants.textPrimary),
              if (controller.selectedPeriod != 'all')
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppConstants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onSelected: controller.changePeriod,
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => controller.periods.entries.map((entry) {
            final isSelected = controller.selectedPeriod == entry.key;

            return PopupMenuItem<String>(
              value: entry.key,
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected
                          ? AppConstants.primaryColor
                          : AppConstants.textPrimary,
                      fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(width: 8),
      ],
      bottom: TabBar(
        controller: tabController,
        labelColor: AppConstants.primaryColor,
        unselectedLabelColor: AppConstants.textSecondary,
        indicatorColor: AppConstants.primaryColor,
        indicatorWeight: 3,
        tabs: const [
          Tab(
            height: 46,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.list, size: 20),
                SizedBox(width: 6),
                Text('Lista'),
              ],
            ),
          ),
          Tab(
            height: 46,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.show_chart, size: 20),
                SizedBox(width: 6),
                Text('Gráfico'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}