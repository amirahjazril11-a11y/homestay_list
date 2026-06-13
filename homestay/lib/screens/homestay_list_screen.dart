import 'package:flutter/material.dart';
import 'package:homestay/models/homestay.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'homestay_detail_screen.dart';

class HomestayListScreen extends StatefulWidget {
  const HomestayListScreen({super.key});

  @override
  State<HomestayListScreen> createState() => _HomestayListScreenState();
}

class _HomestayListScreenState extends State<HomestayListScreen> {
  List<Homestay> _homestays = [];
  List<String> _states = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  String? _selectedState;

  static const String _baseUrl = 'http://slum78.myddns.me/homestay2u/api';
    static const List<String> _homestayEndpoints = [
    'homestays',
    'homestay',
    'homestays.php',
    'get_homestays.php',
  ];
  static const List<String> _stateEndpoints = [
    'states',
    'states.php',
  ];

  @override
  void initState() {
    super.initState();
    _fetchStates();
    _fetchHomestays();
  }
  
    Uri _apiUri(String endpoint, {Map<String, String>? queryParameters}) {
    return Uri.parse('$_baseUrl/$endpoint').replace(
      queryParameters: queryParameters?.isEmpty == true ? null : queryParameters,
    );
  }

  List _readItems(dynamic data, String key) {
    if (data is List) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      return data[key] ?? data['data'] ?? [];
    }
    return [];
  }

  // Fetch list of states for dropdown filter
  Future<void> _fetchStates() async {
     for (final endpoint in _stateEndpoints) {
      try {
        final response = await http
            .get(_apiUri(endpoint))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          continue;
        }
        final data = json.decode(response.body);
        final items = _readItems(data, 'states');
        setState(() {
                  _states = items
              .map<String>((e) => (e as Map)['name']?.toString() ?? '')
              .where((state) => state.isNotEmpty)
              .toList();
        });
        return;
      } catch (e) {
        // Handle error silently, states filter will just be unavailable.
      }
    }
  }


    Future<void> _fetchHomestays({
    String? query,
    String? state,
    String? district,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final queryParameters = <String, String>{};
    if (query != null && query.isNotEmpty) {
      queryParameters['search'] = query;
      queryParameters['limit'] = '20';
    }
    if (state != null && state.isNotEmpty) {
      queryParameters['state'] = state;
    }
    if (district != null && district.isNotEmpty) {
      queryParameters['district'] = district;
    }

    Object? lastError;
    int? lastStatusCode;


    try {
      for (final endpoint in _homestayEndpoints) {
        final response = await http
            .get(_apiUri(endpoint, queryParameters: queryParameters))
            .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
          lastStatusCode = response.statusCode;
          continue;
        }

        final data = json.decode(response.body);
        final items = _readItems(data, 'homestays');
        setState(() {
          _homestays = items.map((e) {
            final jsonItem = Map<String, dynamic>.from(e as Map);
             return Homestay.fromJson(jsonItem);
          }).toList();
          if (_homestays.isEmpty) {
            _errorMessage = 'No homestays found for the search query.';
          }
        });
        return;
      }
       setState(() {
        _errorMessage = lastStatusCode == null
            ? 'Failed to load homestays.'
            : 'Failed to load homestays. Status code: $lastStatusCode';
      });     
    } catch (e) {
       lastError = e;
      setState(() {
        _errorMessage = 'Please check your internet connection: $lastError';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

    void _onSearch() {
      _fetchHomestays(query: _searchController.text.trim(), state: _selectedState, district: _districtController.text.trim());
    }

    void _onFilter() {
      _fetchHomestays(state: _selectedState, district: _districtController.text.trim());
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homestay List in Malaysia'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _onFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilter(),
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

  Widget _buildFilter(){
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: _selectedState,
              items: [
                const DropdownMenuItem(value: null, child: Text('All States')),
                ..._states.map(
                  (state) => DropdownMenuItem(value: state, child: Text(state)),
                ),
              ],
              onChanged: (String? value) {
                setState(() {
                  _selectedState = value;
                  _fetchHomestays(
                    state: value,
                    district: _districtController.text.trim(),
                    query: _searchController.text.trim(),
                  );
                });
              },
              decoration: const InputDecoration(
                labelText: 'Filter by State',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _districtController,
              decoration: const InputDecoration(
                labelText: 'Filter by District',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
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
    return RefreshIndicator(onRefresh: () => _fetchHomestays(query: _searchController.text.trim(), state: _selectedState, district: _districtController.text.trim()), child: ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _homestays.length,
      itemBuilder: (context, index) => _buildCard(_homestays[index]),
    ),
    );
  }

  Widget _buildCard(Homestay homestay) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => HomestayDetailScreen(homestay: homestay)));
        },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (homestay.imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  homestay.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(homestay.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.teal),
                const SizedBox(width: 4),
                Text('${homestay.district}, ${homestay.state}', style: const TextStyle(color: Colors.grey)),
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
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('View Details', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _districtController.dispose();
    super.dispose();
  }
}