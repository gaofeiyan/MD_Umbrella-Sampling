# MD_Umbrella-Sampling

gmx pdb2gmx -f protein_prepared.pdb -o protein.gro -p topol.top -ignh

gmx editconf -f complex.gro -o newbox.gro -box 6.560 4.362 12  #可以用pymol或者VMD计算蛋白距离，要注意，拉动的距离一定要小于盒子的一半（主要为了区别于PBC周期边界条件）

> pbc box #VMD命令，对盒子进行观察

gmx solvate -cp newbox.gro -cs spc216.gro -o solv.gro -p topol.top

gmx grompp -f ions.mdp -c solv.gro -p topol.top -o ions.tpr

gmx genion -s ions.tpr -o solv_ions.gro -p topol.top -pname NA -nname CL -neutral -conc 0.1

gmx grompp -f minim.mdp -c solv_ions.gro -p topol.top -o em.tpr

gmx mdrun -v -deffnm em

gmx grompp -f npt.mdp -c em.gro -p topol.top -r em.gro -o npt.tpr

gmx mdrun -deffnm npt

gmx make_ndx -f npt.gro #recognize the corresponding names of protein and ligand
                     
rename 13 MOL1    #记得把重复的MOL分开，if 两个MOL，一个就命名为MOL1，另一个保持不变MOL，很重要


gmx grompp -f md_pull.mdp -c npt.gro -p topol.top -r npt.gro -n index.ndx -t npt.cpt -o pull.tpr

gmx mdrun -deffnm pull -pf pullf.xvg -px pullx.xvg

gmx trjconv -s pull.tpr -f pull.xtc -o conf.gro -sep

python2 ./setupUmbrella.py summary_distances.dat 0.2 run-umbrella.sh &> caught-output.txt   #如果output.txt没有文本输出，直接 yes | python2 ./setupUmbrella.py summary_distances.dat 0.2 run-umbrella.sh

chmod +x frame-*.sh  #将生成的 .sh 文件给予权限

touch  squence.sh  # 将 .sh 文件一个个进行批次运行

```
for script in frame-*.sh; do

    ./$script

.done
```
nohup bash ./squence.sh &



touch tpr-files.dat    #分别将生成的umbrellaX.tpr （ls umbrella*.tpr 再Excel整理）

touch pullf-files.dat  #分别将生成的umbrellaX_pullf.xvg （ls umbrella*_pullf.xvg 再Excel整理）


两个文件中，分别每行一个tpr/xvg，删除每个tpr/xvg后的多余空格。  #非常重要

生成的 histo.xvg和 profile.xvg即最终结果


