import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const source = path.join(__dirname, '..', 'use_cases', 'build');
const target = path.join(__dirname, '..', 'flutter', 'assets', 'use_cases');

// Remove target if exists
if (fs.existsSync(target)) {
  fs.rmSync(target, { recursive: true, force: true });
}

// Copy source to target
fs.cpSync(source, target, { recursive: true });

console.log(`✓ Copied ${source} -> ${target}`);
