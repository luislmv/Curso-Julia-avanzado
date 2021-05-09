c=1+5; g+=2
b=52

println(b)

for i in 1:4
    println(i)
end

## Una manera de crear celdas.
1+8
c=1

## Este texto es opcional.

println("última linea")
##

x=12
f(x)=x^2+1
f(3)
#--- Segunda manera de crar celdas
h=1
h=[0 0]
#---
1+5
# %% Tercera manera de crear celdas
p="Mi nombre es ..."
# %% Comandos más útiles Ctrl+Shift+p - Open the command panel
#=
Ctrl+Enter - Evaluate at the cursor
Ctrl+Shift+Enter - Evaluate the current file
Ctrl+j Ctrl+o - Open the console
Ctrl+j Ctrl+c - Clear the console
Ctrl+j Ctrl+s - Start Julia
Ctrl+j Ctrl+k - Kill the Julia process
Ctrl+j Ctrl+r - Open a REPL
Ctrl+j Ctrl+p - Open the Plot Pane
Ctrl+j Ctrl-d - Get the documentation for the symbol under the cursor
Ctrl+j Ctrl-g - Go to the definition of the symbol under the cursor
=#
##
#using Pkg
#Pkg.add("Plots")
#Pkg.add("PyPlot") using Plots
pyplot() # Choose a backend
plot(rand(4,4)) # This will plot to the plot pane
