#!/bin/bash
find . -name package.json -exec sed -i 's/\"version\": \"0\.2\.[0-9]*\"/\"version\": \"0.3.0\"/g' {} \;
find . -name package.json -exec sed -i 's/\^0\.2\.0/\^0.3.0/g' {} \;
