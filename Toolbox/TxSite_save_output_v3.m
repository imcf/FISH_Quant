function  TxSite_save_output_v3(TxSite_quant, REC_prop, parameters)


if parameters.fid ~= -1

    fprintf(parameters.fid, '\n== SUMMARY OF TxSITE QUANTIFICATION ==== \n\n'); 
    fprintf(parameters.fid,'mRNA only consider within maximum distance %g\n',parameters.dist_max );   
    fprintf(parameters.fid, 'Number of NASCENT mRNA \n');
    fprintf(parameters.fid, 'All REC: mean +/- stdev                     : %g +/- %g\n', TxSite_quant.N_mRNA_TS_mean_all,TxSite_quant.N_mRNA_TS_std_all);
    fprintf(parameters.fid, 'Best 10 percent of REC: mean +/- stdev      : %g +/- %g\n\n', TxSite_quant.N_mRNA_TS_mean_10per,TxSite_quant.N_mRNA_TS_std_10per);
    fprintf(parameters.fid, 'Number of mRNA at TS (trad. method)         : %g\n', TxSite_quant.N_mRNA_trad);
    fprintf(parameters.fid, 'Number of mRNA at TS (ratio fitted AMP)     : %g\n', TxSite_quant.N_mRNA_fitted_amp);
    fprintf(parameters.fid, 'Number of mRNA at TS (ratio integrated INT) : %g\n\n', TxSite_quant.N_mRNA_integrated_int);
    fprintf(parameters.fid, 'Number of mRNA at TS (sum of pixel)         : %g\n\n', TxSite_quant.N_mRNA_sum_pix);

    fprintf(parameters.fid,'AVERAGED SIZE OF TRANSCRITPION SITE \n');
    fprintf(parameters.fid,'All mRNA: mean +/- stdev [nm]                  : %g +/- %g\n',round(REC_prop.TS_size_all_mean),round(REC_prop.TS_size_all_std));
    fprintf(parameters.fid,'mRNA within max distance : mean +/- stdev [nm] : %g +/- %g\n',round(REC_prop.TS_dist_all_IN_mean),round(REC_prop.TS_dist_all_IN_std));
    
end




