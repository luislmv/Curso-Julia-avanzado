#!/usr/bin/env sh
#Detecta el intérprete que estamos usando.
ps h -p $$ -o args='' | cut -f1 -d' '
echo "Hola"
