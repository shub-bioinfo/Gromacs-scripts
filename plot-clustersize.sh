
filename=clustersize.log

gnuplot <<EOF

set grid
set auto x


set style data histogram
set style fill solid
set boxwidth 0.8

#To rotate the label and fit in it.
set xtics rotate by 45
set xtics font ',8' offset 0,-1

set xrange [4.00 15.00]
#For label in x and y axis
set encoding iso_8859_1
set ylabel "6000 Frames (30 ns trajectory)"
set xlabel "Umbrella CV in ({\305}) "

#This is to set the title of the graph
set title "Cluster Size Ligand heavy atoms clustering at RMSD cutoff 2 {\305}, Umbrella run (8,000 kJ/mol)"

plot "$filename" us 2:xtic(1) lt  rgb 'red' title "Cluster Size ",

set terminal  pngcairo size 1024,720 enhanced color font 'Arial, 11'
set output "clustersize.png"
replot

EOF

