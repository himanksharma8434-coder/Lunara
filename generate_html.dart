import 'dart:io';

void main() async {
  try {
    final markdownFile = File(r'C:\Users\smort\.gemini\antigravity\brain\0c7cc5b5-685a-4536-8d5a-dcf64009adb8\lunara_codebase_breakdown.md');
    final templateFile = File(r'breakdown_template.html');
    final outputFile = File(r'final_breakdown.html');

    print('Checking markdown file...');
    if (!await markdownFile.exists()) {
      print('Markdown file NOT FOUND at ${markdownFile.path}');
      return;
    }
    print('Checking template file...');
    if (!await templateFile.exists()) {
      print('Template file NOT FOUND at ${templateFile.path}');
      return;
    }

    print('Reading files...');
    String markdown = await markdownFile.readAsString();
    String template = await templateFile.readAsString();

    print('Escaping markdown...');
    String escapedMarkdown = markdown.replaceAll('`', '\\`').replaceAll('\$', '\\\$');
    
    print('Replacing content...');
    String finalHtml = template.replaceFirst('<!-- MARKDOWN_CONTENT -->', escapedMarkdown);
    
    print('Writing output...');
    await outputFile.writeAsString(finalHtml);
    print('SUCCESS: Final HTML generated at: ${outputFile.fullPathSync()}');
  } catch (e) {
    print('ERROR: $e');
  }
}

extension FileExt on File {
  String fullPathSync() => File(this.path).absolute.path;
}
