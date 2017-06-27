module.exports =
  title: "Default Configuration"
  type: "object"
  properties:
    options:
      title: "Options"
      type: "object"
      properties:
        rotationThreshold:
          title: 'Rotation Threshold'
          type: 'integer'
          default: 2
        websocketEnable:
          title: 'Enable Websocket'
          type: 'boolean'
          default: false
        websocketPort:
          title: 'Websocket Port'
          type: 'integer'
          default: 9000
