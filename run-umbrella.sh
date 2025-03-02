#!/bin/bash

# Short equilibration
gmx grompp -f npt_umbrella.mdp -c confXXX.gro -r confXXX.gro -p topol.top -n index.ndx -o nptXXX.tpr -maxwarn 99
gmx mdrun -deffnm nptXXX -pme gpu -nb gpu -bonded gpu -v

# Umbrella run
gmx grompp -f md_umbrella.mdp -c nptXXX.gro -r nptXXX.gro -t nptXXX.cpt -p topol.top -n index.ndx -o umbrellaXXX.tpr -maxwarn 99
gmx mdrun -deffnm umbrellaXXX -pme gpu -nb gpu -bonded gpu -v


