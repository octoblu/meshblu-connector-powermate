"use strict"

var path = require("path")
var pathExists = require("path-exists")
var connector = null

if (pathExists.sync(path.resolve("./lib/index.js"))) {
  connector = require("./lib")
} else {
  require("coffee-script/register")
  connector = require("./src")
}

module.exports = connector
