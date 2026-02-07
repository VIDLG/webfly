import 'package:flutter/services.dart' show rootBundle, AssetManifest;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webfly/services/asset_http_server.dart';
import 'package:webfly/ui/router/config.dart';

class UseCasesMenuScreen extends StatefulWidget {
  const UseCasesMenuScreen({super.key});

  @override
  State<UseCasesMenuScreen> createState() => _UseCasesMenuScreenState();
}

class _UseCasesMenuScreenState extends State<UseCasesMenuScreen> {
  List<String> _useCases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUseCases();
  }

  Future<void> _loadUseCases() async {
    try {
      // In newer Flutter versions, AssetManifest.json is not directly loadable via rootBundle in debug mode sometimes,
      // or the path/format might vary. Using AssetManifest.loadFromAssetBundle is the modern, robust way.
      final AssetManifest assetManifest =
          await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> assets = assetManifest.listAssets();

      final useCases = <String>{};

      for (final key in assets) {
        if (key.startsWith('assets/gen/use_cases/') &&
            key.endsWith('index.html')) {
          // Extract the folder name
          // e.g. assets/gen/use_cases/react/index.html -> react
          final parts = key.split('/');
          if (parts.length >= 5) {
            final folderName = parts[3];
            // Filter out root index.html if it exists at gen/use_cases/index.html
            // (which would split to assets, gen, use_cases, index.html -> length 4)
            useCases.add(folderName);
          }
        }
      }

      setState(() {
        _useCases = useCases.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading asset manifest: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _launchUseCase(String framework) {
    final serverUrl = AssetHttpServer().baseUrl;
    if (serverUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asset Server is not running!')),
      );
      return;
    }

    final url = '$serverUrl/$framework/index.html';
    // Navigate to WebF page
    context.push(
      Uri(path: kWebfRoutePath, queryParameters: {kUrlParam: url}).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Use Case'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _useCases.isEmpty
          ? const Center(child: Text('No use cases found in assets.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _useCases.length,
              itemBuilder: (context, index) {
                final useCase = _useCases[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    leading: _getIconForFramework(useCase),
                    title: Text(
                      useCase.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Launch $useCase demo application'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _launchUseCase(useCase),
                  ),
                );
              },
            ),
    );
  }

  Widget _getIconForFramework(String framework) {
    switch (framework.toLowerCase()) {
      case 'react':
        return const Icon(Icons.code, color: Colors.blue); // React blue-ish
      case 'vue':
        return const Icon(
          Icons.data_object,
          color: Colors.green,
        ); // Vue green-ish
      default:
        return const Icon(Icons.web);
    }
  }
}
