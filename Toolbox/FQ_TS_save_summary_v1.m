function FQ_TS_save_summary_v1(file_name_full,TS_summary,parameters)

current_dir = pwd;

%% Parameters
path_save          = parameters.path_save;
file_name_settings = parameters.file_name_settings;
version            = parameters.version;
mRNA_prop          = parameters.mRNA_prop;

%% Ask for file-name if it's not specified
if isempty(file_name_full)
    cd(path_save);

    %- Ask user for file-name for spot results
    if isempty(parameters.file_name_default)
        file_name_default = ['FQ__TS_quant_summary_', datestr(date,'yymmdd'), '.txt'];
    else
        file_name_default = parameters.file_name_default;
    end
    
    
    [file_save,path_save] = uiputfile(file_name_default,'Save results of batch processing');
    file_name_full = fullfile(path_save,file_save);
    
    if file_save ~= 0
        
        %- Ask user to specify comment
        prompt = {'Comment (cancel for no comment):'};
        dlg_title = 'User comment for file';
        num_lines = 1;
        def = {''};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
    end
else   

    file_save = 1;
    answer = 'Batch detection';
end


%% Only write if FileName specified
if sum(file_save ~= 0) && not(isempty(answer))
    
    fid = fopen(file_name_full,'w');
    
    %=== Header    
    fprintf(fid,'FISH-QUANT\t%s\n', version );
    fprintf(fid,'RESULTS TxSite quantification performed ON %s \n', date);
    fprintf(fid,'%s\t%s\n','COMMENT',char(answer)); 
    fprintf(fid,'ANALYSIS-SETTINGS \t%s\n', file_name_settings);  
    
    fprintf(fid,'PROPERTIES OF mRNA\n'); 
    
    %- Sigma-XY
    if isfield(mRNA_prop,'sigma_xy')
        fprintf(fid,'mRNA: sigma-XY: \t%g\n', mRNA_prop.sigma_xy );
    else
        fprintf(fid,'mRNA: sigma-XY: \t%g\n', 0 );
    end
    
    %- Sigma-Z
    if isfield(mRNA_prop,'sigma_z')
        fprintf(fid,'mRNA: sigma-Z: \t%g\n', mRNA_prop.sigma_z );
    else
        fprintf(fid,'mRNA: sigma-Z: \t%g\n', 0 );
    end   
    
    %- Brightest pixel
    if isfield(mRNA_prop,'pix_brightest')
        fprintf(fid,'mRNA: brightest pixel: \t%g\n', mRNA_prop.pix_brightest );
    else
        fprintf(fid,'mRNA: brightest pixel: \t%g\n', 0 );
    end

    %- Sum of all pixels (intensity)
    if isfield(mRNA_prop,'sum_pix')
        fprintf(fid,'mRNA: sum of all pixels (intensity): \t%g\n',round(mRNA_prop.sum_pix) ); 
    else
        fprintf(fid,'mRNA: sum of all pixels (intensity): \t%g\n',0 );
    end
    
    %- Sum all pixels (number)
    if isfield(mRNA_prop,'N_pix_sum')
        fprintf(fid,'mRNA: sum of all pixels (number): \t%g\n',round(mRNA_prop.N_pix_sum) ); 
    else
        fprintf(fid,'mRNA: sum of all pixels (number): \t%g\n',0 );
    end
    
    %- Background value
    if isfield(mRNA_prop,'bgd_value')
        fprintf(fid,'mRNA: background: \t%g\n',round(mRNA_prop.bgd_value) ); 
    else
        fprintf(fid,'mRNA: background: \t%g\n',0 );
    end
    
    
    %- Estimated amplitude
    if isfield(mRNA_prop,'amp_mean_fit_QUANT')
        fprintf(fid,'mRNA: estimated amplitude: \t%g\n',round(mRNA_prop.amp_mean_fit_QUANT) ); 
    else
        fprintf(fid,'mRNA: estimated amplitude: \t%g\n',round(mRNA_prop.amp_mean) );
    end
    
    fprintf(fid,'FILE\tCELL\tTS\tN_IntInt\tN_PSFsup\tN_PSFsup_std\tN_SumPix\tN_Amp\tN_MaxInt\tsigma_xy\tsigma_z\tAMP\tBGD\tSize_mean[nm]\tSize_std[nm]\tBGD_cell\tTS_PixSum\tPSF_BgdSum\tTS_MaxInt\n');    

    %- Summary for each cell
    for i_TS = 1:length(TS_summary)  
        
              if isfield(TS_summary(i_TS).TxSite_quant,'TS_max_int')
                  MAX_int    = TS_summary(i_TS).TxSite_quant.TS_max_int;
                  TS_BGD     = TS_summary(i_TS).TxSite_quant.TS_max_bgd;
                  TS_sum     = TS_summary(i_TS).TxSite_quant.TS_sum;
                  TS_bgd_sum = TS_summary(i_TS).TxSite_quant.TS_bgd;  
                  
              else
                  MAX_int    = 0;
                  TS_BGD     = 0;
                  TS_sum     = 0;
                  TS_bgd_sum = [];
              end
  
              res_quant = [ TS_summary(i_TS).TxSite_quant.N_mRNA_integrated_int, ...
              TS_summary(i_TS).TxSite_quant.N_mRNA_TS_mean_all, ...
              TS_summary(i_TS).TxSite_quant.N_mRNA_TS_std_all, ...
              TS_summary(i_TS).TxSite_quant.N_mRNA_sum_pix, ...
              TS_summary(i_TS).TxSite_quant.N_mRNA_fitted_amp, ...
              TS_summary(i_TS).TxSite_quant.N_mRNA_trad, ...
              TS_summary(i_TS).TS_analysis_results.TS_Fit_Result.sigma_xy, ...
              TS_summary(i_TS).TS_analysis_results.TS_Fit_Result.sigma_z, ...
              TS_summary(i_TS).TS_analysis_results.TS_Fit_Result.amp, ...
              TS_summary(i_TS).TS_analysis_results.TS_Fit_Result.bgd, ...
              TS_summary(i_TS).REC_prop.TS_dist_all_IN_mean, ...
              TS_summary(i_TS).REC_prop.TS_dist_all_IN_std, ...
              TS_BGD, ...
              TS_sum,TS_bgd_sum,MAX_int];
        
         N_col = length(res_quant); 
         string_write = ['%s\t%s\t%s',repmat('\t%g',1,N_col),'\n'];        
         fprintf(fid,string_write,TS_summary(i_TS).file_name_list, TS_summary(i_TS).cell_label, TS_summary(i_TS).TS_label, res_quant);        
    end
    
    fclose(fid);
end

cd(current_dir)

       
        
       