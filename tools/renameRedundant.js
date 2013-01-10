#!/usr/bin/env node
var fs = require('fs');
var path = require('path');
var shrw = require(process.cwd() + '/npm-shrinkwrap.json');

var renameDir = function(name, p) {
    var oldName = path.join.apply(path.join, p.concat(name));
    if (fs.existsSync(oldName)) {
        var newName = path.join.apply(path.join,
                                      p.concat(name+ "-delete-12345"));
        fs.renameSync(oldName, newName);
    }
};

var lsDir = function(p) {
    var result = [];
    var all = fs.readdirSync(path.join.apply(path.join, p));
    all.forEach(function(x) {
                    var fileName = path.join.apply(path.join, p.concat(x));
                    var stats = fs.statSync(fileName);
                    if (stats.isDirectory()) {
                        result.push(x);
                    }
                });
    return result;
};

var traverseF = function (desc, p) {
   if (typeof desc === 'object') {
       if (typeof desc.dependencies === 'object') {
           p.push('node_modules');
           var lstDirs = lsDir(p);
           lstDirs.forEach(function(dir) {
                               if (desc.dependencies[dir]) {
                                   p.push(dir);
                                   traverseF(desc.dependencies[dir], p);
                                   p.pop();
                               } else {
                                   renameDir(dir, p);
                               }
                           });
           p.pop();
       } else {
           renameDir('node_modules', p);
       }
   }
};

traverseF(shrw, [process.cwd()]);

