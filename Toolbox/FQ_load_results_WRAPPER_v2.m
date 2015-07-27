function [cell_prop, par_microscope, file_names, flag_file, version,size_img,comment] = FQ_load_results_WRAPPER_v2(file_name,parameters)


comment = [];
% ==== Get parameters to read data



% =  flag_identifier  ... does first column contain an identifier for each spot
if isfield(parameters,'flag_identifier')
    flag_identifier = parameters.flag_identifier;
else
    flag_identifier = 0;
end

% =  col_par  ... tells FQ where to find the different estimates
if isfield(parameters,'col_par')
    col_par = parameters.col_par;
else
    col_par = [];
end

%- Decide which file to load
filetext = fileread(file_name);

if ~isempty(strfind(filetext,'CELL_START'))
	[cell_prop, par_microscope, file_names, flag_file, version,size_img,comment] = FQ_load_results_v1(file_name,flag_identifier);
else
	[cell_prop, par_microscope, file_names, flag_file, version]                  = FQ2_load_results_v1(file_name,flag_identifier);
    size_img = [];
end
   

%- Set-up structure for thresholding

% Continue only if col_par is defined
if isempty(col_par)
    return
end

for ind_cell=1:length(cell_prop)

    %- Check if values are present
    if isempty(cell_prop(ind_cell).spots_fit)
        continue
    end
    
    %- Get all necessary structures
    thresh          = cell_prop(ind_cell).thresh ;
    spots_fit       = cell_prop(ind_cell).spots_fit;
    spots_detected  = cell_prop(ind_cell).spots_detected;

    thresh.sigmaxy.min   = min(spots_fit(:,col_par.sigmax));
    thresh.sigmaxy.max   = max(spots_fit(:,col_par.sigmax));
    thresh.sigmaxy.diff  = max(spots_fit(:,col_par.sigmax)) - min(spots_fit(:,col_par.sigmax));             

    thresh.sigmaz.min    = min(spots_fit(:,col_par.sigmaz));
    thresh.sigmaz.max    = max(spots_fit(:,col_par.sigmaz));
    thresh.sigmaz.diff   = max(spots_fit(:,col_par.sigmaz)) - min(spots_fit(:,col_par.sigmaz));             

    thresh.amp.min      = min(spots_fit(:,col_par.amp));
    thresh.amp.max      = max(spots_fit(:,col_par.amp));
    thresh.amp.diff     = max(spots_fit(:,col_par.amp)) - min(spots_fit(:,col_par.amp));             

    thresh.bgd.min      = min(spots_fit(:,col_par.bgd));
    thresh.bgd.max      = max(spots_fit(:,col_par.bgd));
    thresh.bgd.diff     = max(spots_fit(:,col_par.bgd)) - min(spots_fit(:,col_par.bgd));             

    thresh.int_raw.min      = min(spots_detected(:,col_par.int_raw));
    thresh.int_raw.max      = max(spots_detected(:,col_par.int_raw));
    thresh.int_raw.diff     = max(spots_detected(:,col_par.int_raw)) - min(spots_detected(:,col_par.int_raw));             

    thresh.int_filt.min      = min(spots_detected(:,col_par.int_filt));
    thresh.int_filt.max      = max(spots_detected(:,col_par.int_filt));
    thresh.int_filt.diff     = max(spots_detected(:,col_par.int_filt)) - min(spots_detected(:,col_par.int_filt));             

    thresh.pos_z.min      = min(spots_fit(:,col_par.pos_z));
    thresh.pos_z.max      = max(spots_fit(:,col_par.pos_z));
    thresh.pos_z.diff     = max(spots_fit(:,col_par.pos_z)) - min(spots_fit(:,col_par.pos_z));      
    
    %- Assign back
    cell_prop(ind_cell).thresh = thresh ;
    
end