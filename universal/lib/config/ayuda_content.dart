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
      'Los ingresos de las citas completadas y los gastos de las compras de Inventario aparecen aquí automáticamente (marcados como "automático" con un candado).',
      'Toca un movimiento para Editarlo o Eliminarlo si lo registraste por error. Los automáticos no se editan aquí: los ingresos de citas se quitan con "Deshacer" en el Historial, y los gastos de compras con "Deshacer" en el historial del producto.',
      'Usa los filtros Hoy / Semana / Mes / Todo para acotar los movimientos y el gráfico de gastos.',
      'El gráfico circular reparte tus gastos por categoría del periodo elegido.',
      'En la gráfica de tendencia (vista Analíticas) toca cualquier punto: se queda marcado y debajo ves los ingresos, gastos y balance de ese día. Tócalo otra vez o pulsa la X para soltarlo.',
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
      'Instagram y Facebook no permiten rellenar el texto por política de esas apps: la app lo copia al portapapeles para que solo tengas que pegarlo.',
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
      'El gasto se registra cuando COMPRAS, por lo que pagaste. Descontar stock después no vuelve a gastar: ese dinero ya salió.',
      'Usa + para registrar una compra: te pregunta cuántas unidades entraron y cuánto pagaste, y crea el gasto solo en Finanzas. No hace falta apuntarlo dos veces.',
      'Usa − para descontar lo que vas gastando (o lo que se rompe o vence). Esto no toca tus finanzas, solo el stock.',
      'Si compras el mismo producto más caro, el costo unitario se promedia con lo que ya tenías, en vez de reescribir el valor del stock viejo.',
      'Toca un producto para ver su historial: cuánto compraste y cuánto usaste. Desde ahí puedes "Deshacer" una compra o salida que registraste mal.',
      'Al crear un producto que YA tenías, apaga "Registrar el gasto en Finanzas": ese dinero salió antes y no debe contar como gasto de hoy.',
      '"Corregir stock" (menú ⋮) sirve para cuadrar con lo que hay de verdad después de contar, y para arreglar el costo unitario si lo tecleaste mal. No cambia tus finanzas.',
      'No puedes tener dos productos con el mismo nombre en la misma categoría: se partiría el stock en dos y ninguno diría la verdad. Si ya lo tienes, súmale stock con + en vez de crearlo otra vez.',
      'Los productos por debajo del mínimo se marcan como "Bajo"; toca la tarjeta "Bajo stock" para ver solo esos.',
      'Arriba ves el valor total del inventario y lo que llevas comprado en los últimos 30 días.',
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
