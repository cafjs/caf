# CAF (Cloud Assistant Framework)

Co-design permanent, active, stateful, reliable cloud proxies with your web app.

See http://www.cafjs.com 

## CAF Top

This repository provides a consistent snapshot of all the other CAF sub-projects, guaranteeing that they will be compatible with each other. 

Most users of CAF will just clone this repository and update submodules recursively, i.e.:

      git submodule update --init --recursive
      
Note that you do need `--recursive` because some repositories such as `caf_core` have their own submodules (e.g., `caf_enyo`).

