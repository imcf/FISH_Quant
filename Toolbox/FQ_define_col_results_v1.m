function col_par = FQ_define_col_results_v1()
% FUNCTION defines in which columns of the results files for the spot
% detection the different estimates can be found.


%- For results of fitting
col_par.pos_y = 1;
col_par.pos_x = 2;
col_par.pos_z = 3;

col_par.amp = 4;
col_par.bgd = 5;

col_par.sigmax = 7;
col_par.sigmay = 8;
col_par.sigmaz = 9;

col_par.int_raw  = 10;
col_par.int_filt = 11;

col_par.pos_x_sub = 14;
col_par.pos_y_sub = 13;
col_par.pos_z_sub = 15;


%- For results of pre-detection
col_par.pos_y_det = 1;
col_par.pos_x_det = 2;
col_par.pos_z_det = 3;

col_par.det_qual_score      = 12;  % Contains quality score
col_par.det_qual_score_norm = 13;  % Contains normalized quality score
col_par.det_qual_score_th   = 14;    % Contains thresholding based on quality score