import 'package:flutter/material.dart';
import '../models/local/legal_document.dart';
import '../services/services.dart';
import '../utils/app_constants.dart';

/// Экран пользовательского соглашения
class TermsOfServiceScreen extends StatefulWidget {
  final LegalDocument? document;
  final bool requireAcceptance;

  const TermsOfServiceScreen({
    super.key,
    this.document,
    this.requireAcceptance = false,
  });

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  bool _isLoading = true;
  LegalDocument? _document;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    if (widget.document != null) {
      setState(() {
        _document = widget.document;
        _isLoading = false;
      });
      return;
    }

    try {
      // Загрузка из кэша или API
      final db = DatabaseService();
      await db.init();
      final cached = db.getCachedTerms();

      if (cached != null) {
        setState(() {
          _document = cached;
          _isLoading = false;
        });
      } else {
        final service = LegalService(
          baseUrl: AppConstants.apiBaseUrl,
          databaseService: db,
        );
        final doc = await service.getTermsOfService();
        setState(() {
          _document = doc;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Пользовательское соглашение')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Пользовательское соглашение')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Ошибка загрузки документа',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadDocument,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользовательское соглашение'),
        actions: widget.requireAcceptance
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // TODO: Share functionality
                  },
                ),
              ],
      ),
      body: _document != null
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Версия: ${_document!.version}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              'Действует с: ${_formatDate(_document!.effectiveFrom)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _document!.content,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                if (widget.requireAcceptance)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Принимаю'),
                      ),
                    ),
                  ),
              ],
            )
          : const Center(child: Text('Документ не найден')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
