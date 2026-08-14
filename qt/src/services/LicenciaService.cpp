#include "services/LicenciaService.h"

#include <QMessageAuthenticationCode>
#include <QRandomGenerator>
#include <QRegularExpression>
#include <QSettings>

namespace {
// Alfabeto base32 legible (sin I, L, O, U) para leer códigos en voz alta.
const QString kAlphabet = QStringLiteral("0123456789ABCDEFGHJKMNPQRSTVWXYZ");
constexpr int kDeviceChars = 10;
constexpr int kLicenceChars = 16;

const char *kDeviceId = "lic_device_id";
const char *kTrialStart = "lic_trial_started_at";
const char *kLicenseKey = "lic_license_key";

#ifndef LICENSE_SECRET
#define LICENSE_SECRET "manicuba-dev-secret"
#endif
} // namespace

LicenciaService::LicenciaService(QObject *parent) : QObject(parent) {}

QString LicenciaService::secreto() const
{
    return QStringLiteral(LICENSE_SECRET);
}

bool LicenciaService::usandoSecretoDev() const
{
    return secreto() == QStringLiteral("manicuba-dev-secret");
}

// ===== Codificación =====

QString LicenciaService::toBase32(const QByteArray &bytes, int length)
{
    int bits = 0;
    quint32 value = 0;
    QString out;
    for (unsigned char byte : bytes) {
        value = ((value << 8) | byte) & 0xFFFFFFFF;
        bits += 8;
        while (bits >= 5) {
            out.append(kAlphabet.at((value >> (bits - 5)) & 31));
            bits -= 5;
            value = value & ((1u << bits) - 1);
            if (out.length() == length)
                return out;
        }
    }
    while (out.length() < length)
        out.append(kAlphabet.at(0));
    return out;
}

QString LicenciaService::group(const QString &code, int size)
{
    QStringList grupos;
    for (int i = 0; i < code.length(); i += size)
        grupos << code.mid(i, size);
    return grupos.join(QLatin1Char('-'));
}

QString LicenciaService::normalizeCode(const QString &raw)
{
    QString s = raw.toUpper();
    s.remove(QRegularExpression(QStringLiteral("[^0-9A-Z]")));
    s.replace(QRegularExpression(QStringLiteral("[IL]")), QStringLiteral("1"));
    s.replace(QLatin1Char('O'), QLatin1Char('0'));
    return s;
}

QString LicenciaService::newDeviceId()
{
    QByteArray bytes(16, 0);
    QRandomGenerator::system()->fillRange(
        reinterpret_cast<quint32 *>(bytes.data()), 4);
    return toBase32(bytes, kDeviceChars);
}

QString LicenciaService::computeLicence(const QString &deviceId, const QString &secret)
{
    QMessageAuthenticationCode code(QCryptographicHash::Sha256);
    code.setKey(secret.toUtf8());
    const QByteArray mensaje =
        QByteArray("manicuba:v1:") + normalizeCode(deviceId).toUtf8();
    code.addData(mensaje);
    return toBase32(code.result(), kLicenceChars);
}

bool LicenciaService::verifyLicence(const QString &deviceId, const QString &licence,
                                    const QString &secret)
{
    const QString expected = computeLicence(deviceId, secret);
    const QString given = normalizeCode(licence);
    if (given.length() != expected.length())
        return false;
    // Comparación en tiempo constante.
    int diff = 0;
    for (int i = 0; i < expected.length(); ++i)
        diff |= expected.at(i).unicode() ^ given.at(i).unicode();
    return diff == 0;
}

// ===== Estado / persistencia =====

void LicenciaService::init()
{
    QSettings sp;
    if (sp.value(QLatin1String(kDeviceId)).toString().isEmpty())
        sp.setValue(QLatin1String(kDeviceId), newDeviceId());
    if (sp.value(QLatin1String(kTrialStart)).toString().isEmpty())
        sp.setValue(QLatin1String(kTrialStart),
                    QDateTime::currentDateTime().toString(Qt::ISODate));
}

QString LicenciaService::deviceId()
{
    init();
    return QSettings().value(QLatin1String(kDeviceId)).toString();
}

bool LicenciaService::estaLicenciado() const
{
    return !QSettings().value(QLatin1String(kLicenseKey)).toString().isEmpty();
}

bool LicenciaService::activar(const QString &codigo)
{
    const QString id = deviceId();
    if (!verifyLicence(id, codigo, secreto()))
        return false;
    QSettings().setValue(QLatin1String(kLicenseKey), normalizeCode(codigo));
    refrescar();
    return true;
}

void LicenciaService::refrescar()
{
    init();
    QSettings sp;
    m_tipo = calcularEstado(estaLicenciado(),
                            sp.value(QLatin1String(kTrialStart)).toString(),
                            QDateTime::currentDateTime(), m_diasRestantes);
    emit estadoCambiado();
}

LicenciaService::Tipo LicenciaService::calcularEstado(bool licenciado,
                                                      const QString &trialStartedAt,
                                                      const QDateTime &ahora,
                                                      int &diasRestantesOut)
{
    if (licenciado) {
        diasRestantesOut = 0;
        return Tipo::Activa;
    }
    const QDateTime inicio = QDateTime::fromString(trialStartedAt, Qt::ISODate);
    if (trialStartedAt.isEmpty() || !inicio.isValid()) {
        diasRestantesOut = trialDays;
        return Tipo::Prueba;
    }
    // Días completos transcurridos (trunca hacia cero, como Duration.inDays).
    const qint64 diasPasados = inicio.secsTo(ahora) / 86400;
    const int diasRestantes = trialDays - static_cast<int>(diasPasados);
    // Un reloj atrasado no debe alargar la prueba más allá de su duración.
    if (diasRestantes > trialDays) {
        diasRestantesOut = trialDays;
        return Tipo::Prueba;
    }
    if (diasRestantes <= 0) {
        diasRestantesOut = 0;
        return Tipo::Vencida;
    }
    diasRestantesOut = diasRestantes;
    return Tipo::Prueba;
}

QString LicenciaService::estadoTipo() const
{
    switch (m_tipo) {
    case Tipo::Activa: return QStringLiteral("activa");
    case Tipo::Vencida: return QStringLiteral("vencida");
    case Tipo::Prueba:
    default: return QStringLiteral("prueba");
    }
}

QString LicenciaService::deviceIdFormateado() const
{
    const QString id = QSettings().value(QLatin1String(kDeviceId)).toString();
    return group(id, 5);
}
