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
    src/services/LicenciaService.cpp
    src/services/CategoriaService.cpp
    src/services/ClienteService.cpp
    src/services/ServicioService.cpp
    src/services/FinanzasService.cpp
    src/services/CitaService.cpp
)

target_include_directories(manicuba PRIVATE src)

# Secreto de firma de licencias. En producción se pasa con:
#   cmake -S qt -B build -DLICENSE_SECRET="tu-secreto-real"
if(NOT DEFINED LICENSE_SECRET)
    set(LICENSE_SECRET "manicuba-dev-secret")
endif()
target_compile_definitions(manicuba PRIVATE LICENSE_SECRET="${LICENSE_SECRET}")

# Theme.qml es un singleton QML (marcar ANTES de qt_add_qml_module).
set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(manicuba
    URI ManiCuba
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    QML_FILES
        qml/Main.qml
        qml/Theme.qml
        qml/LicenciaGate.qml
        qml/components/AppCard.qml
        qml/components/SectionHeader.qml
        qml/components/EstadoBadge.qml
        qml/components/EmptyState.qml
        qml/components/DonutChart.qml
        qml/components/LineChartMini.qml
        qml/screens/HomeScreen.qml
        qml/screens/clientes/ClientesScreen.qml
        qml/screens/clientes/ClienteForm.qml
        qml/screens/clientes/ClienteDetail.qml
        qml/screens/servicios/ServiciosScreen.qml
        qml/screens/servicios/ServicioForm.qml
        qml/screens/finanzas/FinanzasScreen.qml
        qml/screens/finanzas/IngresoForm.qml
        qml/screens/finanzas/GastoForm.qml
        qml/screens/agenda/AgendaScreen.qml
        qml/screens/agenda/CitaForm.qml
        qml/screens/agenda/HistorialScreen.qml
)

target_link_libraries(manicuba PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Sql
)
