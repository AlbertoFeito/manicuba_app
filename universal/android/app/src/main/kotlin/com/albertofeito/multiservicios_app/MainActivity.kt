package com.albertofeito.multiservicios_app

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

private const val CANAL_COMPARTIR = "app/compartir"

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL_COMPARTIR)
            .setMethodCallHandler { call, result ->
                if (call.method == "compartirEnApp") {
                    val rutas = call.argument<List<String>>("rutas") ?: emptyList()
                    val texto = call.argument<String>("texto") ?: ""
                    val paquete = call.argument<String>("paquete") ?: ""
                    result.success(compartirEnApp(rutas, texto, paquete))
                } else {
                    result.notImplemented()
                }
            }
    }

    // Abre [paquete] directo (WhatsApp/Instagram/Facebook) con [texto] y,
    // si hay, las fotos en [rutas] adjuntas. Devuelve false (en vez de
    // lanzar) si la app no está instalada o falla, para que el lado Dart
    // pueda caer al selector genérico del sistema.
    private fun compartirEnApp(rutas: List<String>, texto: String, paquete: String): Boolean {
        return try {
            val intent = Intent(
                if (rutas.size > 1) Intent.ACTION_SEND_MULTIPLE else Intent.ACTION_SEND
            )
            intent.type = if (rutas.isEmpty()) "text/plain" else "image/*"
            intent.setPackage(paquete)
            intent.putExtra(Intent.EXTRA_TEXT, texto)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

            if (rutas.isNotEmpty()) {
                val authority = "$packageName.fileprovider"
                val uris = ArrayList(
                    rutas.map { ruta -> FileProvider.getUriForFile(this, authority, File(ruta)) }
                )
                if (uris.size == 1) {
                    intent.putExtra(Intent.EXTRA_STREAM, uris[0])
                } else {
                    intent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                }
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
