# DESCRIPTION:    Base Caf.js image
# TO_BUILD:       docker build --tag ghcr.io/cafjs/caf .

FROM node:18

RUN mkdir -p /usr/src

ENV PATH="/usr/src/node_modules/.bin:${PATH}"

RUN apt-get update && apt-get install -y rsync && apt-get clean

COPY . /usr/src

RUN cd /usr/src && yarn install --production --ignore-optional && yarn cache clean
