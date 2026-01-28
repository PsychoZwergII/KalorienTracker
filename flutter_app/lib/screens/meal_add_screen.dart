import 'package:flutter/material.dart';
import 'barcode_scan_screen.dart';
import 'manual_food_entry_screen.dart';
import 'scanner_screen.dart';

class MealAddScreen extends StatelessWidget {
  final String mealName;
  final String mealType;

  const MealAddScreen({
    Key? key,
    required this.mealName,
    required this.mealType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$mealName hinzufügen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildOptionCard(
              context,
              title: 'Barcode scannen',
              subtitle: 'Produkt per Barcode erfassen',
              icon: Icons.qr_code_scanner,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BarcodeScanScreen(mealType: mealType),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildOptionCard(
              context,
              title: 'KI-Bildanalyse',
              subtitle: 'Foto machen und analysieren lassen',
              icon: Icons.camera_alt,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ScannerScreen(mealType: mealType),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildOptionCard(
              context,
              title: 'Manuell hinzufügen',
              subtitle: 'Werte selbst eingeben',
              icon: Icons.edit,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ManualFoodEntryScreen(mealType: mealType),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF2C3E50)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
