import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import '../config/theme.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  late Future<List<BackupFile>> _backupsFuture;
  String? _message;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  void _loadBackups() {
    _backupsFuture = BackupService.listBackups();
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      final filePath = await BackupService.createBackupFile(storeName: 'ManiCuba');
      setState(() {
        _message = filePath != null
            ? '✅ Backup guardado localmente'
            : '✅ Backup creado exitosamente';
        _loadBackups();
      });
    } catch (e) {
      setState(() => _message = '❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareBackup(BackupFile backup) async {
    setState(() => _isLoading = true);
    try {
      await BackupService.shareBackup();
      setState(() => _message = '✅ Abierto menú de compartir');
    } catch (e) {
      setState(() => _message = '❌ Error al compartir: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup(BackupFile backup) async {
    // Diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Restaurar Backup'),
        content: const Text(
          '¿Estás seguro? Esto REEMPLAZARÁ todos tus datos actuales con los del backup.\n\n'
          'No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final jsonString = await backup.file.readAsString();
      await BackupService.importData(jsonString);
      setState(() => _message = '✅ Datos restaurados exitosamente');
      if (mounted) {
        // Recargar la app después de restaurar
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      setState(() => _message = '❌ Error al restaurar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBackup(BackupFile backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Backup'),
        content: Text('¿Eliminar ${backup.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await BackupService.deleteBackup(backup);
      setState(() {
        _message = '✅ Backup eliminado';
        _loadBackups();
      });
    } catch (e) {
      setState(() => _message = '❌ Error al eliminar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💾 Backup de Datos'),
        backgroundColor: Colors.pink.shade100,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Sección de información
              Container(
                color: Colors.blue.shade50,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Protege tus datos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Haz copias de seguridad de tus clientes, citas y finanzas. '
                      'Si pierdes el teléfono o desinstalan la app, podrás restaurar todo.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _createBackup,
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Crear Backup Ahora'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mensaje de estado
              if (_message != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _message!.startsWith('✅')
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    border: Border.all(
                      color: _message!.startsWith('✅')
                          ? Colors.green
                          : Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.startsWith('✅')
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Lista de backups
              Expanded(
                child: FutureBuilder<List<BackupFile>>(
                  future: _backupsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final backups = snapshot.data ?? [];

                    if (backups.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.backup_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sin backups aún',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Crea tu primer backup toca el botón arriba',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: backups.length,
                      itemBuilder: (context, index) {
                        final backup = backups[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.insert_drive_file,
                                      color: Colors.pink.shade400,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            backup.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                backup.dateFormatted,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const Text(' • '),
                                              Text(
                                                backup.sizeFormatted,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : () => _restoreBackup(backup),
                                      icon: const Icon(Icons.restore, size: 18),
                                      label: const Text('Restaurar'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : () => _shareBackup(backup),
                                      icon: const Icon(Icons.share, size: 18),
                                      label: const Text('Compartir'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: _isLoading
                                          ? null
                                          : () => _deleteBackup(backup),
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
