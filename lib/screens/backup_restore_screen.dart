import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> with SingleTickerProviderStateMixin {
  final BackupService _backupService = BackupService();
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String? _lastBackupDate;
  late AnimationController _animationController;
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadLastBackupDate();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLastBackupDate() async {
    setState(() {
      _lastBackupDate = null;
    });
  }

  Future<void> _performBackup() async {
    setState(() => _isBackingUp = true);

    try {
      await _backupService.shareBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup file ready to share!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _copyBackupToClipboard() async {
    setState(() => _isBackingUp = true);

    try {
      final jsonString = await _backupService.exportToJson();
      await Clipboard.setData(ClipboardData(text: jsonString));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup copied to clipboard!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copy failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _performRestore({bool merge = false}) async {
    final jsonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        ),
        child: AlertDialog(
          title: const Text('Restore Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: merge ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: merge ? Colors.orange : Colors.red),
                ),
                child: Text(
                  merge
                      ? 'Merge: Pagsamahin ang backup sa existing data.'
                      : 'Replace: Burahin ang lahat ng existing data at ilagay ang backup.',
                  style: TextStyle(
                    fontSize: 12,
                    color: merge ? Colors.orange : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'I-paste ang JSON content dito:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: jsonController,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'I-paste ang JSON content ng backup file...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kanselahin'),
            ),
            ElevatedButton(
              onPressed: () async {
                final jsonString = jsonController.text.trim();
                if (jsonString.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pakilagyan ng JSON content')),
                  );
                  return;
                }

                Navigator.pop(context);
                setState(() => _isRestoring = true);

                try {
                  final success = await _backupService.restoreFromJson(jsonString, merge: merge);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(merge ? 'Data merged successfully!' : 'Data restored successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Restore error: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isRestoring = false);
                }
              },
              child: const Text('I-restore'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        ),
        child: AlertDialog(
          title: const Text('Restore Data'),
          content: const Text(
            'Piliin ang paraan ng restore:\n\n'
            'Replace: Burahin ang lahat ng existing data at ilagay ang backup.\n'
            'Merge: Pagsamahin ang backup sa existing data.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _performRestore(merge: false);
              },
              child: const Text('Replace', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _performRestore(merge: true);
              },
              child: const Text('Merge', style: TextStyle(color: Colors.orange)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kanselahin'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.04,
                vertical: constraints.maxHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset(0, (1 - value) * 30),
                      child: Opacity(opacity: value, child: child),
                    ),
                    child: _buildBackupCard(),
                  ),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset(0, (1 - value) * 30),
                      child: Opacity(opacity: value, child: child),
                    ),
                    child: _buildRestoreCard(),
                  ),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset(0, (1 - value) * 30),
                      child: Opacity(opacity: value, child: child),
                    ),
                    child: _buildInfoSection(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackupCard() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = 1),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_hoveredIndex == 1 ? 1.01 : 1.0),
        child: Card(
          elevation: _hoveredIndex == 1 ? 4 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A6B8A), Color(0xFF003547)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.backup, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Backup Data',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'I-export ang iyong database sa JSON file',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_lastBackupDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Huling backup: $_lastBackupDate',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: AnimatedButton(
                        onPressed: _isBackingUp ? null : _performBackup,
                        isLoading: _isBackingUp,
                        icon: Icons.share,
                        label: 'I-share',
                        color: const Color(0xFF1A6B8A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedButton(
                        onPressed: _isBackingUp ? null : _copyBackupToClipboard,
                        isLoading: _isBackingUp,
                        icon: Icons.copy,
                        label: 'I-copy',
                        color: const Color(0xFF1A6B8A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreCard() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = 2),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_hoveredIndex == 2 ? 1.01 : 1.0),
        child: Card(
          elevation: _hoveredIndex == 2 ? 4 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFC4793A), Color(0xFF4A2800)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restore, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restore Data',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'I-restore ang database mula sa JSON file',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: AnimatedButton(
                    onPressed: _isRestoring ? null : _showRestoreDialog,
                    isLoading: _isRestoring,
                    icon: Icons.cloud_download,
                    label: 'I-restore',
                    color: const Color(0xFFC4793A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Impormasyon',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fixed: Made text scrollable and added wrapping
          SingleChildScrollView(
            child: Text(
              '• Ang backup ay naglalaman ng lahat ng data (products, sales, customers, expenses, etc.)\n'
              '• Para mag-backup: Pindutin ang "I-share" para i-save sa Drive/Email, o "I-copy" para kopyahin sa clipboard\n'
              '• Para mag-restore: Kopyahin ang JSON content ng backup file at i-paste sa restore dialog\n'
              '• Replace: Burahin ang lahat ng existing data at ilagay ang backup (gamitin kapag nagbago ng device)\n'
              '• Merge: Pagsamahin ang backup sa existing data (gamitin para idagdag lang data)',
              style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.5),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData icon;
  final String label;
  final Color color;

  const AnimatedButton({
    super.key,
    this.onPressed,
    required this.isLoading,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered && widget.onPressed != null ? 1.02 : 1.0),
        child: ElevatedButton.icon(
          onPressed: widget.onPressed,
          icon: widget.isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(widget.icon),
          label: Text(widget.isLoading ? 'Naglo-load...' : widget.label),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}