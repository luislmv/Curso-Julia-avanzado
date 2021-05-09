# Depuración.

# Debugger.jl
using Debugger

## Ejemplo.
f = function(x, y = 2)
    z = 3
    w=x + y*1 + z*1
    x=w
    x + y + z
end
##
# «@enter» inicia la depuración en REPL.
# El prompt «1|debug>» indica que podemos ejecutar comandos.
# El comando «?» nos imprime la lista de comandos.
@enter f(1)
# Probamos «?», «q», «o», «se», «n», «u» y «c»
##
#Supongamos que debería devolver 12 en lugar de 11.
f(1)
##
@enter f(1)
# Probamos «fr», «`» y «^c».
## Otro ejemplo.
axpy3 = function(a, x, y)
    a*x + y
end

f3 = function()
    a = 2
    x = 3
    y = 4
    println("If a = $a, x = $x, y = $y, then ax + y = $(axpy3(x, y, a))")
end
## Depuramos f3 y probamos «sg».
@enter f3()

## Introducimos un punto de interrupción con @bp.
axpy3 = function(a, x, y)
    @bp
    a*x + y
end

f3 = function()
    a = 2
    x = 3
    y = 4
    println("If a = $a, x = $x, y = $y, then ax + y = $(axpy3(x, y, a))")
end
## En una ejecución normal «@bp», se ignora.
f3()

## Depuramos f3 y ejecutamos «c» para ir a la linea con «@bp».
@enter f3()

## «@run» equivale a «@enter» y luego «c».
@run f3()

## Juno.jl
# Juno tiene un depurador integrado.
## Ejemplo.
f = function(x, y = 2)
    z = 3
    w=x + y*1 + z*1
    x=w
    x + y + z
end
##
Juno.@enter f(1)

## Float64 a Binario.
"""
Cambia la base de un entero decimal a entero binario.
"""
function EntABin(x::Int)
    bin_ent=[] #Almacena los dígitos binarios.
    xaux=x
    dr=(xaux,0) #división entera y resto inicial.
    while xaux > 1
        dr=divrem(xaux,2) #división entera y resto.
        push!(bin_ent, Int(dr[2]))
        xaux=dr[1]
    end
    push!(bin_ent, Int(dr[1]))
    reverse(bin_ent)
end

"""
Cambia la base de la mantisa decimal a la mantisa binario.
El valor no se redondea al más cercano, sino al menor más cercano.
"""
function MantBin(x::Float64, n::Int)
    bin_mant=[]
    #Sólo necesitamos la mantisa.
    xaux=BigFloat(string(x))%big"1.0" #Se trabaja con Big, para evitar errores de redondeo en los cálculos.
    for i in 1:n
        xaux*=big"2.0"
        dr=divrem(xaux, big"1.0")
        push!(bin_mant, Int(dr[1])) #Se añade la parte entera convertida a entero (0 o 1).
        xaux=dr[2] #Sólo nos quedamos con la parte fraccionaria, para repetir el proceso.
    end
    return bin_mant
end

"""
Construye los 11 dígitos del exponente de un Float64 en binario.
Se le pasa el exponente como un entero decimal.
Para convertir usa la función EntABin definida al principio del notebook.
Los dígitos faltantes se rellenan con ceros.
Devuelve un arreglo con los 11 elementos.
"""
function ExpFloat64ABin(x::Int)
    bin_exp=EntABin(x+1023)
    N=11-length(bin_exp)
    if N>0
        bin_exp = reverse(bin_exp)
        for i in 1:N
            push!(bin_exp, Int(0))
        end
        bin_exp = reverse(bin_exp)
    end
    return bin_exp
end

"""
Encuentra la n, para la cual x están en [2^n, 2^{n+1}).
Si x está normalizado, entonces -1022<=n<=1023.
Si x es subnormal, n=-1023, si es inf o NaN, n=1024.
Se devuelve un arreglo con los 11 dígitos en binario para n. También se devuelve n.
"""
function ObtenerExpBin(x::Float64)
    E_min, E_max = -1022, 1023
    a, b = E_min, E_max

    #Se atienden los casos extremos.
    if x<2.0^E_min
        return [ExpFloat64ABin(E_min - 1), E_min - 1] #11 ceros para los números subnormales.
    elseif x==2.0^E_min
        return [ExpFloat64ABin(E_min), E_min] #Si es el menor número normalizado representable.
    elseif Inf>x>=2.0^E_max
        return [ExpFloat64ABin(E_max), E_max] #Arreglo del exponente mas grande antes de Inf.
    elseif isinf(x) || isnan(x)
        return [ExpFloat64ABin(E_max+1), E_max+1] #Inf y NaN tienen el mismo exponente, 11 unos.
    end

    #Este algoritmo busca la n, de manera similar
    #al método de bisección para hallar ceros de funciones.
    while b != a+1
        c=(a+b)÷2
        exp_c = 2.0^c
        if exp_c == x
            return [ExpFloat64ABin(c), c]
        end
        2.0^a < x < exp_c ? b=c : a=c
    end
    return [ExpFloat64ABin(a), a]
end

"""
Convierte un Float64 «x» a binario según la norma IEE 750 (la mantisa no se redondea al más cercano).
Para obtener la mantisa, se utiliza la función MantBin definida al principio del notebook.
Devuelve una cadena «s», con la representación binaria de «x».
"""
function Float64Abin(x::Float64)
    bin=zeros(Int8, 64) #Se rellena de ceros, para Inf y NaN.
    E_nin, E_max = -1022, 1023
    mant = []

    #Añadimos el signo.
    if signbit(x)
        bin[1]=1
    end

    #Los casos especiales Inf y NaN.
    if isinf(x)
        bin[2:12].=1
        return join(string.(bin))
    elseif isnan(x)
        bin[2:13].=1
        return join(string.(bin))
    end

    #Encontramos los 11 dígitos del exponente.
    expo = ObtenerExpBin(abs(x))

    #Si el número es subnormal, hay que sumarle uno al exponente.
    if expo[2]==-1023
       expo[2]+=1
    end

    #Se obtiene el cociente x/2^n, -1022<=n<=1023.
    fac = abs(BigFloat(string(x))/big"2.0"^(expo[2]))

    #Se obtiene la mantisa con 52 dígitos.
    mant = MantBin(Float64(fac), 52)

    #Construimos la cadena con la notación en binario.
    return join(string.([bin[1]; expo[1]; mant]))
end
## Depurar «Float64Abin»
Juno.@run Float64Abin(2.225073858507202e-308)
