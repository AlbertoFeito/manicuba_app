// Pruebas de CompartirNativo mockeando el MethodChannel nativo
// 'app/compartir' (que en Android abre WhatsApp/Instagram/Facebook).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiservicios_app/services/compartir_nativo.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const canal = MethodChannel('app/compartir');
  final nativo = CompartirNativo();

  void mockCanal(Future<Object?>? Function(MethodCall)? handler) {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(canal, handler);
  }

  tearDown(() => mockCanal(null));

  Future<bool> llamar() => nativo.compartirEnApp(
        rutas: const ['/tmp/a.jpg'],
        texto: 'hola',
        paquete: 'com.whatsapp',
      );

  test('devuelve true cuando el canal responde true', () async {
    MethodCall? recibido;
    mockCanal((call) async {
      recibido = call;
      return true;
    });

    expect(await llamar(), isTrue);
    expect(recibido!.method, 'compartirEnApp');
    expect(recibido!.arguments['paquete'], 'com.whatsapp');
  });

  test('devuelve false cuando el canal responde null', () async {
    mockCanal((call) async => null);
    expect(await llamar(), isFalse);
  });

  test('devuelve false ante una PlatformException', () async {
    mockCanal((call) async => throw PlatformException(code: 'ERROR'));
    expect(await llamar(), isFalse);
  });

  test('devuelve false si no hay canal nativo (MissingPluginException)',
      () async {
    mockCanal(null); // sin handler -> MissingPluginException
    expect(await llamar(), isFalse);
  });
}
