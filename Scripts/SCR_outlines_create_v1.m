%% FQ script that creates outlines for different colors
% First, you have to define all the outline that should be used to create 
% outlines in a different color. IMPORTANT: these outlines have to be in
% the same folder
%
% Second, you have to specify a textfile, that defined the different
% colors. This file has the following properties 
%  + It is a TAB delimited text file. This can for instance be generated 
%    with Excel
%  + First row contains the unique string of the first color, e.g. CY3
%  + Following rows define one color. First element is the unique string,
%    e.g. CY5, 2nd element is the the excitation wavelength in nm, 3rd
%    element the emission wavelength
%
% Script will then go over all outline files. It will create one folder for
% each color, in which the new outlines will be saved. 

%% Define outline files that should be converted
[outlines_list,folder_outlines] = uigetfile({'*.txt'},'Select outline files','MultiSelect', 'on');

if ~iscell(outlines_list)
    dum =outlines_list; 
    outlines_list = {dum};
end

if outlines_list{1} ~= 0
    return
end

    
%% Get color processing list
[file_proc, path_proc] = uigetfile('*.txt','Get color processing list.');

%==== Make sure file exists
if file_proc == 0; return; end
    
file_load =fullfile(path_proc,file_proc);
if not(exist(file_load))
    warndlg('Processing file does not exist',mfilename)
    disp(file_load)
end
    
%===== Analyze file with files to be processed
disp(' ===== FISH-quant: create outline files in different colors')
disp(' Analysing list with files to be processed')

fid = fopen(file_load);
tline = fgetl(fid);
i_file    = 1;
list_colors = {};

isFirst  = 1;

while ischar(tline)
    
    disp(tline)
    
    % - Find tabulators in current line, add index of last element
    k = strfind(tline, sprintf('\t') );
    k(end+1) = length(tline)+1;
    
    %- Check if there is the correct number of tabs
    if length(k) ~= 3
        disp('Incorrect number of elements')
        disp(tline)
        continue
    end
    
    str_color = tline(1 : k(1)-1);
    
    %- If first line, only get first field
    if isFirst
        str_first  = str_color;
        isFirst  = 0;
    else
       list_colors(i_file-1).str_replace = str_color;
       list_colors(i_file-1).Ex          = str2double(tline(k(1)+1 : k(2)-1));
       list_colors(i_file-1).Em          = str2double(tline(k(2)+1 : k(3)-1)); 
    end
       
    %- Get next line and increase index of file counter
    tline = fgetl(fid);
    i_file = i_file +1;
    
end
fclose(fid);

N_colors  = length(list_colors);
fprintf(' Found %d files\n',N_colors)


%% Go over list and process

parameters.name_str.old = str_first;

for i_colors=1:N_colors

    %- Show update
    fprintf('\n = Processing color %d of %d\n',i_colors,N_colors)
    
    %- Wavelength
    parameters.Em = list_colors(i_colors).Em;
    parameters.Ex = list_colors(i_colors).Ex;
    
    %- Replacement string
    parameters.name_str.new = list_colors(i_colors).str_replace;

    %- Assign file-names
    parameters.outlines_list   = outlines_list;
    parameters.folder_outlines = folder_outlines;  
    
    %- Replace the colors
    FQ3_outline_replace_color_v2(parameters)
end