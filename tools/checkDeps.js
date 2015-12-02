#!/usr/bin/env node

var extractModule = function(obj, res) {
    if ((typeof obj === 'object') && (typeof obj.module === 'string')) {
        var array = obj.module.split("#"); 
        if (array.length === 2) {
            res[array[0]] = true;
        }
    }
};

var extractDeps = function(obj, res) {
    if (obj && (typeof obj === 'object')) {
        extractModule(obj, res);
        for (var x in obj) {
            extractDeps(obj[x], res);
        }
    }
};

var failed = false;

var pac = require(process.cwd() + '/package.json');
var filter = new RegExp("^caf_");
var result = {};
for (var dep in pac.dependencies) {
     if (filter.test(dep)) {
         result[dep] = true;
     }
}
var newDeps = {};
try {
    var fram =  require(process.cwd() + '/lib/framework.json');
    extractDeps(fram, newDeps);  
} catch(x) {
//    console.log("got " + x);
    console.log("no framework.json");
}

try {
    var framPlus =  require(process.cwd() + '/lib/framework++.json');
    extractDeps(framPlus, newDeps);  
} catch(x) {
//    console.log("got " + x);
    console.log("no framework++.json");
}

try {
    var ca =  require(process.cwd() + '/lib/ca.json');
    extractDeps(ca, newDeps);  
} catch(x) {
    console.log("no ca.json");
}

try {
    var caPlus =  require(process.cwd() + '/lib/ca++.json');
    extractDeps(caPlus, newDeps);  
} catch(x) {
    console.log("no ca++.json");
}

for (var x in newDeps) {
   if (!result[x]) {
       console.log("Error: Add dependency " + x  + " to package.json");
       failed = true;
   }
}

process.exit((failed ? 1 : 0));
