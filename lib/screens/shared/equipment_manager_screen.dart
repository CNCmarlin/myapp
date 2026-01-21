import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/user_profile_provider.dart';
import 'equipment_category_detail_screen.dart';

class EquipmentManagerScreen extends StatefulWidget {
  final bool isOnboarding;

  const EquipmentManagerScreen({super.key, this.isOnboarding = false});

  @override
  State<EquipmentManagerScreen> createState() => _EquipmentManagerScreenState();
}

class _EquipmentManagerScreenState extends State<EquipmentManagerScreen> {
  String _selectedEnvironment = 'gym'; // Default to Gym

  // Rationale: These categories match our JSON structure precisely.
  final List<Map<String, dynamic>> _categories = [
    {'id': 'chest_machines', 'name': 'Chest', 'icon': Icons.fitness_center},
    {'id': 'back_machines', 'name': 'Back', 'icon': Icons.rowing},
    {
      'id': 'shoulder_machines',
      'name': 'Shoulders',
      'icon': Icons.architecture
    },
    {'id': 'leg_machines', 'name': 'Legs', 'icon': Icons.downhill_skiing},
    {'id': 'arm_machines', 'name': 'Arms', 'icon': Icons.sports_gymnastics},
    {'id': 'core_machines', 'name': 'Core', 'icon': Icons.grid_view},
    {'id': 'cables', 'name': 'Cables', 'icon': Icons.cable},
    {'id': 'free_weights', 'name': 'Weights', 'icon': Icons.scale},
    {'id': 'cardio', 'name': 'Cardio', 'icon': Icons.speed},
    {'id': 'bodyweight', 'name': 'Bodyweight', 'icon': Icons.accessibility_new},
  ];

  @override
  Widget build(BuildContext context) {
    // 🛡️ SHIELD: Dual-Provider Access
    // Rationale: Uses OnboardingProvider for new users, UserProfileProvider for existing ones.
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final profileProvider = Provider.of<UserProfileProvider>(context);

    final currentList = widget.isOnboarding
        ? onboardingProvider.finalProfile.equipmentIds
        : (profileProvider.userProfile?.equipmentIds ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Equipment'),
        actions: [
          if (!widget.isOnboarding)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => Navigator.pop(context),
            )
        ],
      ),
      body: Column(
        children: [
          _buildEnvironmentSelector(),
          Expanded(
            child: _buildCategoryGrid(currentList),
          ),
          _buildSelectionSummary(currentList.length, currentList),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 🛡️ SHIELD: Initial Auto-Selection Trigger
    // Change: Explicitly triggering the provider logic on first load.
    // Rationale: SegmentedButton does not fire onSelectionChanged for the initial value.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyEnvironmentLogic(_selectedEnvironment);
    });
  }

  // 📍 Surgical Fix: Helper to centralize logic for both initState and user interaction
  void _applyEnvironmentLogic(String env) {
    if (widget.isOnboarding) {
      context.read<OnboardingProvider>().applyEssentialsForEnvironment(env);
    } else {
      context.read<UserProfileProvider>().applyEssentialsForEnvironment(env);
    }
  }

  Widget _buildEnvironmentSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
              value: 'gym', label: Text('Gym'), icon: Icon(Icons.apartment)),
          ButtonSegment(
              value: 'home', label: Text('Home'), icon: Icon(Icons.home)),
          ButtonSegment(
              value: 'bodyweight',
              label: Text('Bodyweight'),
              icon: Icon(Icons.bolt)),
        ],
        selected: {_selectedEnvironment},
        onSelectionChanged: (Set<String> newSelection) {
          final env = newSelection.first;
          setState(() => _selectedEnvironment = env);
          if (widget.isOnboarding) {
            context
                .read<OnboardingProvider>()
                .applyEssentialsForEnvironment(env);
          } else {
            context
                .read<UserProfileProvider>()
                .applyEssentialsForEnvironment(env);
          }
        },
      ),
    );
  }

  Widget _buildCategoryGrid(List<String> currentList) { // 📍 Surgical Fix: Explicitly using the passed currentList
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        return FutureBuilder<String>(
          future: DefaultAssetBundle.of(context).loadString('assets/data/equipment_library.json'),
          builder: (context, snapshot) {
            int count = 0;
            if (snapshot.hasData) {
              final List<dynamic> library = json.decode(snapshot.data!);
              count = library.where((item) => 
                item['category'] == cat['id'] && currentList.contains(item['id'])
              ).length;
            }

            return _CategoryCard(
              name: cat['name']!,
              icon: cat['icon'] as IconData,
              selectedCount: count,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EquipmentCategoryDetailScreen(
                    categoryId: cat['id']!,
                    categoryName: cat['name']!,
                    isOnboarding: widget.isOnboarding,
                  ),
                ),
              ),
            );
          },
        );
      },
    ); // 📍 Surgical Fix: Corrected syntax and removed extra parenthesis
  }

// 🛡️ SHIELD: Selection Review & Modify Logic
  // Change: Removed internal "Next Step" button and made the summary bar interactive.
  // Rationale: Fixes UI redundancy and provides a central way to modify selections before proceeding.
  Widget _buildSelectionSummary(int count, List<String> currentList) {
    return InkWell(
      onTap: count > 0 ? () => _showReviewSheet(context, currentList) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Equipment Selected',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  '$count Items Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (count > 0)
              const Icon(Icons.expand_less_rounded),
          ],
        ),
      ),
    );
  }

 // 🛡️ SHIELD: Dynamic JSON-Categorized Review
  // Change: Refactored to load JSON metadata to group items perfectly by their actual category.
  // Rationale: Replaces brittle "slug-matching" with deterministic data-driven grouping.
  void _showReviewSheet(BuildContext context, List<String> initialList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => FutureBuilder<String>(
          future: DefaultAssetBundle.of(context).loadString('assets/data/equipment_library.json'),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final List<dynamic> library = json.decode(snapshot.data!);
            
            return Consumer2<OnboardingProvider, UserProfileProvider>(
              builder: (context, onboardProv, profileProv, _) {
                final liveList = widget.isOnboarding 
                    ? onboardProv.finalProfile.equipmentIds 
                    : (profileProv.userProfile?.equipmentIds ?? []);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Review Equipment", style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    const Divider(),
                    Expanded(
                      child: liveList.isEmpty 
                        ? const Center(child: Text("No equipment selected"))
                        : ListView(
                            controller: scrollController,
                            children: _categories.map((cat) {
                              // 📍 Deterministic Filter: Match live IDs against their category in the JSON
                              final itemsInCategory = library.where((item) => 
                                item['category'] == cat['id'] && liveList.contains(item['id'])
                              ).toList();

                              if (itemsInCategory.isEmpty) return const SizedBox.shrink();

                              return _buildCategoryExpansionTile(context, cat, itemsInCategory);
                            }).toList(),
                          ),
                    ),
                  ],
                );
              },
            );
          }
        ),
      ),
    );
  }

  Widget _buildCategoryExpansionTile(BuildContext context, Map<String, dynamic> cat, List<dynamic> itemsInCategory) {
    return ExpansionTile(
      leading: Icon(cat['icon'], color: Theme.of(context).colorScheme.primary),
      title: Text("${cat['name']} (${itemsInCategory.length})"),
      initiallyExpanded: false, // Rationale: Makes it easier to see what was just added
      children: itemsInCategory.map((item) {
        return ListTile(
          title: Text(item['name']), // 📍 Change: Uses proper "Name" from JSON instead of slug
          trailing: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
          onTap: () {
            // Rationale: Remove logic triggers provider which updates liveList via Consumer2
            if (widget.isOnboarding) {
              context.read<OnboardingProvider>().toggleEquipment(item['id']);
            } else {
              context.read<UserProfileProvider>().toggleEquipment(item['id']);
            }
          },
        );
      }).toList(),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon; // 📍 Surgical Change: Updated from String to IconData
  final int selectedCount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.selectedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          // 📍 Surgical Change: Wrapped in Stack for the badge
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 28, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (selectedCount > 0) // 📍 Surgical Change: Added selection badge
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    '$selectedCount',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
