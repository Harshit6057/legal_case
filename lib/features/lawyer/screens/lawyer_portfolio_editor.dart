import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LawyerPortfolioEditor extends StatefulWidget {
  final String lawyerId;
  const LawyerPortfolioEditor({super.key, required this.lawyerId});

  @override
  State<LawyerPortfolioEditor> createState() => _LawyerPortfolioEditorState();
}

class _LawyerPortfolioEditorState extends State<LawyerPortfolioEditor> {
  final _formKey = GlobalKey<FormState>();
  final _aboutController = TextEditingController();
  final _experienceController = TextEditingController();
  final _casesController = TextEditingController();
  String? _specialization;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchPortfolioData();
  }

  Future<void> _fetchPortfolioData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.lawyerId).get();
    if (doc.exists) {
      final data = doc.data();
      setState(() {
        _aboutController.text = data?['about'] ?? '';
        _experienceController.text = (data?['experience'] ?? 0).toString();
        _casesController.text = (data?['cases'] ?? 0).toString();
        _specialization = data?['specialization'];
      });
    }
  }

  Future<void> _updatePortfolio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.lawyerId).update({
        'about': _aboutController.text.trim(),
        'experience': int.parse(_experienceController.text),
        'cases': int.parse(_casesController.text),
        'specialization': _specialization,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Portfolio Updated!")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Portfolio")),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Professional Bio", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _aboutController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Describe your professional background...",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Bio is required" : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _specialization,
                decoration: const InputDecoration(labelText: "Main Specialization", border: OutlineInputBorder()),
                items: ['criminal', 'civil', 'corporate', 'Property', 'immigration', 'Public' ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _specialization = v),
                validator: (v) => v == null ? "Select specialization" : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Years Experience", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _casesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Total Cases", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B2B45),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _updatePortfolio,
                child: const Text("Save Portfolio Details", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}