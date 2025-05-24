import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/ai_service_factory.dart';

/// Widget for selecting AI provider in app settings
class AiProviderSelector extends StatefulWidget {
  final Function(String)? onProviderChanged;

  const AiProviderSelector({
    super.key,
    this.onProviderChanged,
  });

  @override
  State<AiProviderSelector> createState() => _AiProviderSelectorState();
}

class _AiProviderSelectorState extends State<AiProviderSelector> {
  String _selectedProvider = AiServiceFactory.getCurrentProvider();

  @override
  Widget build(BuildContext context) {
    final supportedProviders = AiServiceFactory.getSupportedProviders();

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ai_provider_selection'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'ai_provider_description'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ...supportedProviders
                .map((provider) => _buildProviderTile(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderTile(String provider) {
    final displayName = AiServiceFactory.getProviderDisplayName(provider);
    final capabilities = AiServiceFactory.getProviderCapabilities(provider);
    final isSelected = _selectedProvider == provider;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Radio<String>(
          value: provider,
          groupValue: _selectedProvider,
          onChanged: _onProviderSelected,
        ),
        title: Text(
          displayName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getProviderDescription(provider)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: capabilities.entries
                  .where((entry) => entry.value)
                  .map((entry) => Chip(
                        label: Text(
                          _getCapabilityDisplayName(entry.key),
                          style: const TextStyle(fontSize: 10),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
        ),
        onTap: () => _onProviderSelected(provider),
      ),
    );
  }

  void _onProviderSelected(String? provider) {
    if (provider != null && provider != _selectedProvider) {
      setState(() {
        _selectedProvider = provider;
      });

      try {
        AiServiceFactory.switchProvider(provider);
        widget.onProviderChanged?.call(provider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ai_provider_switched'
                .tr(args: [AiServiceFactory.getProviderDisplayName(provider)])),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ai_provider_switch_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );

        // Revert selection on error
        setState(() {
          _selectedProvider = AiServiceFactory.getCurrentProvider();
        });
      }
    }
  }

  String _getProviderDescription(String provider) {
    switch (provider) {
      case AiServiceFactory.openaiProvider:
        return 'ai_provider_openai_description'.tr();
      case AiServiceFactory.geminiProvider:
        return 'ai_provider_gemini_description'.tr();
      default:
        return '';
    }
  }

  String _getCapabilityDisplayName(String capability) {
    switch (capability) {
      case 'text_analysis':
        return 'ai_capability_text'.tr();
      case 'image_analysis':
        return 'ai_capability_image'.tr();
      case 'file_analysis':
        return 'ai_capability_file'.tr();
      case 'multimodal':
        return 'ai_capability_multimodal'.tr();
      case 'high_quality_vision':
        return 'ai_capability_vision'.tr();
      default:
        return capability;
    }
  }
}
