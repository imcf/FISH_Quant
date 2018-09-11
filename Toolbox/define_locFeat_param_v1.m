function feat_param = define_locFeat_param_v1
% FUNCTION. Define different parameters to calculate localization features

%- Analysis of Ripley's L-function
feat_param.ripley.correction      = 1;  % Edge correction, 0=none, 1=renormalized border spot count, 2=spots at border are not considered
feat_param.ripley.space           = 1;  % Spacing for Ripley's K-function
feat_param.ripley.dist_interest   = 40; % Characteristic distance for the blob features (distance to which Ripley's k-function is considered)

%- Cell extension analysis with morphological opening
feat_param.cell_ext.disk_size = [15 30 45 60];  % Opening used to compare mRNA counts in cell extension to rest of the cell
feat_param.morph_opening_in_2D = 1; % Morphological opening is performed in 2D (after projection) or not.


%- For debugging: list feature names that should be debugged
feat_param.verbose = {''};


