function parameters_quant = FQ_TS_settings_modify_v5(parameters_quant,flag_simple)
% Function to modify the settings of TS quantification



if flag_simple
        %- User-dialog
    dlgTitle = 'Options for TxSite quantification';  
    prompt_avg(1)  = {'[CROP] in XY +/- nm'};
    prompt_avg(2) = {'[CROP] in Z +/- nm'};
    prompt_avg(3) = {'[CROP] 0-no, 1-yes (with region)'};
    prompt_avg(4) = {'Size of region to sum intensity [XY]: center +/- pix'};
    prompt_avg(5) = {'Size of region to sum intensity [Z]: center +/- pix'};

    
    defaultValue_avg{1} = num2str(parameters_quant.crop_image.xy_nm);
    defaultValue_avg{2} = num2str(parameters_quant.crop_image.z_nm);
    defaultValue_avg{3} = num2str(parameters_quant.flags.crop);
    defaultValue_avg{4} = num2str(parameters_quant.N_pix_sum.xy);
    defaultValue_avg{5} = num2str(parameters_quant.N_pix_sum.z);

    options.Resize='on';
    %options.WindowStyle='normal';
    userValue = inputdlg(prompt_avg,dlgTitle,1,defaultValue_avg,options);

    %- Return results if specified
    if( ~ isempty(userValue))

        parameters_quant.crop_image.xy_nm      = str2double(userValue{1});
        parameters_quant.crop_image.z_nm       = str2double(userValue{2});
        parameters_quant.flags.crop            = str2double(userValue{3});
        parameters_quant.N_pix_sum.xy          = str2double(userValue{4});
        parameters_quant.N_pix_sum.z           = str2double(userValue{5});
    end
    
else
    
    %- User-dialog
    dlgTitle = 'Options for TxSite quantification';
    prompt_avg(1) = {'[CROP] in XY +/- nm'};
    prompt_avg(2) = {'[CROP] in Z +/- nm'};
    prompt_avg(3) = {'[CROP] 0-no, 1-yes (with region)'};
    prompt_avg(4) = {'Size of region to sum intensity [XY]: center +/- pix'};
    prompt_avg(5) = {'Size of region to sum intensity [Z]: center +/- pix'};
    prompt_avg(6) = {'[Placement] 1-random; 2-max Int'};
    prompt_avg(7) = {'[Residuals] 1-ssr;    2-asr'};
    prompt_avg(8) = {'Number of runs'};
    prompt_avg(9) = {'Number of runs for preliminary analysis'};
    prompt_avg(10) = {'[BGD AUTO] Number of tested values'};
    prompt_avg(11) = {'[BGD AUTO] Factor for minimum intensity'};
    prompt_avg(12) = {'[BGD AUTO] Factor for maximum intensity'};
    
    defaultValue_avg{1} = num2str(parameters_quant.crop_image.xy_nm);
    defaultValue_avg{2} = num2str(parameters_quant.crop_image.z_nm);
    defaultValue_avg{3} = num2str(parameters_quant.flags.crop);
    defaultValue_avg{4} = num2str(parameters_quant.N_pix_sum.xy);
    defaultValue_avg{5} = num2str(parameters_quant.N_pix_sum.z);
    defaultValue_avg{6} = num2str(parameters_quant.flags.placement);
    defaultValue_avg{7} = num2str(parameters_quant.flags.quality);
    defaultValue_avg{8} = num2str(parameters_quant.N_reconstruct);
    defaultValue_avg{9} = num2str(parameters_quant.N_run_prelim);
    defaultValue_avg{10} = num2str(parameters_quant.bgd_N_bins);
    defaultValue_avg{11} = num2str(parameters_quant.bgd_fact_min);
    defaultValue_avg{12} = num2str(parameters_quant.bgd_fact_max);
    



    options.Resize='on';
    %options.WindowStyle='normal';
    userValue = inputdlg(prompt_avg,dlgTitle,1,defaultValue_avg,options);

    %- Return results if specified
    if( ~ isempty(userValue))
        parameters_quant.crop_image.xy_nm      = str2double(userValue{1});
        parameters_quant.crop_image.z_nm       = str2double(userValue{2});
        parameters_quant.flags.crop            = str2double(userValue{3});
        parameters_quant.N_pix_sum.xy          = str2double(userValue{4});
        parameters_quant.N_pix_sum.z           = str2double(userValue{5});
        parameters_quant.flags.placement       = str2double(userValue{6});
        parameters_quant.flags.quality         = str2double(userValue{7});
        parameters_quant.N_reconstruct         = str2double(userValue{8});
        parameters_quant.N_run_prelim          = str2double(userValue{9}); 
        parameters_quant.bgd_N_bins            = str2double(userValue{10});
        parameters_quant.bgd_fact_min          = str2double(userValue{11});
        parameters_quant.bgd_fact_max          = str2double(userValue{12});

    end
end
