#!/bin/sh
if [ "$1" = "rebase" ]
then
  exec ./bin/dockeruby ./bin/refresh_generations
fi
