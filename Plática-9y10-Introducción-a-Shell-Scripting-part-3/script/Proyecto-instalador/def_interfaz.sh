#Verifica que el script se haya ejecutado como root.
#No recibe parámetros.
EsRoot(){
  if [[ $(id -u) != 0 ]]; then
   Salir 1
  fi
}

#Valida las opciones y establece los programas a instalar.
#Si no se especifica ningún programa, todos serán seleccionados.
#Las opciones siempre deben escribirse antes del parámetro.
#La revisión termina al encontrar un parámetro que no sea una opción.
#Recibe como parámetros a la lista de parámetros del script.
AnalisisOpciones(){
  while [[ -n $1 ]]; do #Recorro todas las opciones.
    case $1 in
      -j | --julia)
        julia=true
        shift
        ;;
      -c | --anaconda)
        anaconda=true
        shift
        ;;
      -a | --atom)
        atom=true
        shift
        ;;
      -*)
        Salir 2 #Sale con error 2 si detecta una opción incorrecta.
        ;;
      *)
        break #Sale del ciclo y de la función si ya no hay más opciones.
        ;;
    esac
  done
  #Opción por defecto.
  #Si ningún programa es seleccionado, los seleccionamos todos.
  # es equivalente a if [[ $julia = false && $anaconda = false && $atom = false ]] ; then
  if ! { $julia || $anaconda || $atom ;}; then
    julia=true; anaconda=true; atom=true
  fi
  parametros=$@ #Se actualizan los parámetros sin las opciones.
}

#Valida los parámetros que no son opciones.
#Sólo se acepta un único parámetro.
#El parámetro debe corresponder al directorio que contiene los paquetes.
#Si no hay parámetros, la función no hace nada.
#Recibe como parámetro a la lista de parámetros del script, menos las opciones detectadas.
AnalisisParametros(){
  case $# in
    0) #Si no hay parámetros.
      return
      ;;
    1) #Si hay un parámetro.
      if [[ -d $1 ]]; then
        dir_instaladores="$1"
      else
        Salir 3 #El parámetro debe ser un directorio.
      fi
      ;;
    *) #Si hay más de un parámetro, sale con error 4.
      Salir 4
      ;;
  esac
}

#En caso de ser necesario, establece la ruta de los paquetes a instalar (Atom no lo necesita).
#Para ello, llama a la función «MenuPaquete» que es la que hace todo el trabajo.
#No se reciben parámetros.
ObtenerRutas(){
  if $julia; then
    echo "-----------------------------"
    echo "Para la instalación de Julia."
    echo "-----------------------------"
    MenuPaquete "julia*.tar.gz" ruta_julia
  fi
  if $anaconda; then
    echo "--------------------------------"
    echo "Para la instalación de Anaconda."
    echo "--------------------------------"
    MenuPaquete "*conda*.sh" ruta_anaconda
  fi
}

#Crea un menú para escoger el paquete a instalar.
#El menú se crea con los candidatos que cumplen el criterio de búsqueda en el
#directorio especificado por parámetro.
#En caso de que no se haya especificado el parámetro, buscará en el directorio
#de «descargas» del usuario actual y en el directorio del script.
#Recibe dos parámetros, el patrón de búsqueda y la variable que almacena la
#ruta del paquete seleccionado.
MenuPaquete(){
  #Se crea el arreglo con la opciones.
  local -n ruta_paquete=$2 #Salida: La ruta del paquete a instalar.
  local paquete="$1" #El patrón del paquete a instalar
  local viejo_IFS=$IFS #almacena el contenido original de «IFS».
  local lista_paquetes="" #Almacena la lista de paquetes candidatos para la instalación.
  local dir_inst=$dir_instaladores #Para no modificar la variable global
  IFS=$'\n' #Cambiamos el separador.

  #Se llena la lista de paquetes candidatos.
  if [[ -z $dir_inst ]]; then
    #Agregamos el directorio de «Descargas».
    dir_inst=$(runuser -s /bin/bash $SUDO_USER -c "xdg-user-dir DOWNLOAD")
    #Busco en «descargas» y además en el directorio actual.
    lista_paquetes=($(find $dir_inst . -maxdepth 1 -iname "$paquete"))
  else
    #Busco en el directorio pasado por parámetro.
    lista_paquetes=($(find $dir_inst -maxdepth 1 -iname "$paquete"))
  fi

  #Si no hay paquetes informo y salgo.
  if [[ ${#lista_paquetes[*]} -eq 0 ]]; then
    Salir 5
  fi

  #Se crea el menú con la lista encontrada.
  PS3="Elija una opción: " #Se cambia «#?» por «Elija una opción: »
  echo "De la siguiente lista:"
  select i in ${lista_paquetes[*]}; do

    #Si se elige una opción no listada, i="".
    if [[ -z $i ]]; then  #Revisamos si i no está vacía.
      echo "Opción no válida." #Informamos del error y repetimos.
    else
      ruta_paquete=$i
      break
    fi
  done
  IFS=$viejo_IFS #Regresamos al separador original.
}

#Crea un reporte previo a la instalación.
#El objetivo es proporcionar información, para que el usuario decida si
#es conveniente proseguir con la instalación o abortar.
#Se usa antes de «ConfirmarInst».
#No recibe parámetros.
ReportePreInst(){
  echo "--------------------------------"
  echo "Informe previo a la instalación:"
  echo "--------------------------------"
  for app in "julia" "anaconda" "atom"; do
    if ${!app}; then #Si cada valor de app almacena el valor true.
      echo "Se instalará el programa «$app»."
    fi
  done
  echo "-----------------------------------------"
}

#Pregunta al usuario si desea seguir con la instalación o abortar.
#Se usa después de «ReportePreInst».
#No recibe parámetros.
ConfirmarInst(){
  local respuesta

  while true; do
    read -p "Desea proseguir con la instalación (s/n): " respuesta
    case $respuesta in
      s | S |si | sí |Si | Sí)
        break
        ;;
      n | N | no | No)
        Salir "abort"
        ;;
      *)
        echo "Respuesta incorrecta."
        ;;
    esac
  done
}

#Se utiliza para finalizar el script.
#Muestra un mensaje antes de finalizar.
#Recibe un parámetro que indica el motivo de la salida.
#Si el valor es «0» o «abort», entonces no ha ocurrido ningún error
#y el valor devuelto es «0».
#En ese caso el mensaje se devuelve por la salida estándar.
#Cualquier otro valor del parámetro, está asociado a algún error en el script.
#En ese caso el valor devuelto es el mismo parámetro de entrada y el mensaje
#se envía por la salida de error estándar.
Salir(){
  case $1 in
    "abort")
      echo "El script «$0» se cerrará sin realizar ninguna instalación."
      exit 0
      ;;
    0)
      echo "La instalación finalizó con éxito."
      ;;
    1)
      echo "El script $0 necesita privilegios de administrador." >&2
      echo "Pruebe a ejecutar sudo $0." >&2
      ;;
    2)
      echo "Opción «${BASH_ARGV[1]}» es incorrecta." >&2
      echo "Las opciones permitidas son:" >&2
      echo "  -j --julia1 -c --anaconda-a --atom -u --usuarios" >&2
      ;;
    3)
      echo "El parámetro $parametros No es un directorio." >&2
      ;;
    4)
      echo "Sólo puede haber un parámetro." >&2
      ;;
    5)
      echo -e "No se encontraron instaladores en:\n$dir_instaladores" >&2
      ;;
    6)
      echo "Problemas al descomprimir el paquete «julia*.tar.gz»." >&2
      ;;
    7)
      echo "No se puede crear el directorio «/opt/julia»." >&2
      ;;
    8)
      echo "Problemas al crear el enlace simbólico para «julia»." >&2
      ;;
    9)
      echo "Problemas al instalar «IJulia»." >&2
      ;;
    10)
      echo "Problemas al instalar «Anaconda»." >&2
      ;;
    11)
      echo "Problemas al crear el enlace simbólico para «anaconda-navigator»." >&2
      ;;
    12)
      echo "Problemas al crear el enlace simbólico para «jupyter-notebook»." >&2
      ;;
    *)
      echo "Opción incorrecta" >&2
      exet 1
      ;;
  esac
  exit $1
}
