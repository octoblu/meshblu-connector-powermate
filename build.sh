#!/bin/bash

set -e

node_hid_madness() {
  if [ ! -d ./node_modules/node-hid ]; then
    return 0
  fi
  echo '* build node-hid'
  if [ -n "$(which npm)" ] && [ "$TRAVIS_OS_NAME" == 'linux' ]; then
    echo '* installing on linux with hidraw'
    npm install node-hid --driver=hidraw
  fi
  if [ -d ./bin ]; then
    rm -rf ./bin
  fi
  mkdir ./bin
  cp "$(node_hid_bin)" ./bin/HID.node
  sed -ie "s@ require(binding_path)@ require(path.join(process.cwd(), 'bin', 'HID.node'))@" node_modules/node-hid/nodehid.js
}

node_hid_bin(){
  node -e "console.log(require('node-pre-gyp').find('$PWD/node_modules/node-hid/package.json'))"
}

install_deps() {
  if [ -z "$(which node-gyp)" ]; then
    echo '* installing node-gyp'
    yarn global add node-gyp
  fi
  if [ -z "$(which node-pre-gyp)" ]; then
    echo '* installing node-pre-gyp'
    yarn global add node-pre-gyp
  fi
  if [ -z "$(which coffee)" ]; then
    echo '* coffee-script should be required as dev dependency'
    exit 1
  fi
  if [ -z "$(which pkg)" ]; then
    echo '* pkg should be required as dev dependency'
    exit 1
  fi
}

pkg_connector() {
  if [ -d ./dist ]; then
    rm -rf ./dist
  fi
  mkdir ./dist
  echo '* build connector executable'
  pkg --options expose-gc --out-dir ./dist .
}

yarn_install() {
  echo '* yarn install'
  yarn install --check-files --force
}

decoffee() {
  echo '* decoffee this project'
  if [ -d ./src ]; then
    coffee --map --compile src/*.coffee
  fi
  if [ -d ./configs ]; then
    coffee --map --compile configs/**/*.coffee
  fi
  if [ -d ./jobs ]; then
    coffee --map --compile jobs/**/*.coffee
  fi
}

decoffee_index_file() {
  local module_name="$1"
  local require_path="$2"
  local real_file_path="$3"
  if [ ! -d "$PWD/node_modules/$module_name" ]; then
    return 0
  fi
  pushd "$PWD/node_modules/$module_name" > /dev/null
    echo "* decoffee index file in $module_name"
    echo "module.exports = require('$require_path');" > "$real_file_path"
  popd > /dev/null
}

decoffee_module() {
  local module_name="$1"
  local folder_name="$2"
  if [ ! -d "$PWD/node_modules/$module_name" ]; then
    return 0
  fi
  pushd "$PWD/node_modules/$module_name" > /dev/null
    echo "* decoffee module $module_name"
    coffee --map --compile $folder_name/*.coffee
  popd > /dev/null
}

main() {
  yarn_install
  install_deps
  decoffee
  decoffee_module 'meshblu-connector-runner' 'src'
  decoffee_index_file 'meshblu-connector-runner' './src/index.js' './index.js'
  decoffee_index_file 'meshblu-connector-runner' './src/runner.js' './runner.js'
  decoffee_module 'meshblu' 'src'
  decoffee_module 'meshblu-config' 'lib'
  decoffee_index_file 'meshblu-config' './lib/meshblu-config.js' './index.js'
  decoffee_module 'meshblu-connector-schema-generator' 'src'
  decoffee_index_file 'meshblu-connector-schema-generator' './src/schema-generator.js' './index.js'
  decoffee_module 'meshblu-encryption' 'src'
  decoffee_index_file 'meshblu-encryption' './src/encryption.js' './index.js'
  decoffee_module 'meshblu-http' 'src'
  decoffee_index_file 'meshblu-http' './src/meshblu-http.js' './index.js'
  decoffee_module 'srv-failover' 'src'
  decoffee_index_file 'srv-failover' './src/srv-failover.js' './index.js'
  node_hid_madness
  pkg_connector
}

main "$@"
