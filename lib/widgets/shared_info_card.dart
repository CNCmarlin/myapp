import 'package:flutter/material.dart';

class SharedInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? expandableContent;

  const SharedInfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.expandableContent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        child: expandableContent != null
            ? ExpansionTile(
                title: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(subtitle),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0).copyWith(top: 0),
                    child: expandableContent,
                  ),
                ],
              )
            : ListTile(
                title: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(subtitle),
              ),
      ),
    );
  }
}