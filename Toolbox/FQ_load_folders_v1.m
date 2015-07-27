function [handles_loaded,flag_file] = FQ_load_folders_v1(file_name)

handles_loaded.path_name_root    = [];
handles_loaded.path_name_results = [];
handles_loaded.path_name_image   = [];
handles_loaded.path_name_outline = [];


%- Open file
fid  = fopen(file_name,'r');

if fid == -1
    warndlg('File cannot be opened','FQ_load_folders_v1'); 
    disp(['File cannot be opened: ' , file_name])
    flag_file = 0;
else
    
    tline = fgetl(fid);
    
    while ischar(tline)
        
        %- Path: root
        if ~(isempty(strfind(tline, 'path_name_root'))) 
            k = strfind(tline, sprintf('\t') );
            handles_loaded.path_name_root = tline(k+1:end);
        end
    
         %- Path: results
        if ~(isempty(strfind(tline, 'path_name_results'))) 
            k = strfind(tline, sprintf('\t') );
            handles_loaded.path_name_results = tline(k+1:end);
        end   
    
    
         %- Path: image
        if ~(isempty(strfind(tline, 'path_name_image'))) 
            k = strfind(tline, sprintf('\t') );
            handles_loaded.path_name_image = tline(k+1:end);
        end   
    
        %- Path: outline
        if ~(isempty(strfind(tline, 'path_name_outline'))) 
            k = strfind(tline, sprintf('\t') );
            handles_loaded.path_name_outline = tline(k+1:end);
        end
        
        
        tline = fgetl(fid);
        
    end
    
    flag_file = 1;
end