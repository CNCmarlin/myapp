import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../services/secure_storage_service.dart';

class ApiKeyPage extends StatefulWidget {
  // 🛡️ SHIELD: Validation Callback
  // Rationale: Communicates valid state to parent OnboardingScreen to enable/disable "Next".
  final Function(bool) onValidationChanged;
  
  const ApiKeyPage({super.key, required this.onValidationChanged});

  @override
  State<ApiKeyPage> createState() => _ApiKeyPageState();
}

// 🛡️ SHIELD: Persistent AI Setup & Verification
// Change: Added pre-loading of existing keys and dynamic status icons.
// Rationale: Ensures the user knows exactly when the key is active and stored.
class _ApiKeyPageState extends State<ApiKeyPage> {
  final _controller = TextEditingController();
  bool _isValidating = false;
  bool _isVerified = false; // NEW: Track verification status
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 🛡️ SHIELD: Pre-load existing key
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkExistingKey());
  }

  Future<void> _checkExistingKey() async {
    final key = await context.read<SecureStorageService>().getGeminiKey();
    if (key != null && key.isNotEmpty) {
      _controller.text = key;
      // Re-validate the existing key to ensure it's still active
      await _validateAndSave(key, silent: true); 
    }
  }

  Future<void> _validateAndSave(String key, {bool silent = false}) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) {
      widget.onValidationChanged(false);
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _isVerified = false;
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: cleanKey);
      await model.generateContent([Content.text('Ping')]);

      await context.read<SecureStorageService>().saveGeminiKey(cleanKey);
      
      setState(() => _isVerified = true);
      widget.onValidationChanged(true);
      
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("API Key Verified!"), backgroundColor: Colors.green),
        );
      }
    } on GenerativeAIException catch (e) {
      debugPrint("Gemini AI Error: ${e.message}");
      setState(() {
        if (e.message.contains('User location is not supported')) {
          _errorMessage = "Region Error: Gemini is not available in your current country.";
        } else if (e.message.contains('API_KEY_INVALID')) {
          _errorMessage = "Key Error: The API key is invalid. Try a new one.";
        } else {
          _errorMessage = "AI Error: ${e.message}";
        }
      });
      widget.onValidationChanged(false);
    } catch (e) {
      debugPrint("General AI Error: $e");
      setState(() => _errorMessage = "Connection Error: Check your internet.");
      widget.onValidationChanged(false);
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isVerified ? Icons.check_circle : Icons.vpn_key, 
            size: 64, 
            color: _isVerified ? Colors.green : Colors.blue
          ),
          const SizedBox(height: 24),
          const Text("Gemini AI Setup", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            _isVerified 
              ? "Your API Key is active and verified." 
              : "To generate programs locally, you need a Gemini API Key.",
            textAlign: TextAlign.center,
          ),
           const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => launchUrl(Uri.parse('https://aistudio.google.com/app/apikey')),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text("Get Key"),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => launchUrl(Uri.parse('https://ai.google.dev/gemini-api/docs/api-key')),
                icon: const Icon(Icons.help_outline, size: 16),
                label: const Text("Help"),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            obscureText: true, // 🛡️ SHIELD: Mask the key for privacy
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Enter API Key',
              hintText: 'AIzaSy...',
              errorText: _errorMessage,
              // 🛡️ SHIELD: Dynamic Icon Logic
              // Change: Shows Spinner during check, Green Check when verified, or Arrow to verify.
              suffixIcon: _isValidating 
                ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                : _isVerified 
                  ? const Icon(Icons.verified, color: Colors.green)
                  : IconButton(
                      icon: const Icon(Icons.arrow_forward), 
                      onPressed: () => _validateAndSave(_controller.text)
                    ),
            ),
            onSubmitted: (val) => _validateAndSave(val),
          ),
          if (_errorMessage != null)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text("Ensure you have no spaces and your key is active.", style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}