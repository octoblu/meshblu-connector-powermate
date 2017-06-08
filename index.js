"use strict"

var pathExists = require("path-exists")
var connector = null

if (pathExists.sync("./dist/index.js")) {
  connector = require("./dist")
} else {
  require("coffee-script/register")
  connector = require("./src")
}

module.exports = connector
