import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dotenv/dotenv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:yandex_drive_api/yandex_drive_api.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yandex Drive API Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  YandexDrive? _yandexDrive;
  DiskInfo? _diskInfo;
  List<Resource>? _files;
  bool _isLoading = false;
  String _status = 'Не авторизован';
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _loadEnv();
  }

  Future<void> _loadEnv() async {
    final env = DotEnv(includePlatformEnvironment: true)..load();
    if (env['YANDEX_CLIENT_ID'] == null ||
        env['YANDEX_CLIENT_SECRET'] == null) {
      setState(() {
        _status =
            'Ошибка: отсутствуют YANDEX_CLIENT_ID или YANDEX_CLIENT_SECRET в .env';
      });
    }
  }

  Future<void> _authorize() async {
    setState(() {
      _isLoading = true;
      _status = 'Авторизация...';
    });

    try {
      final env = DotEnv(includePlatformEnvironment: true)..load();
      final file = File('./oauth2_account.json');
      final account = OAuth2Account(
        appPrefix: 'yandex_drive_example',
        tokenStorage: OAuth2TokenStorageJson(file: file),
      );
      final provider = Yandex(
        clientId: env['YANDEX_CLIENT_ID']!,
        clientSecret: env['YANDEX_CLIENT_SECRET']!,
        redirectUri: 'http://localhost:8569/callback',
        scopes: [
          'login:email',
          'login:info',
          "cloud_api:disk.write",
          "cloud_api:disk.read",
          'cloud_api:disk.app_folder',
          'cloud_api:disk.info',
        ],
      );
      final serviceName = provider.name;

      account.addProvider(provider);

      OAuth2Token? token;
      if (file.existsSync()) {
        try {
          token = await account.loadAccount(serviceName, 'vartecmvm');
        } catch (e) {
          // Игнорировать
        }
      }

      token ??= await account.newLogin(serviceName);

      if (token != null) {
        final client = await account.createClient(token);
        _yandexDrive = YandexDrive(client);
        setState(() {
          _status = 'Авторизован';
        });
      } else {
        setState(() {
          _status = 'Ошибка авторизации';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getDiskInfo() async {
    if (_yandexDrive == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final diskInfo = await _yandexDrive!.getDiskInfo();
      setState(() {
        _diskInfo = diskInfo;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка получения информации о диске: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getFiles() async {
    if (_yandexDrive == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final files = await _yandexDrive!.getFiles(limit: 10);
      setState(() {
        _files = files.items;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка получения файлов: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_yandexDrive == null || _selectedFile == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final path = 'disk:/${_selectedFile!.name}';
      final link = await _yandexDrive!.getUploadLink(path);
      final file = File(_selectedFile!.path!);
      final response = await http.put(
        Uri.parse(link.href.toString()),
        body: file.readAsBytesSync(),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Файл загружен')));
      } else {
        throw Exception('Ошибка загрузки: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadFile(Resource file) async {
    if (_yandexDrive == null || file.path == null || file.name == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final link = await _yandexDrive!.getDownloadLink(file.path!);
      final response = await http.get(Uri.parse(link.href.toString()));
      if (response.statusCode == 200) {
        final dir = await getDownloadsDirectory();
        final filePath = '${dir!.path}/${file.name!}';
        final downloadedFile = File(filePath);
        await downloadedFile.writeAsBytes(response.bodyBytes);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Файл скачан: $filePath')));
      } else {
        throw Exception('Ошибка скачивания: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yandex Drive API Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Статус: $_status'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _authorize,
              child: const Text('Авторизоваться'),
            ),
            const SizedBox(height: 16),
            if (_yandexDrive != null) ...[
              ElevatedButton(
                onPressed: _isLoading ? null : _getDiskInfo,
                child: const Text('Получить информацию о диске'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _getFiles,
                child: const Text('Получить список файлов'),
              ),
              const SizedBox(height: 16),
              if (_selectedFile != null)
                Text('Выбран файл: ${_selectedFile!.name}'),
              ElevatedButton(
                onPressed: _isLoading ? null : _pickFile,
                child: const Text('Выбрать файл для загрузки'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    _isLoading || _selectedFile == null ? null : _uploadFile,
                child: const Text('Загрузить файл'),
              ),
              const SizedBox(height: 16),
            ],
            if (_diskInfo != null) ...[
              Text('Общий объем: ${_diskInfo!.totalSpace}'),
              Text('Использовано: ${_diskInfo!.usedSpace}'),
              Text('Корзина: ${_diskInfo!.trashSize}'),
              const SizedBox(height: 16),
            ],
            if (_files != null) ...[
              const Text('Файлы:'),
              Expanded(
                child: ListView.builder(
                  itemCount: _files!.length,
                  itemBuilder: (context, index) {
                    final file = _files![index];
                    return ListTile(
                      title: Text(file.name ?? 'Без имени'),
                      subtitle: Text(file.type ?? 'Неизвестный тип'),
                      trailing: IconButton(
                        icon: Icon(Icons.download),
                        onPressed: () => _downloadFile(file),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (_isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
