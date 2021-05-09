#Inicia la instalación de los programas seleccionados.
#En caso de que un programa esté elegido para ser instalado
#llama a la función encargada de su instalación.
#No recibe parámetros.
Instalar(){
  if $anaconda; then
    InstalarAnaconda
  fi
  if $julia; then
    InstalarJulia
  fi
  if $atom; then
    InstalarAtom
  fi
}

#Instala Julia.
#Copia el directorio descomprimido dentro de «/opt/julia»
#Si el directorio dentro de «/opt/julia» existe, lo remplaza.
#De ser necesario, se crea el directorio «/opt/julia».
#Crea un enlace simbólico para «Julia» en «/usr/local/bin».
#No recibe parámetros.
InstalarJulia(){
  local ruta_opt_julia="/opt/julia/" #Ruta inicial para ubicar julia.
  #Descomprime el paquete en el directorio actual y almacena
  #la salida estándar del proceso de descompresión.
  local salida_tar=($(tar -vxzf "$ruta_julia"))
  ComprobarErr $? 6

  mkdir -p $ruta_opt_julia #Se crea el directorio contenedor.
  ComprobarErr $? 7

  #El primer elemento de «salida_tar» es el nombre del directorio que se
  #ha descomprimido. Se añade a la ruta de julia para completarla.
  ruta_opt_julia+=${salida_tar[0]}

  #Si existe el directorio lo eliminamos para que no haya error al mover el nuevo.
  if [[ -d "$ruta_opt_julia" ]]; then
    rm -r "$ruta_opt_julia"
  fi
  #Movemos el directorio al lugar de destino.
  mv "./${salida_tar[0]}" "/opt/julia"
  #Se crea el enlace simbólico para que sea visible por el sistema.
  ln -s --force "$ruta_opt_julia/bin/julia" "/usr/local/bin/julia"
  ComprobarErr $? 8

  #Si se instaló anaconda, instalamos «IJulia».
  if $anaconda; then
    #Es necesario que lo lance el usuario «actual» porque se instala en la el directorio personal.
   echo 'using Pkg; Pkg.add("IJulia")' | runuser -s /bin/bash $SUDO_USER -c "julia"
    ComprobarErr $? 9
  fi
}

#Instala o actualiza Anaconda desde su script de instalación.
#Crea enlaces simbólicos para algunos de sus ejecutables más usados.
#No recibe parámetros.
InstalarAnaconda(){
  #Se ejecuta el instalador con las opciones y parámetros deseados.
  bash $ruta_anaconda -ubp /opt/anaconda3/
  ComprobarErr $? 10
  ln -s --force "/opt/anaconda3/bin/anaconda-navigator" "/usr/local/bin/condanav"
  ComprobarErr $? 11
  ln -s --force "/opt/anaconda3/bin/jupyter-notebook" "/usr/local/bin/jnote"
  ComprobarErr $? 12
  ln -s --force "/opt/anaconda3/bin/conda" "/usr/local/bin/conda"
  ComprobarErr $? 13
}

#Instala Atom desde su repositorio.
#Añade el repositorio y la llave pública.
#Luego actualiza la información de los repositorios e instala.
#No recibe parámetros.
InstalarAtom(){
  #Se obtiene la llave GPG con wget y se añade con apt-key en archivo /etc/apt/trusted.gpg.
  wget -qO - https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add

  #Se crea un archivo .list y se escribe la linea deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main
  sudo bash -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'

  apt-get update #actualizamos los índices de cada repositorio añadido.

  apt-get -y install atom #instalamos.

}

#Comprueba si el proceso anterior terminó con errores.
#En caso de error llama a la función «Salir».
#Recibe dos parámetros. El primero es el estado de salida del proceso
#que se desea comprobar y el segundo es el error que se quiere reportar
#a la función Salir, en caso de error.
ComprobarErr(){
  if [[ $1 != 0 ]]; then
    Salir $2
  fi
}
