import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_service.dart';

class SystemConfigScreen extends StatefulWidget {
  const SystemConfigScreen({super.key});

  @override
  State<SystemConfigScreen> createState() => _SystemConfigScreenState();
}

class _SystemConfigScreenState extends State<SystemConfigScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _configs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    try {
      final configs = await _adminService.getSystemConfigs();
      setState(() {
        _configs = configs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading configs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateConfig(String configId, dynamic newValue) async {
    try {
      await _adminService.updateSystemConfig(configId, newValue, 'admin');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadConfigs(); // Reload to get updated data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update configuration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildConfigCard(Map<String, dynamic> config) {
    final key = config['key'] as String;
    final value = config['value'];
    final description = config['description'] as String;
    final category = config['category'] as String;
    final configId = config['id'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildConfigEditor(configId, key, value),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigEditor(String configId, String key, dynamic value) {
    if (value is bool) {
      return Switch(
        value: value,
        onChanged: (newValue) => _updateConfig(configId, newValue),
        activeColor: Colors.blue,
      );
    } else if (value is int) {
      final controller = TextEditingController(text: value.toString());
      return SizedBox(
        width: 100,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          onSubmitted: (newValue) {
            final intValue = int.tryParse(newValue);
            if (intValue != null) {
              _updateConfig(configId, intValue);
            }
          },
        ),
      );
    } else if (value is double) {
      final controller = TextEditingController(text: value.toString());
      return SizedBox(
        width: 100,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          onSubmitted: (newValue) {
            final doubleValue = double.tryParse(newValue);
            if (doubleValue != null) {
              _updateConfig(configId, doubleValue);
            }
          },
        ),
      );
    } else {
      // String or other types
      final controller = TextEditingController(text: value.toString());
      return SizedBox(
        width: 200,
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          onSubmitted: (newValue) => _updateConfig(configId, newValue),
        ),
      );
    }
  }

  Widget _buildConfigsByCategory() {
    final categories = <String, List<Map<String, dynamic>>>{};

    for (final config in _configs) {
      final category = config['category'] as String;
      categories.putIfAbsent(category, () => []);
      categories[category]!.add(config);
    }

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories.keys.elementAt(index);
        final configs = categories[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            ...configs.map((config) => _buildConfigCard(config)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'System Configuration',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _loadConfigs,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _configs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.settings_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No configurations found',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'System configurations will appear here',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : _buildConfigsByCategory(),
    );
  }
}
