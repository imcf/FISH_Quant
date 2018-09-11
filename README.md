Matlab toolbox to analyze single molecule mRNA FISH data. 

1. Counting the number of mature and nascent transcripts in 3D images.
2. (locFISH) Simulating realistic smFISH images with different RNA localization patterns.
3. (locFISH) Analyzing RNA localization in simulated and experimental data. 

For more details see **publications**: 

* Mueller F, Senecal A, Tantale K, Marie-Nelly H, Ly N, Collin O, Basyuk E, Bertrand E, Darzacq X, Zimmer C. FISH-quant: automatic counting of transcripts in 3D FISH images. Nature Methods 2013; 10(4): 277–278.
* Samacoits A, Chouaib R,  Safieddine A, Traboulsi AM, Ouyang W, Zimmer C, Peter M, Bertrand E, Walter T, Mueller F. A computational framework to study sub-cellular RNA localization. In preparation.

You can also sign up to the FISH-quant email list to receive emails about updates and new developments (http://groups.google.com/group/fish-quant-discuss).

## Installation information ##

Program was developed and tested in Matlab R2017b on Mac OS 10.13.4. Some functions might NOT work in earlier versions. Please contact us if you encounter any problems.

The following **toolboxes** are required

* Optimization toolbox
* Statistics toolbox
* Image processing toolbox
* (Optional) Parallel processing toolbox 

Program is provided as an **ZIP archive**. On rare occasions problems might occur when unzipping under Windows 7 with the built-in unzipper. Here the folders are encrypted and are shown in green. This can be avoided by using the free program 7-Zip (http://www.7-zip.org/).


## Getting started ##

We provide several help files in the Documents folder for new users to getting used to FISH-quant. We recommend working with the example data and using either step-by-step tutorial to familiarize yourself with the basic functionality. The more detailed user manual can then be used to adjust more advanced options.


**FISH_QUANT__Tutorials.pdf**: In this PDF we explain in detail the basic workflow for the analysis of FISH data. This is done based on the example data.

**Example data**. This zip archive can be downloaded from the "Download" section and contains already processed FISH data. For these data the entire analysis has been performed and the different results files are provided.

**FISH_QUANT_v3.pdf**. An PDF containing with a detailed user manual describing the entire functionality of FISH-quant. 

**locFISH_manual.pdf** Describes the entire functionality to analyze RNA localization (simulating images, calculation of localization features, and cell classification based on RNA localization).


## Bugs, other issues and suggestions for improvements ##
Please report bugs via the Issues menu item or email Florian Mueller (Contact see below). If you have problems with some of the processing steps or you have suggestions for improvements please also email Florian Mueller.
Development team

## Development team ##
* FISH-quant v1 and v2 developed by Florian Mueller (ENS Paris, Institut Pasteur) based on work of Hervé Marie-Nelly (Institut Pasteur). 
* FISH-quant v3  and locFISH developed by Florian Mueller, Aubin Samacoits (Institut Pasteur), and Thomas Walter (Institut Curie)

Research was conducted in the group of Christophe Zimmer (Institut Pasteur), Xavier Darzacq (ENS Paris; Adrien Senecal and Nathalie Lao), and Edouard Bertrand (IGMM Montpellier; Eugenia Basyuk and Katjana Tantale).
Depot at APP

A depot of the software was issued at APP (http://www.app.asso.fr/en/) under the reference number IDDN.FR.001.090009.000.S.A.2013.000.10000


## Contact ##
Florian Mueller: muellerf.research@gmail.com
Institut Pasteur, Computational Imaging and Modeling Unit, 25-28 rue du Docteur Roux, 75015 Paris, France