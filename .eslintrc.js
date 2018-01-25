module.exports = {
    "extends": "eslint:recommended",
    "env" : {
        "browser": true,
        "node": true
    },
    "rules": {
        // enable additional rules, mostly with auto fix...
        "strict" : ["error", "global"],
        "indent": ["error", 4],
        "no-multi-spaces" : ["error"],
        "linebreak-style": ["error", "unix"],
        "quotes": ["error", "single", {"avoidEscape": true}],
        "semi": ["error", "always"],
        "key-spacing": ["error", { "beforeColon": false, "afterColon": true}],
        "keyword-spacing": ["error", { "before": true }],
        "array-bracket-spacing": ["error", "never"],
        "comma-spacing": ["error", {"before": false, "after": true}],
        "semi-spacing": ["error", {"before": false, "after": true}],
        "space-in-parens": ["error", "never"],
        "max-len" : ["error", 80],
        "no-multiple-empty-lines": "error",
        "no-trailing-spaces" : ["error"]
    }
};
