module.exports = {
  name: require('./package.json').name,
  bin: 'command.js',
  pkg: {
    targets: [
      'node7-macos-x64',
      'node7-linux-x64',
      'node7-linux-x86',
      'node7-win-x64',
      'node7-win-x86',
    ],
    scripts: [
      'index.js',
      'src/*.js',
      'jobs/**/*.js',
      'configs/**/*.js',
      'node_modules/node-hid/nodehid.js',
    ],
    assets: [
      'package.json',
      'jobs/**/*.json',
      'configs/**/*.json',
      'bin/HID.node',
    ]
  }
}
