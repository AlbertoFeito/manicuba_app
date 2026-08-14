#!/usr/bin/env node
/**
 * Genera la licencia de un teléfono a partir de su código de equipo.
 *
 *   LICENSE_SECRET=tu-secreto node scripts/generar_licencia.mjs 7K3M9-2QXBD
 *
 * El secreto debe ser el MISMO con el que se compiló el APK
 * (--dart-define=LICENSE_SECRET=...). Si no coinciden, el código no sirve.
 *
 * Guarda este archivo y el secreto en tu máquina; NO los repartas.
 */

import { createHmac } from 'node:crypto';

const ALPHABET = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const LICENCE_CHARS = 16;

function toBase32(bytes, length) {
  let bits = 0;
  let value = 0;
  let out = '';
  for (const byte of bytes) {
    value = ((value << 8) | byte) >>> 0;
    bits += 8;
    while (bits >= 5) {
      out += ALPHABET[(value >>> (bits - 5)) & 31];
      bits -= 5;
      value = value & ((1 << bits) - 1);
      if (out.length === length) return out;
    }
  }
  return out.padEnd(length, ALPHABET[0]);
}

function normalizeCode(raw) {
  return (raw || '')
    .toUpperCase()
    .replace(/[^0-9A-Z]/g, '')
    .replace(/[IL]/g, '1')
    .replace(/O/g, '0');
}

function group(code, size) {
  return (code.match(new RegExp(`.{1,${size}}`, 'g')) || []).join('-');
}

function computeLicence(deviceId, secret) {
  const digest = createHmac('sha256', secret)
    .update(`pelucuba:v1:${normalizeCode(deviceId)}`)
    .digest();
  return toBase32(digest, LICENCE_CHARS);
}

const args = process.argv.slice(2);
let secret = process.env.LICENSE_SECRET || 'pelucuba-dev-secret';
let onlyCode = false;
const positional = [];

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--secret') {
    secret = args[++i] ?? secret;
  } else if (args[i] === '--solo-codigo') {
    onlyCode = true;
  } else if (!args[i].startsWith('--')) {
    positional.push(args[i]);
  }
}

const deviceId = positional[0];
if (!deviceId) {
  console.error('Uso: node scripts/generar_licencia.mjs <codigo-de-equipo>');
  console.error('Ejemplo: node scripts/generar_licencia.mjs 7K3M9-2QXBD');
  process.exit(1);
}

const normalized = normalizeCode(deviceId);
const licence = computeLicence(normalized, secret);

if (onlyCode) {
  process.stdout.write(licence);
} else {
  if (secret === 'pelucuba-dev-secret') {
    console.error(
      'AVISO: usas el secreto de desarrollo. No sirve para vender.\n',
    );
  }
  console.log(`Equipo:   ${group(normalized, 5)}`);
  console.log(`Licencia: ${group(licence, 4)}`);
}
