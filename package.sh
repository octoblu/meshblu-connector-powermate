#!/bin/bash

set -e

node_hid_madness() {
  if [ ! -d ./node_modules/node-hid ]; then
    return 0
  fi
  echo '* build node-hid'
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
  if [ -d ./deploy ]; then
    rm -rf ./deploy
  fi
  mkdir ./deploy
  echo '* build connector executable'
  pkg --options expose-gc --target "$PACKAGE_TARGET" --out-dir ./deploy .
}

yarn_install() {
  echo '* yarn install'
  yarn install --check-files --force
}

yarn_build() {
  echo '* yarn build'
  yarn build
}

main() {
  yarn_install
  yarn_build
  install_deps
  node_hid_madness
  pkg_connector
}

main "$@"
