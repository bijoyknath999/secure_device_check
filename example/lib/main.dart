import 'package:flutter/material.dart';
import 'package:secure_device_check/secure_device_check.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Device Check',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const SecurityDashboard(),
    );
  }
}

class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({super.key});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  bool? _isEmulator;
  bool? _isCompromised;
  bool _devOptionsEnabled = false;
  bool _usbDebuggingEnabled = false;
  bool _screenProtectionEnabled = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runAllChecks();
  }



  Future<void> _runAllChecks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final emulator = await FlutterSecurityGuard.isEmulator();
      final compromised = await FlutterSecurityGuard.isDeviceCompromised();
      final devOptions =
          await FlutterSecurityGuard.isDeveloperOptionsEnabled();

      if (mounted) {
        setState(() {
          _isEmulator = emulator;
          _isCompromised = compromised;
          _devOptionsEnabled = devOptions['developerOptions'] ?? false;
          _usbDebuggingEnabled = devOptions['usbDebugging'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error running security checks: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleScreenProtection() async {
    try {
      if (_screenProtectionEnabled) {
        await FlutterSecurityGuard.disableScreenProtection();
      } else {
        await FlutterSecurityGuard.enableScreenProtection();
      }
      setState(() => _screenProtectionEnabled = !_screenProtectionEnabled);
      _showSnackBar(
        _screenProtectionEnabled
            ? '🛡️ Screen protection ON — screenshots & recordings blocked'
            : '📷 Screen protection OFF — normal behavior',
      );
    } catch (e) {
      _showSnackBar('Error toggling screen protection: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Device Check'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runAllChecks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Error
                if (_errorMessage != null) ...[
                  Card(
                    color: colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: colorScheme.onErrorContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_errorMessage!,
                                style: TextStyle(
                                    color: colorScheme.onErrorContainer)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Status Banner
                _buildStatusBanner(colorScheme),
                const SizedBox(height: 24),



                // ═══ SCREEN PROTECTION ═══
                Text(
                  '🛡️ Screen Protection',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    secondary: Icon(
                      _screenProtectionEnabled
                          ? Icons.shield
                          : Icons.shield_outlined,
                      color: _screenProtectionEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    title: const Text('Block Screenshots & Recording'),
                    subtitle: Text(
                      _screenProtectionEnabled
                          ? 'ON — captures will be black'
                          : 'OFF — captures allowed',
                    ),
                    value: _screenProtectionEnabled,
                    onChanged: (_) => _toggleScreenProtection(),
                  ),
                ),
                const SizedBox(height: 24),

                // ═══ DEVICE CHECKS ═══
                Text(
                  'Device Security Checks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCheckCard(
                  icon: Icons.phone_android,
                  title: 'Emulator Detection',
                  subtitle: _isEmulator == true
                      ? 'Running on emulator / simulator'
                      : 'Running on physical device',
                  isAlert: _isEmulator == true,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 12),
                _buildCheckCard(
                  icon: Icons.security,
                  title: 'Root / Jailbreak Detection',
                  subtitle: _isCompromised == true
                      ? 'Device is compromised!'
                      : 'Device is clean',
                  isAlert: _isCompromised == true,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 12),
                _buildCheckCard(
                  icon: Icons.developer_mode,
                  title: 'Developer Options',
                  subtitle: _devOptionsEnabled
                      ? 'Developer options are ON${_usbDebuggingEnabled ? ' (USB debugging ON)' : ''}'
                      : 'Developer options are OFF',
                  isAlert: _devOptionsEnabled,
                  colorScheme: colorScheme,
                ),
              ],
            ),
    );
  }

  Widget _buildCheckCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isAlert,
    required ColorScheme colorScheme,
    Widget? trailing,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAlert
              ? colorScheme.errorContainer
              : colorScheme.primaryContainer,
          child: Icon(icon,
              color: isAlert
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimaryContainer),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing ??
            Icon(
              isAlert ? Icons.warning_amber_rounded : Icons.check_circle,
              color: isAlert ? colorScheme.error : Colors.green,
            ),
      ),
    );
  }

  Widget _buildStatusBanner(ColorScheme colorScheme) {
    final hasIssue =
        _isEmulator == true || _isCompromised == true || _devOptionsEnabled;
    return Card(
      color:
          hasIssue ? colorScheme.errorContainer : colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              hasIssue ? Icons.gpp_bad : Icons.gpp_good,
              size: 48,
              color: hasIssue
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasIssue ? 'Security Issues Found' : 'Device Secure',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: hasIssue
                          ? colorScheme.onErrorContainer
                          : colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasIssue
                        ? 'One or more security checks failed.'
                        : 'All security checks passed.',
                    style: TextStyle(
                      color: hasIssue
                          ? colorScheme.onErrorContainer
                          : colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
