#pragma once

#include <QDateTime>
#include <QObject>
#include <QString>

// Licencia por dispositivo, verificada 100% sin conexión.
// Port 1:1 de lib/services/licencia_service.dart: mismo alfabeto base32, mismo
// mensaje HMAC-SHA256 ("manicuba:v1:<deviceId normalizado>") y misma lógica de
// estado, de modo que las licencias ya emitidas siguen siendo válidas.
class LicenciaService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString estadoTipo READ estadoTipo NOTIFY estadoCambiado)
    Q_PROPERTY(int diasRestantes READ diasRestantes NOTIFY estadoCambiado)
    Q_PROPERTY(bool licenciado READ estaLicenciado NOTIFY estadoCambiado)
    Q_PROPERTY(bool bloqueada READ bloqueada NOTIFY estadoCambiado)
    Q_PROPERTY(QString deviceIdFormateado READ deviceIdFormateado NOTIFY estadoCambiado)
    Q_PROPERTY(bool usandoSecretoDev READ usandoSecretoDev CONSTANT)

public:
    enum class Tipo { Activa, Prueba, Vencida };
    Q_ENUM(Tipo)

    explicit LicenciaService(QObject *parent = nullptr);

    // Crea el código de equipo y la fecha de inicio de prueba si no existen.
    Q_INVOKABLE void init();
    // Recalcula el estado y emite estadoCambiado().
    Q_INVOKABLE void refrescar();
    // Intenta activar; si el código es válido lo guarda y devuelve true.
    Q_INVOKABLE bool activar(const QString &codigo);

    QString estadoTipo() const;
    int diasRestantes() const { return m_diasRestantes; }
    bool estaLicenciado() const;
    bool bloqueada() const { return m_tipo == Tipo::Vencida; }
    QString deviceIdFormateado() const;
    bool usandoSecretoDev() const;

    // ===== Lógica pura (estática, testeable) =====
    static QString toBase32(const QByteArray &bytes, int length);
    static QString normalizeCode(const QString &raw);
    static QString group(const QString &code, int size);
    static QString computeLicence(const QString &deviceId, const QString &secret);
    static bool verifyLicence(const QString &deviceId, const QString &licence,
                              const QString &secret);
    static Tipo calcularEstado(bool licenciado, const QString &trialStartedAt,
                               const QDateTime &ahora, int &diasRestantesOut);

    static constexpr int trialDays = 15;

signals:
    void estadoCambiado();

private:
    QString deviceId();
    QString secreto() const;
    static QString newDeviceId();

    Tipo m_tipo = Tipo::Prueba;
    int m_diasRestantes = trialDays;
};
