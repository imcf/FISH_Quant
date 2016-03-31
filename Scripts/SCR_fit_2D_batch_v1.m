%% Get all files that should be processed

[file_name, path_name] = uigetfile({'*.tif';'*.TIF';'*.stk';'*.STK';'*.*'},'Select images that should be processed','MultiSelect','on');

if ~iscell(file_name)
    dum = file_name;
    clear file_name
    file_name = {dum};
end

if file_name{1} == 0; return; end


%% Loop over all files
for i_file = 1:numel(file_name)
    
    %- Get file-name
    file_loop = file_name{i_file};
    
    %- Call fitting routine
    SCR_fit_2D_v1(fullfile(path_name,file_loop))
end
