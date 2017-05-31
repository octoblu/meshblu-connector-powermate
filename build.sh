#!/bin/bash

set -e

cson_compile() {
  for file_path in "$@"; do
    while IFS= read -r -d '' cson_file; do
      cson2json "$cson_file" > "${cson_file/%cson/json}"
    done < <(find "$file_path" -type f -name '*.cson' -print0)
  done
}

main() {
  echo '* yarn install'
  yarn install
  echo '* coffee compile this project'
  coffee --map --compile configs/**/*.coffee src/*.coffee
  echo '* cson compile this project'
  cson_compile ./configs

  pushd ./node_modules/meshblu-connector-runner > /dev/null
    echo '* coffee compile meshblu-connector-runner'
    coffee --map --compile src/*.coffee
    echo "module.exports = require('./src/index.js');" > ./index.js
  popd > /dev/null

  pushd ./node_modules/meshblu > /dev/null
    echo '* coffee compile meshblu'
    coffee --map --compile src/*.coffee
  popd > /dev/null

  pushd ./node_modules/meshblu-config > /dev/null
    echo '* coffee compile meshblu-config'
    coffee --map --compile lib/*.coffee
    echo "module.exports = require('./lib/meshblu-config.js');" > ./index.js
  popd > /dev/null

  pushd ./node_modules/meshblu-connector-schema-generator > /dev/null
    echo '* coffee compile meshblu-connector-schema-generator'
    coffee --map --compile src/*.coffee
    echo "module.exports = require('./src/schema-generator.js');" > ./index.js
  popd > /dev/null

  pushd ./node_modules/meshblu-encryption > /dev/null
    echo '* coffee compile meshblu-encryption'
    coffee --map --compile src/*.coffee
    echo "module.exports = require('./src/encryption.js');" > ./index.js
  popd > /dev/null

  pushd ./node_modules/meshblu-http > /dev/null
    echo '* coffee compile meshblu-http'
    coffee --map --compile src/*.coffee
    echo "module.exports = require('./src/meshblu-http.js');" > ./index.js
  popd > /dev/null

  pushd ./node_modules/srv-failover > /dev/null
    echo '* coffee compile srv-failover'
    coffee --map --compile src/*.coffee
    echo "module.exports = require('./src/srv-failover.js');" > ./index.js
  popd > /dev/null

  echo '* handle node-hid'
  if [ -d ./bin ]; then
    rm -rf ./bin
  fi
  mkdir ./bin
  cp node_modules/node-hid/build/Release/HID.node ./bin/HID.node
  sed -ie "s@require(binding_path)@require(path.join(process.cwd(), 'bin', 'HID.node'))@" node_modules/node-hid/nodehid.js
  if [ -d ./dist ]; then
    rm -rf ./dist
  fi
  mkdir ./dist
  echo '* pkg connector'
  pkg --options expose-gc \
    --out-dir ./dist \
    .
}

main "$@"
