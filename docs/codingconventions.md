# CAF Coding Conventions

## Functional objects

Don't use `new` or `this`. Create objects using closures. A great description of this functional style is in Crockford's book [][#Crockford:2008]. We do that for two reasons: first, we can use methods as callbacks without much binding fuss; second, we have much better encapsulation, and private object state simplifies secure multi-tenancy.

## Do not rely on exceptions

Do not `throw`. Exceptions and asynchronous code do not mix well. Use standard node.js callback conventions to propagate errors (i.e., first argument not a falsy).

## Stick to node.js callback conventions and use the 'async' library

There are many ways to manage asynchronous code. It is not that important which one you choose but it is critical that you don't mix. Most node.js libraries use a simple callback convention. The 'async' library just builds on this convention to provide higher-order abstractions. CAF implements actors using 'async' but it also maintains this callback convention. 

## Name callbacks using nesting levels

We use the following naming scheme for callbacks: cb, cb0, cb1, cb2,... where the number gives you the nesting level. The goal is to avoid calling the wrong callback by making the code a bit easier to read. For example:

    var f = function(x, cb) {
       async.series([
                     function(cb0)  {
                         ...
                         cb0(null, "something");
                     },
                     function(cb0) {
                          var cb1 = function(err, data) {
                            cb0(err, data);
                          }
                          ...
                          cb1(null,"whatever") 
                     
                     }], function(err, data) {
                         cb(err, data)
                     }
                    );   
    }

## Do not use `return` in asynchronous code 

By convention, when the last argument of a function call is a callback, you must use this callback if you need to return a value. To enforce this convention we do not use `return` inside the function. This means that all the execution paths of your function should terminate by calling the callback. For example, instead of writing:

    var f = function(x, cb) {
        if (x > 2) {
            return cb(null, 2); 
        }
        if (x < 1) {
            return cb(null, 1);
        }
        cb(null, 0);
    }

we use the following style:

    var f = function(x, cb) {
        if (x > 2) {
           cb(null, 2);
        } else if (x < 1) {
           cb(null, 1);
        } else {
           cb(null, 0);
        }    
    }

## Callback invocations are always tail calls

When a callback is not used as a tail call it creates very complex control flow. For example:

    var countCalls = 0;
    var f = function(x, cb) {
        async.series([
                      function (cb0) {    
                          cb0(null);
                          countCalls = countCalls + 1;
                      },
                      function (cb0) {   
                           console.log("#calls" + countCalls);
                           cb0(null);
                      }], function(err, data) {
                      ...
                      


will not increment `countCalls` when you would expect...

## Syntax

We are a bit old fashioned. Always use semicolons, commas at the end, no tabs,
four spaces to indent, 80 characters per line, and always use curly braces (opening braces in the same line).

## Documentation

If you are writing a plugin it is critical that `README.md` describes the snippets of JSON that need to be inserted in `framework.json` and `ca.json`; i.e., include the expected names of your modules, and the properties that can be configured. 

It is also important that the proxy class file has proper JSDoc since it defines the interface visible to application code. Use Google's standard type descriptions as shown in [JavaScript Style Guide](http://google-styleguide.googlecode.com/svn/trunk/javascriptguide.xml#JavaScript_Types)

The plan is to automatically extract and aggregate that information for all plugins, but we don't have a tool just yet.

## Semantic versioning and npm shrinkwrap

We will follow [SemVer 2.0](http://semver.org/) policies for version numbers. Our current major version is 0, and this means that you are out of luck, anything may change at any time. 

We always shrinkwrap applications (with npm), and it is crucial that your plugins increment version numbers whenever they change; otherwise, it would be impossible to recreate in a consistent manner an application that uses any of your plugins. Moreover, if you publish an app that uses your own plugins, make sure that the exact versions of those plugins listed in `npm-shrinkwrap.json` are publicly available (e.g., in a public npm directory or github).  

## Use the `caf_` prefix to name your plugin packages

A CAF plugin has little use outside CAF, but we use generic npm packages and directories to facilitate its development. The main npm directory has a flat name space, and it is very important that we do not pollute it with our special-purpose packages. For this reason, always prefix your plug-in package names with 'caf_'. The bonus feature is that we will be able to easily list all the CAF plugins from the npm directory, and extract CAF documentation from them. Our 'Website' app could have a CA that periodically checks for changes in the directory, and rebuilds the documentation when needed.     








[#Crockford:2008]: Douglas Crockford. *JavaScript: The Good Parts*. O'Reilly 2008.
