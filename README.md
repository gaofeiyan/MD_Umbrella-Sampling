# MD_Umbrella-Sampling


gmx grompp -f md_pull.mdp -c npt.gro -p topol.top -r npt.gro -n index.ndx -t npt.cpt -o pull.tpr

gmx mdrun -deffnm pull -pf pullf.xvg -px pullx.xvg

gmx trjconv -s pull.tpr -f pull.xtc -o conf.gro -sep



python2 ./setupUmbrella.py summary_distances.dat 0.2 run-umbrella.sh &> caught-output.txt   #如果output.txt没有文本输出，直接 yes | python2 ./setupUmbrella.py summary_distances.dat 0.2 run-umbrella.sh




touch  squence.sh

for script in frame-*.sh; do
    ./$script
done

