function [TxSite_quant, REC_prop, TS_analysis_results, TS_rec, Q_all] = TS_quant_v17(image_struct,pos_TS,PSF_shift,parameters_quant)
% Function to quantify the number of nascent transcripts at the transcription site


%== Open file to save status of analysis
file_name_save_STATUS = parameters_quant.file_name_save_STATUS;
if not(isempty(file_name_save_STATUS));
   parameters_quant.fid = fopen(file_name_save_STATUS,'w'); 
   
   if parameters_quant.fid == -1
      warndlg(['Status of TxSite quantifcation cannot be saved. Invalid file: ', file_name_save_STATUS],mfilename);
   else  
       fprintf(parameters_quant.fid, '== FISH-QUANT: TxSITE quantification performed on %s \n\n', datestr(date,'dd-mm-yyyy'));
       fprintf(parameters_quant.fid, 'File  : %s \n',   parameters_quant.name_file);
       fprintf(parameters_quant.fid, 'Cell  : %s \n',   parameters_quant.name_cell);
       fprintf(parameters_quant.fid, 'TxSite: %s \n\n', parameters_quant.name_TS);
   end
else
   parameters_quant.fid = -1;     
end

        
%=== Analysis of the transcription site
[TS_analysis_results, PSF_shift]                = TxSite_reconstruct_ANALYSIS_v12(image_struct,pos_TS,PSF_shift,parameters_quant);


%=== Optional: quantification with PSF superposition approach
if not(parameters_quant.flags.quant_simple_only)
    [TS_rec, Q_all, TS_analysis_results.img_bgd] = TxSite_reconstruct_w_image_v9(TS_analysis_results,PSF_shift,parameters_quant);    
else
    Q_all  = [];
    TS_rec = [];
end

%== Analyse quantification & perform quantification based on fit
[TxSite_quant, REC_prop, TS_rec]                  = FQ_TS_analyze_results_v8(TS_rec,Q_all, TS_analysis_results, parameters_quant);


%== Convert FILE to PDF
if not(isempty(parameters_quant.file_name_save_PLOTS_PS))
   try 
        ps2pdf('psfile', parameters_quant.file_name_save_PLOTS_PS, ...
            'pdffile', parameters_quant.file_name_save_PLOTS_PDF, ...
            'gspapersize', 'a4', 'deletepsfile', 1);
   catch err
       disp(' ')
       disp('=============================================================')
       disp('Output file for TS quantification could not be generated')
       disp('Caused by function ps2pdf. This function needs Ghostscript to be installed.')
       disp('Ghostscript can be installed from: http://www.ghostscript.com/')
       disp('Original error displayed below')
       disp('=============================================================')
       disp(err)
   end
end
 
%== Close file
if  parameters_quant.fid ~= -1;
    fclose(parameters_quant.fid);
end

