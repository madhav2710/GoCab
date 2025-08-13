import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationSearchDialog extends StatefulWidget {
  final String title;
  final String hint;

  const LocationSearchDialog({
    super.key,
    required this.title,
    required this.hint,
  });

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  final _controller = TextEditingController();
  final List<String> _suggestions = [
    'Current Location',
    'Home',
    'Work',
    'Airport',
    'Shopping Mall',
    'Restaurant',
    'Hospital',
    'University',
    'Train Station',
    'Bus Station',
  ];
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _filteredSuggestions = _suggestions;
    _controller.addListener(_filterSuggestions);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _filterSuggestions() {
    final query = _controller.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSuggestions = _suggestions;
      } else {
        _filteredSuggestions = _suggestions
            .where((suggestion) =>
                suggestion.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _filteredSuggestions[index];
                  return ListTile(
                    leading: Icon(
                      suggestion == 'Current Location' 
                          ? Icons.my_location 
                          : Icons.location_on,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(
                      suggestion,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context, suggestion);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
