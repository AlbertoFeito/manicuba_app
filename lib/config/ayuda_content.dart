import 'package:flutter/material.dart';

/// Contenido de la ayuda de una ventana.
class AyudaInfo {
  const AyudaInfo({
    required this.titulo,
    required this.icono,
    required this.puntos,
  });

  final String titulo;
  final IconData icono;
  final List<String> puntos;
}

/// Catálogo de ayudas por ventana. La clave identifica cada pantalla.
class Ayudas {
  static const inicio = AyudaInfo(
    titulo: 'Inicio',
    icono: Icons.home,
    puntos: [
      'El "Resumen del Día" muestra tus citas, ingresos, gastos y balance de hoy en tiempo real.',
      'Usa las "Acciones Rápidas" para crear al vuelo: Nueva Cita, Nuevo Cliente, Registrar Gasto o Post de Redes.',
      'Toca el menú ⋮ (arriba a la derecha) para abrir Servicios, Inventario y la Galería de trabajos.',
      'El resumen se actualiza al volver a esta pestaña.',
    ],
  );

  static const agenda = AyudaInfo(
    titulo: 'Agenda',
    icono: Icons.calendar_today,
    puntos: [
      'Toca un día del calendario para ver sus citas debajo.',
      'Pulsa "Nueva cita" para agendar: elige cliente y servicio (el monto se rellena solo con el precio del servicio).',
      'Toca una cita para cambiar su estado (Pendiente, Confirmada, Completada, Cancelada), editarla o eliminarla.',
      'Al marcar una cita como COMPLETADA, su monto se registra automáticamente como ingreso en Finanzas.',
      'Las citas COMPLETADAS y CANCELADAS salen del calendario y pasan al Historial; el calendario solo muestra las activas (pendientes y confirmadas).',
      'Una cita completada ya no se puede eliminar (protege tus cuentas); si la marcaste por error, usa "Deshacer" desde el Historial.',
      'Abre el Historial desde el menú ⋮ (arriba a la derecha).',
    ],
  );

  static const historial = AyudaInfo(
    titulo: 'Historial de citas',
    icono: Icons.history,
    puntos: [
      'Aquí quedan las citas completadas (verde) y las canceladas (rojo), de la más reciente a la más antigua.',
      'Las completadas no se pueden eliminar (protegen el registro de ingresos); las canceladas sí se pueden eliminar.',
      '"Deshacer" corrige un error: si marcaste una cita como completada o cancelada sin querer, la devuelve al calendario como Pendiente. Si estaba completada, también le quita el ingreso.',
      'El historial de cada cliente también aparece en su ficha (pestaña Clientes).',
    ],
  );

  static const clientes = AyudaInfo(
    titulo: 'Clientes',
    icono: Icons.people,
    puntos: [
      'Busca por nombre o teléfono con la barra superior.',
      'Pulsa "Nuevo" para agregar un cliente (nombre y teléfono son obligatorios).',
      'Toca un cliente para ver su ficha con contacto, notas e historial de citas.',
      'En la ficha, toca el teléfono (o los iconos) para Llamar, abrir WhatsApp, enviar SMS o copiar el número.',
      'Desde la ficha puedes editar o eliminar al cliente.',
      'Un cliente con citas completadas no se puede eliminar (protege tu historial de ingresos); sí puedes editar sus datos.',
    ],
  );

  static const finanzas = AyudaInfo(
    titulo: 'Finanzas',
    icono: Icons.bar_chart,
    puntos: [
      'Arriba ves el balance del mes y los mini-balances de hoy y de la semana.',
      'Usa "Ingreso" o "Gasto" para registrar movimientos manualmente.',
      'Los ingresos de las citas completadas aparecen aquí automáticamente (marcados como "automático" con un candado).',
      'Toca un movimiento para Editarlo o Eliminarlo si lo registraste por error. Los ingresos automáticos de citas no se editan aquí: usa "Deshacer" en el Historial.',
      'Usa los filtros Hoy / Semana / Mes / Todo para acotar los movimientos y el gráfico de gastos.',
      'El gráfico circular reparte tus gastos por categoría del periodo elegido.',
      'Desliza hacia abajo para actualizar los datos.',
    ],
  );

  static const redes = AyudaInfo(
    titulo: 'Redes Sociales',
    icono: Icons.share,
    puntos: [
      'Pulsa "Nuevo post" y escribe título y contenido.',
      'Toca los chips sugeridos para añadir emojis y hashtags al instante.',
      'Puedes agregar fotos al post (de la cámara, la galería del teléfono o tu Galería de trabajos) desde el formulario.',
      'En cada post: Copiar (al portapapeles), Compartir, Editar, marcar Publicado/Pendiente o Eliminar.',
      'Compartir abre WhatsApp, Instagram o Facebook directo, según la plataforma que elegiste al crear el post, con las fotos adjuntas.',
      'Instagram y Facebook no permiten rellenar el texto por política de esas apps: Manicuba lo copia al portapapeles para que solo tengas que pegarlo.',
      'Usa los filtros Todos / Pendientes / Publicados para organizar tus posts.',
    ],
  );

  static const servicios = AyudaInfo(
    titulo: 'Servicios',
    icono: Icons.spa,
    puntos: [
      'Es tu catálogo de servicios con precio y duración.',
      'Pulsa "Nuevo" para agregar uno; toca un servicio o su menú para editar/eliminar.',
      'Estos servicios son los que eliges al crear una cita, y su precio rellena el monto automáticamente.',
    ],
  );

  static const inventario = AyudaInfo(
    titulo: 'Inventario',
    icono: Icons.inventory_2,
    puntos: [
      'Controla tus productos: stock actual, mínimo y costo.',
      'Usa los botones + y − para ajustar el stock rápidamente.',
      'Busca por nombre o categoría con la barra superior.',
      'Los productos por debajo del mínimo se marcan como "Bajo"; toca la tarjeta "Bajo stock" para ver solo esos.',
      'Arriba ves el valor total del inventario.',
    ],
  );

  static const galeria = AyudaInfo(
    titulo: 'Galería de trabajos',
    icono: Icons.photo_library,
    puntos: [
      'Guarda fotos de tus trabajos para tenerlas siempre a mano (offline).',
      'Pulsa "Agregar" para tomar una foto con la cámara o elegirla de la galería.',
      'Toca una foto para verla en grande, compartirla o eliminarla.',
    ],
  );
}
