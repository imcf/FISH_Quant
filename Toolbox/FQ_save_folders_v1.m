function [file_save, path_save] = FQ_save_folders_v1(handles)


if isempty(handles.img.path_names.root)
    file_name_default = '_FQ_folders.txt';
else
    file_name_default = fullfile(handles.img.path_names.root,'_FQ_folders.txt');
end

 
[file_save,path_save] = uiputfile(file_name_default);
file_name_full = fullfile(path_save,file_save);

if file_save ~= 0

    fid = fopen(file_name_full,'w');

    %- Save folders
    fprintf(fid,'%s\t%s\n','path_name_root',handles.img.path_names.root);    
    fprintf(fid,'%s\t%s\n','path_name_results',handles.img.path_names.results); 
    fprintf(fid,'%s\t%s\n','path_name_image',handles.img.path_names.img); 
    fprintf(fid,'%s\t%s\n','path_name_outline',handles.img.path_names.outlines); 

    fclose(fid);
end

