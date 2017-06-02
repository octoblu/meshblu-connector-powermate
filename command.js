#!/usr/bin/env node

const { MeshbluConnectorCommand } = require("meshblu-connector-cli")
const command = new MeshbluConnectorCommand({ argv: process.argv, connectorPath: __dirname })
command.run()
