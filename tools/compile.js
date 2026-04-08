const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const srcDir = path.join(__dirname, '..', 'src');
const binDir = path.join(__dirname, '..', 'bin');
const javaPath = 'C:\\Program Files\\Java\\jdk-19\\bin\\java.exe';
const mxmlcJar = 'C:\\flex\\lib\\mxmlc.jar';
const sourceFile = path.join(srcDir, 'Habbo.as');
const outputFile = path.join(srcDir, 'Habbo.swf');

const startTime = Date.now();

const args = [
  '+flexlib=C:\\flex\\frameworks',
  sourceFile,
  '-static-link-runtime-shared-libraries=true',
  '-swf-version=14',
  '-default-background-color=#000000',
  '-use-network=true',
  '-default-frame-rate', '40',
  '-default-size', '1280', '800'
];

const compiler = spawn(javaPath, ['-jar', mxmlcJar, ...args], { cwd: path.join(__dirname, '..') });

compiler.stdout.on('data', (data) => process.stdout.write(data));
compiler.stderr.on('data', (data) => process.stderr.write(data));

compiler.on('close', (code) => {
  const elapsed = Date.now() - startTime;
  const seconds = Math.floor(elapsed / 1000);
  const milliseconds = elapsed % 1000;

  if (code === 0 && fs.existsSync(outputFile)) {
    const timestamp = new Date().toISOString().replace(/[-:]/g, '').replace('T', '').slice(0, 12);
    const newName = `PRODUCTION-${timestamp}-${milliseconds.toString().padStart(3, '0')}.swf`;
    fs.renameSync(outputFile, path.join(binDir, newName));
    console.log(`Completed! ${seconds}.${milliseconds.toString().padStart(3, '0')}s`);
  } else {
    console.error('Compilation failed with code:', code);
    process.exit(1);
  }
});