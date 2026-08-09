pragma Singleton
import QtQuick

// Paleta y medidas, portadas de lib/config/theme.dart y constants.dart.
QtObject {
    // Colores principales
    readonly property color primary: "#E91E63"      // Rosa intenso
    readonly property color primaryLight: "#F48FB1" // Rosa claro
    readonly property color primaryDark: "#C2185B"  // Rosa oscuro
    readonly property color accent: "#FFC107"       // Ámbar

    // Neutros
    readonly property color textPrimary: "#212121"
    readonly property color textSecondary: "#757575"
    readonly property color divider: "#BDBDBD"
    readonly property color background: "#FAFAFA"
    readonly property color surface: "#FFFFFF"

    // Estado
    readonly property color success: "#4CAF50"
    readonly property color error: "#F44336"
    readonly property color warning: "#FFC107"
    readonly property color info: "#2196F3"

    // Estados de cita
    readonly property color estadoPendiente: "#FFC107"
    readonly property color estadoConfirmada: "#2196F3"
    readonly property color estadoCompletada: "#4CAF50"
    readonly property color estadoCancelada: "#F44336"

    // Medidas
    readonly property int paddingSmall: 8
    readonly property int padding: 16
    readonly property int paddingLarge: 24
    readonly property int radiusSmall: 8
    readonly property int radius: 12
    readonly property int radiusLarge: 16

    function colorEstado(estado) {
        switch (estado) {
        case "confirmada": return estadoConfirmada
        case "completada": return estadoCompletada
        case "cancelada": return estadoCancelada
        default: return estadoPendiente
        }
    }
}
