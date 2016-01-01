#!/usr/bin/env node

var pac = {};
try {
    pac = require(process.cwd() + '/package.json');
} catch (ex) {
    console.error('Warning: no package.json');
};

var filter = new RegExp("^caf_");
var result = {};
var deps = pac.dependencies || {};
for (var dep in deps) {
     if (filter.test(dep)) {
         result[dep] = true;
     }
}
console.log(Object.keys(result).join(' '));
