import 'package:flutter/material.dart';
import 'package:homestay/models/homestay.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
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

  // Search history
  final List<String> _searchHistory = [];

  // Pagination
  int _currentLimit = 20;
  final List<int> _limitOptions = [10, 20, 50, 100];

  static const String _baseUrl = 'http://slum78.myddns.me/homestay2u/api';
  static const String _homestaysEndpoint = 'homestays';
  static const String _statesEndpoint = 'states';

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
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      return data[key] ?? data['data'] ?? [];
    }
    return [];
  }

  Future<void> _fetchStates() async {
    try {
      final response = await http
          .get(_apiUri(_statesEndpoint))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      final items = _readItems(data, 'states');
      setState(() {
        _states = items
            .map<String>((e) => (e as Map)['state']?.toString() ?? '')
            .where((state) => state.isNotEmpty)
            .toList();
      });
    } catch (e) {
      // Handle error silently, states filter will just be unavailable.
    }
  }

  Future<void> _fetchHomestays({
  String? query,
  String? state,
  String? district,
  int? limit,
}) async {
  setState(() {
    _isLoading = true;
    _errorMessage = '';
    _homestays = [];
  });

  final queryParameters = <String, String>{};
  
  queryParameters['limit'] =
    (limit ?? _currentLimit).toString();
  
  if (query != null && query.isNotEmpty) {
    queryParameters['search'] = query;
  }
  if (state != null && state.isNotEmpty) {
    queryParameters['state'] = state;
  }
  if (district != null && district.isNotEmpty) {
    queryParameters['district'] = district;
  }

  try {
      final uri = _apiUri(
        _homestaysEndpoint,
        queryParameters: queryParameters,
    );

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List items = data['homestays'] ?? data['data'] ?? [];
      setState(() {
        _homestays = items.map((e) {
          final jsonItem = Map<String, dynamic>.from(e as Map);
          return Homestay.fromJson(jsonItem);
        }).toList();

        // ← correct empty result message
        if (_homestays.isEmpty) {
          _errorMessage = 'No homestay found for your search.';
        }
      });
    } else {
      setState(() {
        _errorMessage = 'Unable to load data from server.';
      });
    }
  } on TimeoutException {
    // ← specific timeout message
    setState(() {
      _errorMessage = 'Request timed out. Please try again.';
    });
  } catch (e) {
    // ← only for real connection errors
    setState(() {
      _errorMessage = 'Please check your internet connection.';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
  void _onSearch() {
    final query = _searchController.text.trim();

    // Save to search history
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) _searchHistory.removeLast();
      });
    }

    _fetchHomestays(
      query: query,
      state: _selectedState,
      district: _districtController.text.trim(),
      limit: _currentLimit,
    );
  }

  void _onFilter() {
    _fetchHomestays(
      state: _selectedState,
      district: _districtController.text.trim(),
      limit: _currentLimit,
    );
  }

  void _applyHistorySearch(String query) {
    _searchController.text = query;
    _onSearch();
  }

  void _clearHistory() {
    setState(() => _searchHistory.clear());
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
          if (_searchHistory.isNotEmpty) _buildSearchHistory(),
          _buildFilter(),
          _buildPaginationControl(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name, state, or district',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              const Text('Recent searches',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Spacer(),
              GestureDetector(
                onTap: _clearHistory,
                child: const Text('Clear',
                    style: TextStyle(fontSize: 12, color: Colors.teal)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _searchHistory.map((query) {
              return ActionChip(
                label: Text(query, style: const TextStyle(fontSize: 12)),
                avatar: const Icon(Icons.history, size: 14),
                onPressed: () => _applyHistorySearch(query),
                backgroundColor: Colors.teal.withValues(alpha: 0.08),
                side: const BorderSide(color: Colors.teal, width: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedState ?? '',
              items: [
                const DropdownMenuItem<String>(
                    value: '', child: Text('All States')),
                ..._states.map(
                  (state) =>
                      DropdownMenuItem<String>(value: state, child: Text(state)),
                ),
              ],
              onChanged: (String? value) {
                setState(() {
                  _selectedState = value == '' ? null : value;
                });
                  _fetchHomestays(
                    state: value == '' ? null : value,
                    district: _districtController.text.trim(),
                    query: _searchController.text.trim(),
                    limit: _currentLimit,
                  );
              },
              decoration: const InputDecoration(
                labelText: 'Filter by State',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          const Text('Results per page:',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 10),
          ..._limitOptions.map((option) {
            final isSelected = _currentLimit == option;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text('$option',
                    style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.teal)),
                selected: isSelected,
                selectedColor: Colors.teal,
                backgroundColor: Colors.teal.withAlpha((0.08 * 255).round()),
                side: const BorderSide(color: Colors.teal, width: 0.5),
                onSelected: (_) {
                  setState(() => _currentLimit = option);
                  _fetchHomestays(
                    query: _searchController.text.trim(),
                    state: _selectedState,
                    district: _districtController.text.trim(),
                    limit: option,
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
          child: Text(_errorMessage,
              style: const TextStyle(fontSize: 16, color: Colors.red)));
    }
    return RefreshIndicator(
      onRefresh: () => _fetchHomestays(
        query: _searchController.text.trim(),
        state: _selectedState,
        district: _districtController.text.trim(),
        limit: _currentLimit,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      HomestayDetailScreen(homestay: homestay)));
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
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(homestay.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.teal),
                  const SizedBox(width: 4),
                  Text('${homestay.district}, ${homestay.state}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
              if (homestay.price != null) ...[
                const SizedBox(height: 4),
                Text('Price: RM ${homestay.price!.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green)),
              ],
              if (homestay.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(homestay.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey)),
              ],
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('View Details',
                    style: TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold)),
              ),
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