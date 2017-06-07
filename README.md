# meshblu-connector-powermate

[![Dependency status](http://img.shields.io/david/octoblu/meshblu-connector-powermate.svg?style=flat)](https://david-dm.org/octoblu/meshblu-connector-powermate)
[![devDependency Status](http://img.shields.io/david/dev/octoblu/meshblu-connector-powermate.svg?style=flat)](https://david-dm.org/octoblu/meshblu-connector-powermate#info=devDependencies)
[![Build Status](http://img.shields.io/travis/octoblu/meshblu-connector-powermate.svg?style=flat&branch=master)](https://travis-ci.org/octoblu/meshblu-connector-powermate)
[![Slack Status](http://community-slack.octoblu.com/badge.svg)](http://community-slack.octoblu.com)

[![NPM](https://nodei.co/npm/meshblu-connector-powermate.svg?style=flat)](https://npmjs.org/package/meshblu-connector-powermate)

## Installing

```bash
$ npm install meshblu-connector-powermate
```

### Usage

```bash
$ npm start
```

or with debug

```bash
$ env DEBUG='meshblu-connector-powermate*' npm start
```

### Releasing

```bash
$ npm run package
```

## License

The MIT License (MIT)

Copyright 2017 Octoblu Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


## Build on ARM
```
../dockcross-node/dockcross-linux-armv7 --image octoblu/dockcross-node-linux-armv7 bash -c 'export HOME=/tmp/cache && yarn install && yarn build && meshblu-connector-pkger'
cp HID.node meshblu-connector-powermate meshblu-connector-powermate_2.0.11-1/usr/share/meshblu-connector-pm2/connectors/meshblu-connector-powermate; and rm  -rf meshblu-connector-powermate_2.0.11-1/DEBIAN meshblu-connector-powermate_2.0.11-1/etc; cp -rfp ../.installer/debian/* meshblu-connector-powermate_2.0.11-1 ; and dpkg --build meshblu-connector-powermate_2.0.11-1; and scp meshblu-connector-powermate_2.0.11-1.deb pi@192.168.100.141:; and ssh pi@192.168.100.141 "sudo dpkg -i ./meshblu-connector-powermate_2.0.11-1.deb"
