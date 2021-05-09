#!/usr/bin/env bash

#Instala los programas necesario para el taller (Julia, Anaconda y Atom).
#El script puede recibir las siguientes opciones:
# «-j»  o «--julia» Para instalar Julia.
# «-c» o «--anaconda» Para instalar Anaconda.
# «-a» o «--atom» Para instalar Atom.
#Recibe un parámetro opcional, para ubicar (directorio) los paquetes a instalar.
#Por defecto se instalan todos los programas.
#Por defecto se buscan los candidatos en el directorio de descargas del
#usuario que ejecutó el script y en el directorio actual.

#Fuente de las definiciones:
. ./def_interfaz.sh #Para interactuar con el usuario.
. ./def_instalaciones.sh #Para realizar la instalación.

EsRoot #Si no es root, informa y sale con error 1.

#Variables globales.

#Las opciones modifican el valor de estas variables.
#Los siguientes programas serán instalados si su valor es «true».
julia=false
anaconda=false
atom=false
#Directorio donde se encuentran los paquetes a instalar.
dir_instaladores=""
#Ruta de los instaladores.
ruta_julia=""
ruta_anaconda=""
#Variable auxiliar con la lista de parámetros del script.
parametros=$@

#Se revisan las opciones.
AnalisisOpciones $parametros
#Se revisa el parámetro.
AnalisisParametros $parametros
#Se establece la ruta de los paquetes a instalar
ObtenerRutas
#Se prepara un reporte previo a la instalación.
ReportePreInst
#Se confirma que se desea proseguir con la instalación.
ConfirmarInst
#Se instalan los paquetes.
Instalar
#Si se ha llegado hasta aquí, es porque todo ha salido bien.
Salir 0
