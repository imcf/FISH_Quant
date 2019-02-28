%% Matlab script to quantify co-localization between smFISH and IF data.
% 
%  To measure the degree of spatial overlap of smiFISH (mRNA) and IF 
%  (protein) signal, this script calculates an enrichment ratio.
%  RNA detection is performed with FISH-quant. 
%  
%  == WORKFLOW
%    This script then processes all FQ results files in a folder. It loops 
%    over each file and processed each cell separately: 
%     1. the median pixel intensity in the IF image at the identified 
%        RNA positions is calculated. 
%     2. Second, a normalization factor as the median IF intensity of the 
%        outlined cytoplasm within the z-range of the detected mRNAs is 
%        estimated. 
%     3. The enrichment ratio of the cell is calculated as the ratio of 
%        the median IF intensity at the RNA positions divided by the mean 
%        cytoplasmic intensity. 
%
%  === INPUT
%    Images are 3D stacks stored separately for each channel. FISH and IF
%    images have to be named such that they can be identified with a
%     
%    smFISH images have to be analyzed with FISH-quant. We refer to the
%    dedicated user manuals for more details
%
%  ==== OUTPUT
%    Actual analysis is performed by the script "FISH_IF_enrich_v1". It
%    returns a matrix, where each cell is in one row
%
%     column 1:  Total RNA level in cells;
%     column 1:  RNA level in cytoplasm;
%     column 3:  IF intensity under RNA positions;
%     column 4:  Median GFP intensity in cytoplasm
%     column 5: enrichment ratio%
%
%  ==== More information
%
%    See the publication:
%       Kamenova et al., Nature Communications, 2019
%       Co-translational assembly of mammalian nuclear multisubunit complexes
%
%    Contact:
%       Florian Mueller, Institute Pasteur
%       muellerf.research@gmail.com


%% Specify name of folder containg the FQ results 
file_info.folder_results = 'PathToFQreults';

%% Specify folder containing the IF images
file_info.folder_images = 'PathToIFimages';             
             

%% Set general analysis parameters

%- Unique identifier for FISH and IF
file_info.txt_smFISH  = 'C3-';
file_info.txt_protein = 'C1-';     
   
%- Size of cropping region around detected RNA position to quantify IF signal
param.size_crop.xy = 0;
param.size_crop.z  = 0;

%- How IF signal should be quantified: 'median' or 'max'
param.flag_quant   = 'median';   

%- Min & max intensity values to be considered
param.nRNA_min = 0;
param.nRNA_max = 500;

%% Search results folder for results files (containing "spot" in the name)
file_list              = dir(file_info.folder_results) ;
file_list_name         = {file_list.name};
ind_results_file       =  cellfun(@(x) strfind(x, 'spots'), file_list_name, 'UniformOutput',false);
ind_results_file       = cellfun(@(x) isempty(x), ind_results_file);
file_info.name_results = {file_list_name{~ind_results_file}};

%% Perform analysis
%  The first analysis quantifies the IF signal at the exact location of the
%  localized RNAs. The second analysis performs an internal control, here 
%  the IF images are quantified with an offset of 5 pixels.

%- Co-localization analysis
param.pix_offset = 0;
enrich_coLoc = FISH_IF_enrich_v1(file_info,param);

%- Co-localization offset control
param.pix_offset = 5;
enrich_Offset = FISH_IF_enrich_v1(file_info,param);


%% Compare co-localization analysis with offset control

%- Assemble data for boxplot
clear data_plot data_coloc data_ctrl
data_coloc(:,1) = enrich_coLoc(:,5);
data_coloc(:,2) = 1;
data_ctrl(:,1)  = enrich_Offset(:,5);
data_ctrl(:,2)  = 2;
data_plot = [data_coloc;data_ctrl];

%- Boxplot
figure, set(gcf,'color','w')
notBoxPlot(data_plot(:,1),data_plot(:,2))
set(gca,'XTickLabel',{'CoLoc','Offset'})
box on
set(gcf,'position',[ 1517 957  300 400])
ylabel('Enrichment ratio')

%- KS test
x1 = data_plot((data_plot(:,2) == 1),1); x2 = data_plot((data_plot(:,2) == 2),1);
[h,p] =  kstest2(x1,x2);
disp('=== KS test: ')
disp('  - null hypothesis that the data are from the same continuous distribution')
disp('  - h is 1 if the test rejects the null hypothesis at the 5% significance level, and 0 otherwise.')
fprintf('\n\KS-test : h = %d, p = %f\n',h,p);

