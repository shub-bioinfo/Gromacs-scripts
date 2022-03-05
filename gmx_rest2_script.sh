#1. To generate topology without #includes 
#gmx_mpi grompp -f nvt.mdp -c nvt.gro -n index.ndx -p topol.top -pp topol_rest2.top

#2. Mention the number of replica and temperature range you want for scaling potential.

#3. Sected the residues in hot region by using "_" after the ATOM label of the like "H12_" with topology file name "topol_rest2.top"

function Scale_Topology(){
# five replicas
nrep=32
# "effective" temperature range
tmin=300
tmax=900
#
# build geometric progression
list=$(
awk -v n=$nrep \
    -v tmin=$tmin \
    -v tmax=$tmax \
  'BEGIN{for(i=0;i<n;i++){
    t=tmin*exp(i*log(tmax/tmin)/(n-1));
    printf(t); if(i<n-1)printf(",");
  }
}'
)
echo "$list" >> TEMP.dat
# clean directory
#rm -fr \#*
#rm -fr topol*

for((i=0;i<nrep;i++))
do
# choose lambda as T[0]/T[i]
# remember that high temperature is equivalent to low lambda
  lambda=$(echo $list | awk 'BEGIN{FS=",";}{print $1/$'$((i+1))';}')
echo "$lambda" >> LAMBDA_VALUES.dat
# process topology
plumed partial_tempering $lambda <  topol_rest2.top >  topol_rest2_sc.top
# clean the scaled topologyies ( anji)
#sed -i '1,12 d' ala_wat_scaled_$i.top
#This part is to run the multidir command  of REST2 in latest version of GROMACS
mkdir rep$i
mv topol_rest2_sc.top rep$i/

done
}
Scale_Topology

#It is for GROMACS 2020 or higher version, which uses "multidir" command to perform replica exchange simulations

for((i=0;i<nrep;i++)) ; do

cd rep$i
cp ../index.ndx .
cp ../nvt.mdp .
cp ../nvt.gro .
cp ../plumed.dat .
#Because it will scale down charges, net charge will not be zero and error will come in generating tpr file.
gmx_mpi grompp -f nvt.mdp -c nvt.gro -p topol_rest2_sc.top -n index.ndx -o mdrun.tpr -maxwarn 2

cd ../
done

#To run simulation
mpirun -np 32 gmx_mpi mdrun -v -deffnm  nvt  -plumed plumed.dat -dlb no  -cpnum 1 -multidir rep0 rep1 ......  rep31 -replex 1000 -hrex
