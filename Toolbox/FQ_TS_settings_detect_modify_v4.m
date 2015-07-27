function parameters_quant = FQ_TS_settings_detect_modify_v4(parameters_quant)
% Function to modify the settings of TS quantification

%- User-dialog
dlgTitle = 'Options for TxSite quantification';
prompt_avg(1) = {'Size-XY +/- nm'};
prompt_avg(2) = {'Size-Z +/- nm'};
prompt_avg(3) = {'Number of connected comp in 3D (6,18,26)'};
prompt_avg(4) = {'Minimum distance between detected sites [pix]'};
prompt_avg(5) = {'Max # of TS per cell'};
prompt_avg(6) = {'Max # of TS per image'};
prompt_avg(7) = {'[TS label] Max distance detected location and brightest FISH signal [nm]'};
prompt_avg(8) = {'[TS label] Minimum intensity of FISH signal to be considered'};




defaultValue_avg{1} = num2str(parameters_quant.size_detect.xy_nm);
defaultValue_avg{2} = num2str(parameters_quant.size_detect.z_nm);
defaultValue_avg{3} = num2str(parameters_quant.conn);
defaultValue_avg{4} = num2str(parameters_quant.min_dist);
defaultValue_avg{5} = num2str(parameters_quant.N_max_TS_cell);
defaultValue_avg{6} = num2str(parameters_quant.N_max_TS_total);
defaultValue_avg{7} = num2str(parameters_quant.dist_max_offset);
defaultValue_avg{8} = num2str(parameters_quant.dist_max_offset_FISH_min_int);

options.Resize='on';
%options.WindowStyle='normal';
userValue = inputdlg(prompt_avg,dlgTitle,1,defaultValue_avg,options);

%- Return results if specified
if( ~ isempty(userValue))
    parameters_quant.size_detect.xy_nm    = str2double(userValue{1});
    parameters_quant.size_detect.z_nm     = str2double(userValue{2});
    parameters_quant.conn                 = str2double(userValue{3});
    parameters_quant.min_dist             = str2double(userValue{4});
    parameters_quant.N_max_TS_cell        = str2double(userValue{5});
    parameters_quant.N_max_TS_total       = str2double(userValue{6});
    parameters_quant.dist_max_offset      = str2double(userValue{7});
    parameters_quant.dist_max_offset_FISH_min_int      = str2double(userValue{8});
end

