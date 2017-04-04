# Welcome to the SciServer Ocean Modelling User Case

[SciServer](http://www.sciserver.org/) consists of integrated tools that work together to create a full-featured system.
SciServer is administrated by The Institute for Data Intensive Engineering and Science (IDIES) and The Johns Hopkins University, and is funded by National Science Fundation award ACI-1261715.

The Ocean Modeling User Case consists of a set of tools that provides access to numerical model output of high-resolution Ocean General Circulation Models (GCMs) set up and run by group of [Prof. Thomas W. N. Haine](http://sites.krieger.jhu.edu/haine/) (Johns Hopkins University - Department of Earth and Planetary Sciences).

## Getting started

### SciServer
1. [Register for a new SciServer account](http://portal.sciserver.org/login-portal/Account/Register) or [Log in to an existing SciServer account](http://portal.sciserver.org/login-portal/Account/Login?callbackUrl=http:%2f%2fcompute.sciserver.org%2fdashboard)
2. Create a new container and choose:
```markdown
- Image: MATLAB R2016a
- Public Volumes: Ocean Circulation
```
3. Click on the green play button.

The workspace contains:
```markdown
- OceanCirculation: Read only directory containing data.
- scratch: Personal directory for storing large temporary files and output.
- persistent: Personal directory for long-term storage of relatively small files.
```

### MITgcm tools
1. Open a new terminal (_New_ -> _Terminal_).
2. Clone the MITgcm tools (e.g. into the persistent directory):
```sh
$ cd /home/idies/workspace/persistent
$ git clone https://github.com/malmans2/JHU-MITgcm_Tools.git
```
3. Get the latest available version:
```sh
$ cd /path/of/JHU-MITgcm_Tools
$ git pull
```
[JHU-MITgcm_Tools](https://github.com/malmans2/JHU-MITgcm_Tools) contains:
```markdown
- code: Directory containing matlab scripts and functions. Type help function.m in matlab to get more details.
  - eulerian: Subdirectory containing eulerian tools.
  - lagrangian: Subdirectory containing lagrangian tools (particle tracking code - not available yet).
- info: Directory containing description and list of available variables for each experiment.
- notebooks: Directory containing notebooks templates that walk you through how to use our tools.
```


## Example
1. Log in to SciServer and open a container.
2. Open a terminal (_New_ -> _Terminal_), create a new directory and open it:
```sh
$ mkdir /home/idies/workspace/persistent/Test
$ cd /home/idies/workspace/persistent/Test
```
3. Copy a notebook template into the _Test_ directory:
```sh
$ cp  /path/of/MITgcm_Tools/notebooks/eulerian_template.ipynb mynotebook.ipynb
```
4. Open your notebook (click on _persistent_ -> _Test_ -> _mynotebook.ipynb_).
5. Now you can edit the notebook following its comments. The first cell sets the environment and can NOT be deleted or moved because it creates variables that will be used by the other cells. The first cell also point to the directory containing the tools: choose the right path by setting `toolspath=['path/of/JHU-MITgcm_Tools']` (e.g. /home/idies/workspace/persistent/JHU-MITgcm_Tools).
6. Check the [info](https://github.com/malmans2/JHU-MITgcm_Tools/tree/master/info) directory for information about the available fields.
7. You can run the notebook using the menu/toolbar, or you can run a single cell by selecting it and pressing Shift+Enter. Jupyter prints the outputs below every cell only when the cell's script is done. If you want to monitor the progress of your notebook, use the logfile option in the first cell; e.g. set `logname=['logfile']` and read it through the terminal:
```sh
$ tail -f logfile
```
Once you get familiar with our tools, you can easily build your own notebooks using the scripts/functions contained in [JHU-MITgcm_Tools/code](https://github.com/malmans2/JHU-MITgcm_Tools/tree/master/code).

### How to cite us:
#### To cite our dataset, please use this reference: 
- Almansi et al., "Variability in Circulation and Hydrography in the Denmark Strait", in preparation

#### To cite our Lagrangian Tracking Particle Code, please use these references: 
- R. Gelderloos, A. S. Szalay, T. W. N. Haine, and G. Lemson, "A fast algorithm for neutrally-buoyant Lagrangian particles in numerical ocean modeling," 2016 IEEE 12th International Conference on e-Science (e-Science), Baltimore, MD, 2016, pp. 381-388.
doi: 10.1109/eScience.2016.7870923
URL: [http://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=7870923&isnumber=7870873](http://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=7870923&isnumber=7870873)

- I. M. Koszalka, T. W. N. Haine, and M. G. Magaldi, 2013: Fates and Travel Times of Denmark Strait Overflow Water in the Irminger Basin. J. Phys. Oceanogr., 43, 2611–2628, doi: 10.1175/JPO-D-13-023.1. URL: [http://journals.ametsoc.org/doi/pdf/10.1175/JPO-D-13-023.1](http://journals.ametsoc.org/doi/pdf/10.1175/JPO-D-13-023.1)


### Support or Contact
- Mattia Almansi: mattia.almansi@jhu.edu
- Dr. Renske Gelderloos:  rgelder2@jhu.edu 

Having trouble with SciServer or JHU-MITgcm_Tools? Contact us and we’ll help you!
The [SciServer support page](http://www.sciserver.org/support/) may also be useful.

JHU-MITgcm_Tools is open source: let us know if you find any bugs or if you want to share any notebooks/functions.
