# FISH-quant #

Matlab toolbox to analyze single molecule mRNA FISH data. Allows counting the number of mature and nascent transcripts in 3D images.

For more details see the publication: Mueller F, Senecal A, Tantale K, Marie-Nelly H, Ly N, Collin O, Basyuk E, Bertrand E, Darzacq X, Zimmer C. FISH-quant: automatic counting of transcripts in 3D FISH images. Nature Methods 2013; 10(4): 277–278.

You can also sign up to the FISH-quant email list to receive emails about updates and new developments (http://groups.google.com/group/fish-quant-discuss). 

### Requirements ###
Program was developed and tested in Matlab R2014a on Mac OS 10.9.5. Some functions might NOT work in earlier versions. Please contact us if you encounter any problems.

The following toolboxes are required

* Optimization toolbox
* Statistics toolbox
* Image processing toolbox
* (Optional) Parallel processing toolbox 

Program is provided as an ZIP archive. On rare occasions problems might occur when unzipping under Windows 7 with the built-in unzipper. Here the folders are encrypted and are shown in green. This can be avoided by using the free program 7-Zip (http://www.7-zip.org/). 

### Installation instructions ###


1. Download code from the Downloads section (Select Download repository) https://bitbucket.org/muellerflorian/fish_quant/overview
1. The code is provided in an zip archive with a name like muellerflorian-fish_quant-b4177b99dc53.zip. The last part of the name changes over time reflecting new versions.  To avoid updating the path-definition each time you download a new version of FISH-quant (see next), we recommend copying the content of this archive to a folder called FISH_quant in the user folder of Matlab. 
1. Under windows this folder is usually C:\Users\user_name\Documents\MATLAB, where user_name is the user name. This path can be found with the Matlab command userpath. 
1. Create a folder FISH_quant, and copy the content of the downloaded archive in this folder. In the example above, you will have a folder C:\Users\user_name\Documents\MATLAB\FISH_quant with all the source code.
1. Update Matlab path definition. This can be done with a few simple steps in Matlab.
    1. In the Matlab menu select File > Set Path
    1. This will open a dialog box. In this box select *Add with subfolders …*
    1. This will open another dialog. Here select the folder of FISH_quant from step 1, e.g. C:\Users\user_name\Documents\MATLAB\FISH_quant. Click OK.
    1. To save this settings press Save. Depending on the settings of the installation of Matlab this might results in a warning saying that the changes to path cannot be saved. Matlab proposes to save the path-definition file pathdef.m to another location. Click Yes. Select a directory of choice, e.g. the Matlab work directory of the user.

For more details, please consult to detailed FQ manual.

### Getting started ###
We provide several files to help new user getting used to FISH-quant. We recommend working with the example data and using either step-by-step tutorial or the video tutorials to familiarize yourself with the basic functionality. The more detailed user manual can then be used to adjust more advanced options.

* Example data. This zip archive contains already processed FISH data. For these data the entire analysis has been performed and the different results files are provided.
* Tutorial PDF. In this PDF we explain in detail the basic workflow for the analysis of FISH data. This is done based on the example data.
* User manual. A PDF containing with a detailed user manual describing the entire functionality of FISH-quant. 

### Development team ###
Florian MUELLER (Institut Pasteur,ENS Paris) and Aubin SAMACOITS (Institut Pasteur) based on work of Hervé Marie-Nelly (Institut Pasteur). 

### Depot at APP ###
A depot of the software was issued at APP (http://www.app.asso.fr/en/) under the reference number IDDN.FR.001.090009.000.S.A.2013.000.10000 

### Contact ###
Florian Mueller: muellerf.research@gmail.com

Institut Pasteur, Computational Imaging and Modeling Unit, 25-28 rue du Docteur Roux, 75015 Paris, France