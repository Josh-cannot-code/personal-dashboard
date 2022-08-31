#!/bin/bash

elm-format src --yes
elm make src/Main.elm --output=main.js
