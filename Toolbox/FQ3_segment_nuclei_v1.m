function [cell_prop] = FQ3_segment_nuclei_v1(img,par)

%% == Information about cell and image
cell_prop = img.cell_prop;
DAPI_XY   = uint16(img.DAPI_proj_z);

%% Parameters for segmentation
nuc_N_pix_min = par.N_pix_min;
flags         = par.flags;
th_DAPI       = par.th_DAPI;
N_cells       = length(cell_prop);  
status_current_cell =  par.status_current_cell;
    
%% Some pre-processing

%== Delete all saved nuclei - but only if all nuclei are detected
%automatically
if ~status_current_cell
    for i_cell = 1:N_cells
        cell_prop(i_cell).pos_Nuc = {};
    end
end
%% Use threshold to find nucleus
button = 'No';


while strcmp(button,'No')

    %=== Threshood and connected components

    %- Threshold
    DAPI_XY_TH = im2bw(DAPI_XY,th_DAPI);

    %- Connected components
    CC  = bwconncomp(DAPI_XY_TH);
    L   = labelmatrix(CC);
    RGB = label2rgb(L);


    %== Plot figure
    if flags.plot == 1
        h1 = figure(921);
        ax(1) = subplot(2,2,1);
        imshow(DAPI_XY,[])
        title('Processed DAPI')

        ax(2) = subplot(2,2,2);
        imshow(DAPI_XY_TH,[])
        title('Thresholded DAPI')

        ax(3) = subplot(2,2,3);
        imshow(DAPI_XY,[])
        hOVM = alphamask(DAPI_XY_TH, [0 1 0], 0.2);
        title('Thresholded DAPI - overlay')

        ax(4) = subplot(2,2,4);
        imshow(RGB,[])
        title('Connected comp')

        linkaxes([ax(1) ax(2) ax(3) ax(4)],'xy'); 
        set(h1,'Color','w');
    end
    
    if flags.dialog

        button = questdlg('Threshold to define nucleus ok?','DAPI','Yes');
    else
        button = 'Yes';
    end
    %close(h1);
end


%% Get only components that are large enough
ind_new = 1;
clear CC_new

CC_new.Connectivity = CC.Connectivity;
CC_new.ImageSize    = CC.ImageSize;
CC_new.PixelIdxList = CC.PixelIdxList;


if CC.NumObjects == 0
    CC_new = CC;
else
    

    for i_nuc = 1: CC.NumObjects

        ind_lin = CC.PixelIdxList{i_nuc};

        if length(ind_lin) > nuc_N_pix_min       
            CC_new.PixelIdxList{ind_new} = ind_lin;
            ind_new = ind_new +1;
        end

        CC_new.NumObjects = ind_new-1;
    end
end    

%% Find contour of nuclei
L     = labelmatrix(CC_new);
[B,L] = bwboundaries(L,'noholes');


%% Loop over all cells


%- Loop over all nuclei and assign to cells
for i = 1: length(B)

    coord_nuc = B{i};

    y_nuc = coord_nuc(:,1)';  % Row coordinate
    x_nuc = coord_nuc(:,2)';  % Column

    %- Find cell to which nucleus belongs
    ind_cell_Nuc = [];
    
    %- Restrict to currently selected cell
    if status_current_cell
        ind_start = status_current_cell;
        ind_end   = status_current_cell;    
    else
        ind_start = 1;
        ind_end   = N_cells;
    end
        
    for i_cell = ind_start:ind_end
        cell_X = cell_prop(i_cell).x;
        cell_Y = cell_prop(i_cell).y;   

        in_cell = inpolygon(x_nuc,y_nuc,cell_X,cell_Y);

        if in_cell
            ind_cell_Nuc = i_cell; 
        end
    end

    %- Assign to cell
    if not(isempty(ind_cell_Nuc))

        cell_prop(ind_cell_Nuc).pos_Nuc.coord    = coord_nuc;
        cell_prop(ind_cell_Nuc).pos_Nuc.x        = x_nuc;
        cell_prop(ind_cell_Nuc).pos_Nuc.y        = y_nuc;
        cell_prop(ind_cell_Nuc).pos_Nuc.label    = ['NUC_auto_', num2str(i)];
        cell_prop(ind_cell_Nuc).pos_Nuc.auto     = 1;
        cell_prop(ind_cell_Nuc).pos_Nuc.ind_cell = ind_cell_Nuc;

    end
end
   

