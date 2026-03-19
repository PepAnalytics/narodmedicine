import 'dart:async';
import 'package:flutter/material.dart';
import '../models/symptom.dart';
import '../services/api_service.dart';
import '../utils/app_constants.dart';

/// Поле ввода симптомов с автодополнением
class SymptomSearchField extends StatefulWidget {
  final ValueChanged<List<String>> onSymptomsSelected;
  final List<String> initialSymptoms;

  const SymptomSearchField({
    super.key,
    required this.onSymptomsSelected,
    this.initialSymptoms = const [],
  });

  @override
  State<SymptomSearchField> createState() => _SymptomSearchFieldState();
}

class _SymptomSearchFieldState extends State<SymptomSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _overlayController = LayerLink();
  final _completer = Completer<void>();

  List<Symptom> _allSymptoms = [];
  List<Symptom> _filteredSymptoms = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;
  final _overlaySize = ValueNotifier<Size>(Size.zero);

  ApiService? _apiService;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialSymptoms.join(', ');
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSymptoms();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  Future<void> _loadSymptoms() async {
    setState(() => _isLoading = true);
    _error = '';

    try {
      // Создаем ApiService с правильным URL для текущей платформы
      _apiService = ApiService(
        baseUrl: AppConstants.apiBaseUrl,
        getUserId: () async => '', // Для загрузки симптомов user_id не нужен
      );

      final symptoms = await _apiService!.getSymptoms();
      setState(() {
        _allSymptoms = symptoms;
        _isLoading = false;
      });
      _completer.complete();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      _completer.complete();
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _filterSymptoms(String query) {
    if (query.isEmpty) {
      setState(() => _filteredSymptoms = []);
      return;
    }

    final normalizedQuery = query.trim().toLowerCase();
    setState(() {
      _filteredSymptoms = _allSymptoms
          .where((s) => s.name.toLowerCase().contains(normalizedQuery))
          .take(10)
          .toList();
    });
    _showOverlay();
  }

  void _onTextChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _filterSymptoms(text);
    });
  }

  void _selectSymptom(Symptom symptom) {
    final currentText = _controller.text;
    final lastCommaIndex = currentText.lastIndexOf(',');
    String newText;

    if (lastCommaIndex == -1) {
      newText = symptom.name;
    } else {
      newText =
          currentText.substring(0, lastCommaIndex + 1) + ' ' + symptom.name;
    }

    _controller.text = newText;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );

    _notifyParent();
    _hideOverlay();
    _focusNode.requestFocus();
  }

  void _notifyParent() {
    final symptoms = _controller.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    widget.onSymptomsSelected(symptoms);
  }

  void _showOverlay() {
    if (_filteredSymptoms.isEmpty) return;

    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _overlaySize.value = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _overlaySize.value.width,
        child: CompositedTransformFollower(
          link: _overlayController,
          offset: Offset(0, _overlaySize.value.height + 8),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _filteredSymptoms.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final symptom = _filteredSymptoms[index];
                  return ListTile(
                    dense: true,
                    title: Text(symptom.name),
                    onTap: () => _selectSymptom(symptom),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    Future.delayed(const Duration(milliseconds: 150), () {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _overlayController,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: 'Симптомы',
          hintText: 'Введите симптомы через запятую',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _error != null && _error!.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.error_outline, color: Colors.red),
                  tooltip: _error,
                  onPressed: _loadSymptoms,
                )
              : null,
        ),
        onChanged: _onTextChanged,
        onSubmitted: (_) => _notifyParent(),
      ),
    );
  }
}
