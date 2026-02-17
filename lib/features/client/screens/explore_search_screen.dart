import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Ensure these paths match your project structure
import 'package:legal_case_manager/features/lawyer/screens/lawyer_profile_view_screen.dart';

class ExploreSearchScreen extends StatefulWidget {
  const ExploreSearchScreen({super.key});

  @override
  State<ExploreSearchScreen> createState() => _ExploreSearchScreenState();
}

class _ExploreSearchScreenState extends State<ExploreSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "Name"; // Options: Name, Experience, Rating, Category

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Explore Lawyers", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            _buildFilterChips(),
            Expanded(child: _buildResultsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0F172A),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search by $_selectedFilter...",
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Colors.white60),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.white60),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = "");
            },
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ["Name", "Experience", "Rating", "Category"];
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (context, i) {
          final filter = filters[i];
          final bool isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() => _selectedFilter = filter);
              },
              selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFF2563EB),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF2563EB) : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'lawyer')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        // Local filtering logic
        final lawyers = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final String name = (data['name'] ?? "").toString().toLowerCase();
          final String category = (data['specialization'] ?? "").toString().toLowerCase();
          final String exp = (data['experience'] ?? "").toString().toLowerCase();
          final String rating = (data['rating'] ?? "").toString().toLowerCase();

          if (_searchQuery.isEmpty) return true;

          switch (_selectedFilter) {
            case "Name": return name.contains(_searchQuery);
            case "Category": return category.contains(_searchQuery);
            case "Experience": return exp.contains(_searchQuery);
            case "Rating": return rating.contains(_searchQuery);
            default: return name.contains(_searchQuery);
          }
        }).toList();

        if (lawyers.isEmpty) return _buildNoResults();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lawyers.length,
          itemBuilder: (context, index) {
            final data = lawyers[index].data() as Map<String, dynamic>;
            return _buildLawyerCard(data);
          },
        );
      },
    );
  }

  Widget _buildLawyerCard(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.person, color: Color(0xFF2563EB)),
        ),
        title: Text(data['name'] ?? 'Lawyer', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['specialization'] ?? 'General Practice'),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(data['rating']?.toString() ?? '5.0', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.work_history, color: Colors.grey, size: 14),
                const SizedBox(width: 4),
                Text("${data['experience'] ?? '0'} Years", style: const TextStyle(fontSize: 12)),
              ],
            )
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No lawyers found matching your search.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}