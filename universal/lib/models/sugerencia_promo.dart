// Parte del Asistente de Promociones (ver docs/ASISTENTE_PROMOCIONES.md).
//
// Una sugerencia de promoción generada automáticamente por AsistenteService
// a partir de los datos del negocio (clientas inactivas, semanas flojas,
// fotos nuevas, etc.). Cada sugerencia trae un borrador de PostRedes listo
// para editar/compartir.

import 'package:flutter/material.dart';

import 'post_redes.dart';

class SugerenciaPromo {
  const SugerenciaPromo({
    required this.id,
    required this.titulo,
    required this.motivo,
    required this.tipo,
    required this.icono,
    required this.borrador,
    this.clienteIds = const [],
  });

  /// Identificador estable de la *clase* de sugerencia (p. ej. 'inactivas',
  /// 'semana_floja', 'mensual', 'foto_12'). Sirve para descartarla sin que
  /// vuelva a salir en la misma sesión.
  final String id;

  final String titulo;

  /// Explicación corta de por qué se sugiere (se muestra bajo el título).
  final String motivo;

  /// Tipo de post asociado ('oferta', 'promocion', 'trabajo', ...), coincide
  /// con las claves de `BusinessConfig.plantillasPost`.
  final String tipo;

  final IconData icono;

  /// Borrador listo para abrir en el formulario de post o para compartir.
  final PostRedes borrador;

  /// Clientas a las que apunta la sugerencia (p. ej. las inactivas del
  /// win-back). Vacío si la promo no va dirigida a clientas concretas.
  final List<int> clienteIds;
}
