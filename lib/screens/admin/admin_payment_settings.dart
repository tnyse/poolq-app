import 'package:flutter/material.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/services/app_config_service.dart';

/// Admin form to edit payment destinations stored on `config/appConfig`.
class AdminPaymentSettings extends StatefulWidget {
  const AdminPaymentSettings({Key? key}) : super(key: key);

  @override
  State<AdminPaymentSettings> createState() => _AdminPaymentSettingsState();
}

class _AdminPaymentSettingsState extends State<AdminPaymentSettings> {
  final _config = AppConfigService();
  final _zelleController = TextEditingController();
  final _paypalController = TextEditingController();
  final _venmoController = TextEditingController();
  final _cashAppController = TextEditingController();
  String _defaultMethod = AppConfigService.defaultPaymentMethod;
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!_config.isLoaded) {
      await _config.load();
    }
    setState(() {
      _zelleController.text = _config.zelleDestination;
      _paypalController.text = _config.paypalDestination;
      _venmoController.text = _config.venmoDestination;
      _cashAppController.text = _config.cashAppDestination;
      _defaultMethod = _config.defaultPaymentMethodKey;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _zelleController.dispose();
    _paypalController.dispose();
    _venmoController.dispose();
    _cashAppController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _config.setPaymentDestinations(
        zelle: _zelleController.text,
        paypal: _paypalController.text,
        venmo: _venmoController.text,
        cashApp: _cashAppController.text,
        defaultMethod: _defaultMethod,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment destinations saved'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Save failed: $e\nSign in as a Firebase admin user (userType=admin).',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Payment destinations',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlue,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'These addresses are shown to players when entry fees are due '
          '(regular season). Preseason remains free.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _defaultMethod,
          decoration: const InputDecoration(
            labelText: 'Default payment method',
            border: OutlineInputBorder(),
            helperText: 'Shown first / recommended in the payment prompt',
          ),
          items: const [
            DropdownMenuItem(value: 'zelle', child: Text('Zelle')),
            DropdownMenuItem(value: 'venmo', child: Text('Venmo')),
            DropdownMenuItem(value: 'paypal', child: Text('PayPal')),
            DropdownMenuItem(value: 'cashapp', child: Text('Cash App')),
          ],
          onChanged: _saving
              ? null
              : (v) {
                  if (v == null) return;
                  setState(() => _defaultMethod = v);
                },
        ),
        const SizedBox(height: 16),
        _field(
          controller: _zelleController,
          label: 'Zelle email or phone',
          hint: 'name@bank.com or mobile number',
          icon: Icons.account_balance,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _paypalController,
          label: 'PayPal email',
          hint: 'payments@example.com',
          icon: Icons.payment,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _venmoController,
          label: 'Venmo URL or @handle',
          hint: 'https://venmo.com/u/...',
          icon: Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _cashAppController,
          label: 'Cash App \$cashtag',
          hint: '\$YourCashtag',
          icon: Icons.attach_money,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving…' : 'Save destinations'),
            style: AppTheme.primaryButtonStyle,
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      enabled: !_saving,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
