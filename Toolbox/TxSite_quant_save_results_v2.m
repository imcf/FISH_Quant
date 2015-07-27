function TxSite_quant_save_results_v2(REC_prop,parameters)

file_name_save_REC = parameters.file_name_save_REC;
file_name_save_RES = parameters.file_name_save_RES;

img_TS  = REC_prop.img_TS;
img_REC = REC_prop.img_fit;
img_RES = REC_prop.img_res;

%- Get positive and negative residuals
img_RES_pos = img_RES.*(img_RES>0);
img_RES_neg = img_RES.*(img_RES<0);
img_RES_neg = -1*img_RES_neg;    % Bring back to positive values

%- Compose images
img_TS_REC      = cat(2, img_TS, img_REC);
img_Res_pos_neg = cat(2, img_RES_pos, img_RES_neg);

%- Save images
image_save_v2(img_TS_REC,file_name_save_REC);
image_save_v2(img_Res_pos_neg,file_name_save_RES);