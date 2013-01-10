#!/usr/bin/env node
var pac = require(process.cwd() + '/package.json');
var filter = new RegExp("^caf_");
var result = "";
for (var dep in pac.dependencies) {
     if (filter.test(dep)) {
         result += dep + " ";
     }
}
console.log(result);
