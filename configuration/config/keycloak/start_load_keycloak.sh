#!/bin/sh

# This script is auto-executed on JBoss startup synchronously
# however we want to load the realm after JBoss starts in another thread
# so this script simple starts the load_realm script in the background
/tmp/load_realm.sh & 
echo Done