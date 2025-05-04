# MD_Umbrella-Sampling

gmx pdb2gmx -f protein_prepared.pdb -o protein.gro -p topol.top -ignh

  选择amber14力场
  
输入2
  
  选择tip3的水模型
输入1
  
  第二步是生成限制文件posre_lig.itp，用来限制蛋白质在整个体系中的运动

gmx genrestr -f molecule.gro -o posre_lig.itp
  
  选择对整个体系进行限制，默认是xyz方向各1000k的力

选0

  将配体itp文件引入限制文件的参数中，针对配体也进行限制

修改ligand的itp文件，在最末尾添加以下命令  

#ifdef POSRES
#include "posre_lig.itp"
#endif

  将配体的top文件与蛋白质top文件进行合并 合并到蛋白质文件

在topol.top文件的include "amber14sb_parmbsc1.ff/forcefield.itp"后面空行添加以下命令

; Include ligand topologies

include "lig1.itp"

把ligand的名字添加到末尾

  将配体的gro文件与蛋白质gro文件进行合并

将ligand的gro文件中MOL行复制到protein.gro文件倒数第二行，并将protein.gro的原子数相加

#VMD计算蛋白长宽高：
>set sel [atomselect top "protein"]

>set minmax [measure minmax $sel]

#计算结果为 {x_min y_min z_min}，{x_max y_max z_max} 单位为Å，要换算成Gromacs的nm（/10）

gmx editconf -f complex.gro -o newbox.gro -box 6.560 4.362 12  #可以用pymol或者VMD计算蛋白距离，要注意，拉动的距离一定要小于盒子的一半（主要为了区别于PBC周期边界条件）

```
关于质心
gmx editconf -f complex.gro -o newbox.gro -center 0 0 0 -box 6.560 4.362 12
- center 0 0 0 是规定将蛋白放在盒子中心位置，这种为一般情况设置，前期设置了质心，就不用在npt_umbrella.mdp和md_umbrella.mdp中再添加pull-group1-pbcatom     = -1 了
质心的计算会有新一个专栏研究
```

> pbc box #VMD命令，对盒子进行观察
#不合适的选择平移

gmx editconf -f newbox.gro -o newbox.gro  -translate 0 0 3 #向z轴正方向平移3nm

gmx solvate -cp newbox.gro -cs spc216.gro -o solv.gro -p topol.top

gmx grompp -f ions.mdp -c solv.gro -p topol.top -o ions.tpr

gmx genion -s ions.tpr -o solv_ions.gro -p topol.top -pname NA -nname CL -neutral -conc 0.1

gmx grompp -f minim.mdp -c solv_ions.gro -p topol.top -o em.tpr

gmx mdrun -v -deffnm em

gmx grompp -f npt.mdp -c em.gro -p topol.top -r em.gro -o npt.tpr

gmx mdrun -v -deffnm npt

gmx make_ndx -f npt.gro #recognize the corresponding names of protein and ligand

######################## 如果是纯蛋白模拟
 
gmx make_ndx -f npt.gro    
...
 > r 1-27
 > name 19 Chain_A
 > r 28-54
 > name 20 Chain_B
 > q

#######################
                     
rename 13 MOL1    #记得把重复的MOL分开，if 两个MOL，一个就命名为MOL1，另一个保持不变MOL，很重要


gmx grompp -f md_pull.mdp -c npt.gro -p topol.top -r npt.gro -n index.ndx -t npt.cpt -o pull.tpr

gmx mdrun -deffnm pull -pf pullf.xvg -px pullx.xvg -v 
##注意在增加了盒子尺寸后仍有报错Fatal error:
```
Distance between pull groups 1 and 2 (7.300399 nm) is larger than 0.49 times
the box size (7.300317 nm).
```
#可能原因是拉伸的速度太快，导致中途超过了pbc box，就要用md_umbrella_2.mdp进行低速率拉动。

gmx trjconv -s pull.tpr -f pull.xtc -o conf.gro -sep

python2 ./setupUmbrella.py summary_distances.dat 0.2 run-umbrella.sh &> caught-output.txt   

#如果output.txt没有文本输出，直接 
```
yes | python2 ./setupUmbrella.py summary_distances.dat 0.2 run-umbrella.sh
```
chmod +x frame-*.sh  #将生成的 .sh 文件给予权限

touch  squence.sh  # 将 .sh 文件一个个进行批次运行

```
for script in frame-*.sh; do
    ./$script
done
```
nohup bash ./squence.sh &



touch tpr-files.dat    #分别将生成的umbrellaX.tpr （ls umbrella*.tpr 再Excel整理）

touch pullf-files.dat  #分别将生成的umbrellaX_pullf.xvg （ls umbrella*_pullf.xvg 再Excel整理）


两个文件中，分别每行一个tpr/xvg，删除每个tpr/xvg后的多余空格。  #非常重要

gmx wham -it tpr-files.dat -if pullf-files.dat -o -hist -unit kCal

生成的 histo.xvg和 profile.xvg即最终结果


