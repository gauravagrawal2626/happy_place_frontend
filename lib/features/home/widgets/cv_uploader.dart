import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path/path.dart' as path;

class CVUploader extends StatefulWidget {
  const CVUploader({super.key});

  @override
  State<CVUploader> createState() => _CVUploaderState();
}

class _CVUploaderState extends State<CVUploader> {
  String? _fileName;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickAndParseFile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
      );

      if (result == null) {
        setState(() {
          _errorMessage = 'No file selected';
        });
        return;
      }

      final file = result.files.first;
      final fileExtension = path.extension(file.name).toLowerCase();

      // Parse file based on type
      String parsedText = '';
      if (fileExtension == '.pdf') {
        parsedText = await _parsePdfFile(file);
      } else if (fileExtension == '.docx') {
        // TODO: Implement DOCX parsing
        parsedText = 'DOCX parsing not implemented yet';
      }

      // Print parsed text to console
      print('Parsed CV content:');
      print(parsedText);

      setState(() {
        _fileName = file.name;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _parsePdfFile(PlatformFile file) async {
    try {
      List<int>? bytes = file.bytes;

      if (bytes == null && file.path != null) {
        // If bytes are not directly available, try reading from the path
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) {
        throw Exception('Could not read file bytes or path');
      }

      // Load the PDF document
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String text = '';
      // Extract text from each page
      for (int i = 0; i < document.pages.count; i++) {
        text += PdfTextExtractor(document).extractText(startPageIndex: i);
      }
      document.dispose();
      return text;
    } catch (e) {
      throw Exception('Error parsing PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CV Upload',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade900),
              )
            else if (_fileName != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File: $_fileName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Parsed!'),
                ],
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndParseFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload CV'),
            ),
          ],
        ),
      ),
    );
  }
} 