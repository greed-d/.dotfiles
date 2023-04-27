#!/bin/bash

# Pre-requisistes
# paru
# sudo

sudo pacman -S asar
paru -S staruml
cd /opt/StarUML/resources
sudo cp app.asar app.asar.bak && sudo asar extract app.asar app
sudo sed -i "s/setStatus(this, false)/setStatus(this, true)/g" app/src/engine/license-manager.js
sudo sed -i "s/UnregisteredDialog.showDialog()//g" app/src/engine/license-manager.js
sudo asar pack app app.asar
