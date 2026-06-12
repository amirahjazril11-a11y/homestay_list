import 'package:flutter/material.dart';
import 'package:homestay/models/homestay.dart';

class HomestayDetailScreen extends StatelessWidget {
  final Homestay homestay;

  const HomestayDetailScreen({super.key, required this.homestay});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(homestay.name),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (homestay.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  homestay.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
              ),
            const SizedBox(height: 16),
            Text(homestay.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.teal),
                const SizedBox(width: 4),
                Text('${homestay.district}, ${homestay.state}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            if (homestay.price != null) ...[
              const SizedBox(height: 8),
              Text('Price per night: RM ${homestay.price!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.teal)),
            ],
            const Divider(height: 24),
            const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              homestay.description.isNotEmpty ? homestay.description : 'No description available',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
