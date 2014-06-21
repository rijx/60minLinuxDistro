#!/bin/sh
cd bin
for x in $(ldd ./init | awk '{print $3}' | grep ^/); do mkdir .$(dirname $x); cp $x .$x; done

