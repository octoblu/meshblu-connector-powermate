#!/usr/bin/env node
'use strict';

const ConnectorRunner = require('meshblu-connector-runner');
const MeshbluConfig   = require('meshblu-config');

const logger          = console;
logger.debug          = console.info;

const connectorRunner = new ConnectorRunner({
  connectorPath: __dirname,
  meshbluConfig: new MeshbluConfig().toJSON(),
  logger: logger,
});

connectorRunner.run()
