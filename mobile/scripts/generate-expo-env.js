// Expo normally writes this file the first time `expo start` runs. It's
// gitignored, so typecheck needs it regenerated on a fresh checkout / CI.
const fs = require('fs');
const path = require('path');

const target = path.join(__dirname, '..', 'expo-env.d.ts');
const template = `/// <reference types="expo/types" />

// NOTE: This file should not be edited and should be in your git ignore
`;

if (!fs.existsSync(target)) {
  fs.writeFileSync(target, template);
}
