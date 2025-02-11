#!/bin/sh
if [ "$1" = "rebase" ]
then
  exec ./bin/dc ./bin/refresh_generations
fi
