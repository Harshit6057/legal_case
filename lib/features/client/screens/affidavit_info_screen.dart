import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AffidavitInfoScreen extends StatelessWidget {
  const AffidavitInfoScreen({super.key});

  // --- BARE ACTS SECTION ---
  final List<Map<String, String>> bareActs = const [
    {'name': 'Bhartiya Nyaya Sanhita 2023', 'file': 'Bhartiya Nyaya Sanhita 2023.pdf'},
    {'name': 'Code of Civil Procedure 1908', 'file': 'Code of Civil procedure 1908.pdf'},
    {'name': 'The Constitution of India', 'file': 'The constitution of india.pdf'},
    {'name': 'Hindu Marriage Act 1955', 'file': 'The hindu marriage act 1955.pdf'},
  ];

  // --- UPDATED MISC. FORMS SECTION ---
  final List<Map<String, String>> miscForms = const [
    {'name': 'Bhartiya Nyaya Sanhita 2023', 'file': 'Bhartiya Nyaya Sanhita 2023.pdf'},
    {'name': 'Bhartiya Sakshya Adhiniyam 2023', 'file': 'Bhartiya Sakshya Adhiniyam 2023.pdf'},
    {'name': 'Code of Civil procedure 1908', 'file': 'Code of Civil procedure 1908.pdf'},
    {'name': 'Code of Criminal procedure act 1973', 'file': 'Code of Criminal procedure act 1973.pdf'},
    {'name': 'Consumer protection act 1986', 'file': 'Consumer protection act 1986.pdf'},
    {'name': 'Income tax act 1961', 'file': 'Income tax act 1961.pdf'},
    {'name': 'POCSO 2012', 'file': 'POCSO 2012.pdf'},
    {'name': 'Prisoners act 1894', 'file': 'Prisoners act 1894.pdf'},
    {'name': 'The advocates act 1961', 'file': 'The advocates act 1961.pdf'},
    {'name': 'The airport authority of india act 1994', 'file': 'The airport authority of india act 1994.pdf'},
    {'name': 'The arbitration and concilation act 1996', 'file': 'The arbitration and concilation act 1996.pdf'},
    {'name': 'The arms act 1959', 'file': 'The arms act 1959.pdf'},
    {'name': 'The banking regulation Act 1949', 'file': 'The banking regulation Act 1949.pdf'},
    {'name': 'The beareau of Indian Standards act 2016', 'file': 'The beareau of Indian Standards act 2016.pdf'},
    {'name': 'The bhartiya Nagrik Suraksha Sanhita 2023', 'file': 'The bhartiya Nagrik Suraksha Sanhita 2023.pdf'},
    {'name': 'The constitution of india', 'file': 'The constitution of india.pdf'},
    {'name': 'The copyright act 1957', 'file': 'The copyright act 1957.pdf'},
    {'name': 'The divorce act 1869', 'file': 'The divorce act 1869.pdf'},
    {'name': 'The Dowry prohibition act 1961', 'file': 'The Dowry prohibition act 1961.pdf'},
    {'name': 'The electricity act 2003', 'file': 'The electricity act 2003.pdf'},
    {'name': 'The environment protection act 1986', 'file': 'The environment protection act 1986.pdf'},
    {'name': 'The essential commodities act 1955', 'file': 'The essential commodities act 1955.pdf'},
    {'name': 'The family courts act 1984', 'file': 'The family courts act 1984.pdf'},
    {'name': 'The guardian and wards act 1890', 'file': 'The guardian and wards act 1890.pdf'},
    {'name': 'The Hindu adoption and maintenance ac...', 'file': 'The Hindu adoption and maintenance ac....pdf'},
    {'name': 'The hindu marriage act 1955', 'file': 'The hindu marriage act 1955.pdf'},
  ];

  // ✅ REDUNDANT _handleAction REMOVED FROM HERE TO FIX ERRORS

  void _openPreview(BuildContext context, String folder, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          path: 'assets/doc/$folder/$fileName',
          title: fileName,
          folder: folder,
          fileName: fileName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text("Legal Resources", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Color(0xFF2563EB),
            tabs: [
              Tab(text: "Bare Acts"),
              Tab(text: "Misc. Forms"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDocList(context, bareActs, "BareActs"),
            _buildDocList(context, miscForms, "miscforms"),
          ],
        ),
      ),
    );
  }

  Widget _buildDocList(BuildContext context, List<Map<String, String>> docs, String folder) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemExtent: 95, // ✅ Optimization for smoother scrolling
      itemBuilder: (context, index) {
        final item = docs[index];
        return Card(
          key: ValueKey(item['file']), // ✅ Key improves scrolling performance
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            onTap: () => _openPreview(context, folder, item['file']!), // ✅ Click for Preview
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle
              ),
              child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
            ),
            title: Text(
              item['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text("PDF • $folder", style: const TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ),
        );
      },
    );
  }
}

// ✅ DEDICATED PREVIEW SCREEN WITH CORRECT DOWNLOAD LOGIC
class PdfPreviewScreen extends StatelessWidget {
  final String path;
  final String title;
  final String folder;
  final String fileName;

  const PdfPreviewScreen({
    super.key,
    required this.path,
    required this.title,
    required this.folder,
    required this.fileName,
  });

  Future<void> _handleAction(BuildContext context, bool isShare) async {
    try {
      final byteData = await rootBundle.load(path);
      final Uint8List bytes = byteData.buffer.asUint8List();

      if (isShare) {
        // --- SHARE LOGIC ---
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Legal Document: $title');
      } else {
        // --- DOWNLOAD LOGIC: Save to Device Memory ---
        Directory? directory;
        if (Platform.isAndroid) {
          // Standard path for Android Downloads
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        final String savePath = "${directory!.path}/$fileName";
        final file = File(savePath);
        await file.writeAsBytes(bytes);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Downloads: $fileName'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _handleAction(context, true),
          ),
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: () => _handleAction(context, false),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SfPdfViewer.asset(path),
    );
  }
}