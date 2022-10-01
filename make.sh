#!/bin/bash

elm-format src --yes
sass scss/custom.scss styles/custom_bootstrap.css
elm make src/Main.elm --output=main.js
