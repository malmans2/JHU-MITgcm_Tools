# Welcome to the SciServer Ocean Modelling User Case

[SciServer](http://www.sciserver.org/) consists of integrated tools that work together to create a full-featured system.
SciServer is administrated by The Institute for Data Intensive Engineering and Science (idies) and The Johns Hopkins University, and is funded by National Science Fundation award ACI-1261715.

The Ocean Modelling User Case consists of a set of tools that provide access to numerical models outputs resulting from high resolution Ocean General Circulation Models (GCMs) set up and run by [Prof. Thomas W. N. Haine](http://sites.krieger.jhu.edu/haine/) group (Johns Hopkins University - Department of Earth and Planetary Sciences).

## Getting started

### SciServer
1. [Register for a new SciServer account](http://portal.sciserver.org/login-portal/Account/Register) or [Log in to an existing SciServer account](http://portal.sciserver.org/login-portal/Account/Login?callbackUrl=http:%2f%2fcompute.sciserver.org%2fdashboard)
2. Create a new container and choose:
```markdown
- _Image_: MATLAB R2016a 
- _Public Volumes_: Ocean Circulation
```
3. Click on the green play button
The workspace contains:
```markdown
- OceanCirculation: Read only directory containing data
- scratch: Personal directory for storing large temporary files and output
- persistent: Personal directory for long-term storage of relatively small files
```

### MITgcm tools
1. Open a new terminal (_New_ -> _Terminal_)
2. Clone the MITgcm tools (e.g. into the persistent directory)
```sh
$ cd /home/idies/workspace`
$ git clone https://github.com/malmans2/JHU-MITgcm_Tools.git
```



## Example
You can use the [editor on GitHub](https://github.com/malmans2/JHU-MITgcm_Tools/edit/master/README.md) to maintain and preview the content for your website in Markdown files.

Whenever you commit to this repository, GitHub Pages will run [Jekyll](https://jekyllrb.com/) to rebuild the pages in your site, from the content in your Markdown files.

### Markdown

Markdown is a lightweight and easy-to-use syntax for styling your writing. It includes conventions for

```markdown
Syntax highlighted code block

# Header 1
## Header 2
### Header 3

- Bulleted
- List

1. Numbered
2. List

**Bold** and _Italic_ and `Code` text

[Link](url) and ![Image](src)
```

For more details see [GitHub Flavored Markdown](https://guides.github.com/features/mastering-markdown/).

### Jekyll Themes

Your Pages site will use the layout and styles from the Jekyll theme you have selected in your [repository settings](https://github.com/malmans2/JHU-MITgcm_Tools/settings). The name of this theme is saved in the Jekyll `_config.yml` configuration file.

### Support or Contact

Having trouble with Pages? Check out our [documentation](https://help.github.com/categories/github-pages-basics/) or [contact support](https://github.com/contact) and we’ll help you sort it out.
