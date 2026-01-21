import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/user_profile_provider.dart';

class EquipmentCategoryDetailScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final bool isOnboarding;

  const EquipmentCategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.isOnboarding,
  });

  @override
  State<EquipmentCategoryDetailScreen> createState() => _EquipmentCategoryDetailScreenState();
}

class _EquipmentCategoryDetailScreenState extends State<EquipmentCategoryDetailScreen> {
  List<dynamic> _allEquipment = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  // 🛡️ SHIELD: Deterministic JSON Loading
  // Rationale: Loads the "Universal Menu" from assets to ensure UI/AI sync.
  Future<void> _loadLibrary() async {
    final String response = await rootBundle.loadString('assets/data/equipment_library.json');
    final data = await json.decode(response);
    setState(() {
      _allEquipment = (data as List).where((item) => item['category'] == widget.categoryId).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final profileProvider = Provider.of<UserProfileProvider>(context);

    final List<String> selectedIds = widget.isOnboarding
        ? onboardingProvider.finalProfile.equipmentIds
        : (profileProvider.userProfile?.equipmentIds ?? []);

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _allEquipment.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = _allEquipment[index];
                final String id = item['id'];
                final bool isSelected = selectedIds.contains(id);
                final bool isEssential = item['is_essential'] ?? false;

                return CheckboxListTile(
                  title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['description']),
                  value: isSelected,
                  secondary: isEssential 
                    ? const Icon(Icons.star, color: Colors.amber, size: 20) 
                    : null,
                  onChanged: (_) {
                    if (widget.isOnboarding) {
                      onboardingProvider.toggleEquipment(id);
                    } else {
                      profileProvider.toggleEquipment(id);
                    }
                  },
                );
              },
            ),
    );
  }
}