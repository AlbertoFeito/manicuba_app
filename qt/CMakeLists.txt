cmake_minimum_required(VERSION 3.21)

project(ManiCubaQt VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.2 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Sql)

qt_standard_project_setup()

qt_add_executable(manicuba
    main.cpp
    src/db/Database.cpp
    src/config/AppConfig.cpp
    src/config/ThemeController.cpp
    src/services/LicenciaService.cpp
    src/services/CategoriaService.cpp
    src/services/ClienteService.cpp
    src/services/ServicioService.cpp
    src/services/FinanzasService.cpp
    src/services/InventarioService.cpp
    src/services/RedesService.cpp
    src/services/FotoService.cpp
    src/services/CitaService.cpp
    src/services/CamaraService.cpp
    src/services/CompartirService.cpp
)

target_include_directories(manicuba PRIVATE src)

# Secreto de firma de licencias. En producción se pasa con:
#   cmake -S qt -B build -DLICENSE_SECRET="tu-secreto-real"
if(NOT DEFINED LICENSE_SECRET)
    set(LICENSE_SECRET "manicuba-dev-secret")
endif()
target_compile_definitions(manicuba PRIVATE LICENSE_SECRET="${LICENSE_SECRET}")


qt_add_qml_module(manicuba
    URI ManiCuba
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    # Nota: todos los .qml viven directamente bajo qml/ (sin subcarpetas) a
    # propósito. En Android, la resolución de tipos por NOMBRE (import
    # ManiCuba + <Tipo> {}) fallaba de forma sistemática para cualquier tipo
    # cuyo archivo estuviera en una subcarpeta (qml/components/*, qml/screens/
    # **/*), aunque el mismo archivo cargaba perfecto por URL directa y aunque
    # en escritorio nunca falló. Los tipos ya en la raíz (Main, LicenciaGate)
    # nunca tuvieron el problema. Confirmado con sondas en el propio
    # dispositivo antes de aplanar la estructura.
    QML_FILES
        qml/Main.qml
        qml/LicenciaGate.qml
        qml/AppCard.qml
        qml/SectionHeader.qml
        qml/EstadoBadge.qml
        qml/EmptyState.qml
        qml/DonutChart.qml
        qml/LineChartMini.qml
        qml/AyudaDialog.qml
        qml/SelectorFecha.qml
        qml/SelectorHora.qml
        qml/HomeScreen.qml
        qml/ClientesScreen.qml
        qml/ClienteForm.qml
        qml/ClienteDetail.qml
        qml/ServiciosScreen.qml
        qml/ServicioForm.qml
        qml/FinanzasScreen.qml
        qml/IngresoForm.qml
        qml/GastoForm.qml
        qml/InventarioScreen.qml
        qml/ProductoForm.qml
        qml/MovimientosScreen.qml
        qml/RedesScreen.qml
        qml/PostForm.qml
        qml/GaleriaScreen.qml
        qml/AgendaScreen.qml
        qml/CitaForm.qml
        qml/HistorialScreen.qml
)

target_link_libraries(manicuba PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Sql
)

# Configuración específica de Android (solo al compilar cruzado para Android).
if(ANDROID)
    set_target_properties(manicuba PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
        QT_ANDROID_MIN_SDK_VERSION 24
        QT_ANDROID_TARGET_SDK_VERSION 34
        QT_ANDROID_VERSION_NAME "1.0"
        QT_ANDROID_VERSION_CODE 1
    )
endif()
