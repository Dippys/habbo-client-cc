const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const srcDir = path.join(__dirname, '..', 'src');
const binDir = path.join(__dirname, '..', 'bin');
const javaPath = 'C:\\Program Files\\Java\\jdk-19\\bin\\java.exe';
const mxmlcJar = 'C:\\flex\\lib\\mxmlc.jar';
const sourceFile = path.join(srcDir, 'Habbo.as');
const outputFile = path.join(srcDir, 'Habbo.swf');
const stableOutputFile = path.join(binDir, 'Habbo.swf');

const startTime = Date.now();

const args = [
  '+flexlib=C:\\flex\\frameworks',
  sourceFile,
  '-static-link-runtime-shared-libraries=true',
  '-swf-version=25',
  '-default-background-color=#000000',
  '-use-network=true',
  '-use-resource-bundle-metadata=true',
  '-default-frame-rate', '30',
  '-default-size', '800', '600',
  '-accessible=false',
  '-benchmark=false',
  '-optimize=true',
  '-show-unused-type-selector-warnings=true',
  '-strict=true',
  '-warnings=true',
  '-verbose-stacktraces=false'
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
    const archivedOutputFile = path.join(binDir, newName);

    // Keep the latest build at a stable filename for loader.php.
    fs.copyFileSync(outputFile, stableOutputFile);
    // Keep historical timestamped builds for rollback/debugging.
    fs.renameSync(outputFile, archivedOutputFile);

    console.log(`Completed! ${seconds}.${milliseconds.toString().padStart(3, '0')}s`);
    console.log(`Updated: ${stableOutputFile}`);
    console.log(`Archived: ${archivedOutputFile}`);
  } else {
    console.error('Compilation failed with code:', code);
    process.exit(1);
  }
});
