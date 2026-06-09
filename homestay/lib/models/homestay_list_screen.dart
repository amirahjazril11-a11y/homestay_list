import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:homestay/models/homestay.dart';

class HomestayListScreen extends StatefulWidget {
  const HomestayListScreen({Key? key}) : super(key: key);

  @override
  State<HomestayListScreen> createState() => _HomestayListScreenState();
}

class _HomestayListScreenState extends State<HomestayListScreen> {
  List<Homestay> homestays = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  static const String _baseUrl = 'http://slum78.myddns.me/homestay2u/api';

  @override
  void initState() {
    super.initState();
    _fetchHomestays();
  }

  Future<void> _fetchHomestays({String query = ''}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final url = query.isNotEmpty 
          ? '$_baseUrl/homestays?search=$query' 
          : '$_baseUrl/homestays';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          homestays = data.map((json) => HomeStay.fromJson(json)).toList();
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load homestays. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Please check your internet connection: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

    void _onSearch() {
      final query = _searchController.text.trim();
      _fetchHomestays(query: query);
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homestay List'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    ); 
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name, state, or district',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _onSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: const TextStyle(fontSize: 16,color: Colors.red)));
    }
    return RefreshIndicator(onRefresh: () => _fetchHomestays(query: _searchController.text.trim()), child: ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: homestays.length,
      itemBuilder: (context, index) => _buildCard(_homestays[index]),
    ),
    );
  }

  Widget _buildCard(Homestay homestay) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(homestay.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.teal),
                const SizedBox(width: 4),
                Text('${homestay.district}, ${homestay.state}', style: const TextStyle(color: Colors.teal)),
              ],
            ),
            if (homestay.price != null) ...[
              const SizedBox(height: 4),
              Text('Price: RM ${homestay.price!.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
            ],
            if (homestay.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(homestay.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}