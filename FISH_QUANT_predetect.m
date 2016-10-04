function varargout = FISH_QUANT_predetect(varargin)
% FISH_QUANT_PREDETECT MATLAB code for FISH_QUANT_predetect.fig
% Last Modified by GUIDE v2.5 27-May-2016 15:46:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FISH_QUANT_predetect_OpeningFcn, ...
                   'gui_OutputFcn',  @FISH_QUANT_predetect_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before FISH_QUANT_predetect is made visible.
function FISH_QUANT_predetect_OpeningFcn(hObject, eventdata, handles, varargin)

disp(' ')
disp('+++ FISH-QUANT: pre-detection')
disp('- Pre-processing')
        
handles.output = hObject;
handles.status_1st_plot = 1;


%- Set font-size to 10
%  For whatever reason are all the fonts on windows are set back to 8 when the
%  .fig is openend
h_font_8 = findobj(handles.h_fishquant_predetect,'FontSize',8);
set(h_font_8,'FontSize',10)

%- Get installation directory of FISH-QUANT and initiate 
p = mfilename('fullpath');        
handles.FQ_path = fileparts(p); 

assignin('base','h_predetect',handles.h_fishquant_predetect)

%- Other parameters
handles.status_analysis_all_cells = 0;
handles.status_pre_detect    = 0;
handles.status_quality_score = 0;
handles.status_ccc           = 0;
handles.status_nonMaxSupr    = 0;
handles.status_region_changed = 0;

handles.closeFigure = false;

%= Get data from main GUI
if not(isempty(varargin))

    if strcmp( varargin{1},'HandlesMainGui')
        
        handles.child = 1;        
        
        %- Get parameters from main interface
        handles_MAIN = varargin{2};
        handles.img  = handles_MAIN.img;

        %- Change name of GUI
        set(handles.h_fishquant_predetect,'Name', ['FISH-QUANT ', handles.img.version, ': pre-detection']);
        
        %- If not cell_prop are defined 
        if isempty(handles.img.cell_prop) 
            handles.img.cell_prop = define_cell_prop(handles);
            handles.cell_ind_main = 1;
            
        else
            %- Selected cell in main window    
            handles.cell_ind_main = get(handles_MAIN.pop_up_outline_sel_cell,'Value');  
        end  
        
        %- Analyze cells
        handles = analyze_cellprop(hObject, eventdata, handles);
        
        %- Image data        
        handles.img_lin = handles.img.filt(:);

        handles.img_min  = min(handles.img_lin);
        handles.img_max  = max(handles.img_lin);
        handles.img_diff = handles.img_max - handles.img_min;
        handles.img_plot = handles.img.filt_proj_z;  

        %= Get 3D masks
        handles = get_3D_masks(handles,handles.cell_ind_main);
        
        %- Analyze cellular intensity to get automatic ranges
        if ~handles.img.status_detect_val_auto
        
            mask_cell_2D = handles.img.cell_prop(handles.cell_ind_main).mask_cell_2D;       
            int_MIP_cell = handles.img_plot(mask_cell_2D);  %- Get all value of cell
            
            
            val_mean  = mean(int_MIP_cell);
            val_std   = std(double(int_MIP_cell));
            th_int_max = ceil(3*quantile(int_MIP_cell,0.99));
            th_int_min = floor(val_mean+1.5*val_std);        
        
            %- Take random samples
            y_random = datasample(int_MIP_cell,10000);
            [counts, bin] = hist(double(y_random),250);
                                    
            h_fig = figure(789); set(h_fig,'color','w')
            set(gcf,'Name','Histogram of pixel values in filtered image')
            set(gcf,'Toolbar','none')
            set(gcf,'NumberTitle','off')
            set(gcf,'MenuBar','none')
            
            s1 = subplot(211);
            plot(bin,counts,'k','LineWidth',2)   
            
            hold on            
                plot([th_int_min th_int_min],[1 max(counts)],'b')
                plot([th_int_max th_int_max],[1 max(counts)],'r')
            hold off
            xlabel('Intensity')
            ylabel('Frequency')
            legend('Pixel intensity','Threshold: tested min','Threshold: tested max') 
            
            s2=subplot(212);
            box on
            copyobj(allchild(s1),s2);
            set(gca,'yscale','log');
            xlabel('Intensity')
            ylabel('Frequency [log]')
            
            
        else
            th_int_min  = floor(handles.img.settings.detect.th_int_min);
            th_int_max  = ceil(handles.img.settings.detect.th_int_max);
        end
           
        %=== Range to calculate plateau  
        nTH                = handles.img.settings.detect.nTH;
        flag_detect_region = handles.img.settings.detect.flags.detect_region;
        
        dlgTitle = 'Calculate pre-detection threshold         ';

        prompt_avg(1) = {'Minimum intensity threshold to test'};
        prompt_avg(2) = {'Maximum intensity threshold to test'};
        prompt_avg(3) = {'Number of intensity values to test'};
        prompt_avg(4) = {'Analysis region: 0-cell; 1-cyto; 2-nuc' };
        prompt_avg(5) = {'Detection method: 1-local max; 2-conn comp'};
        prompt_avg(6) = {'Propose automatically calculated threshold'};
      
        defaultValue_avg{1} = num2str(th_int_min);
        defaultValue_avg{2} = num2str(th_int_max);
        defaultValue_avg{3} = num2str(nTH);
        defaultValue_avg{4} = num2str(flag_detect_region);
        
        switch handles.img.settings.detect.method
            case 'nonMaxSupr'
                defaultValue_avg{5} = '1';
            case 'connectcomp'
                defaultValue_avg{5} = '2';
        end
        
        defaultValue_avg{6} = num2str(handles.img.settings.detect.flags.auto_th);
        
        options.Resize='on';
        userValue = inputdlg(prompt_avg,dlgTitle,1,defaultValue_avg,options);
        %if exist('h_fig'), close(h_fig), end
        
        if( ~ isempty(userValue))
            th_int_min         = str2double(userValue{1}); 
            th_int_max         = str2double(userValue{2});
            nTH                = str2double(userValue{3});
            flag_detect_region = str2double(userValue{4});
            flag_detect_method = str2double(userValue{5});
            flag_auto_th       = str2double(userValue{6});
            
            if flag_detect_method ==1 
                set(handles.popupmenu_predetect_mode,'Value',flag_detect_method);
                detect_method = 'nonMaxSupr';
            elseif flag_detect_method == 2
                set(handles.popupmenu_predetect_mode,'Value',flag_detect_method)
                detect_method = 'connectcomp';
            else
               warndlg('Value for pre-detection method not allowed')
               disp(flag_detect_method);
            end
            
            handles.closeFigure = false;
        else
            handles.closeFigure = true;
        end
    
        if not(handles.closeFigure)
        
            %- Check if values have already been used
            status_same_par =   ...
                            nTH == handles.img.settings.detect.nTH && ...
                            th_int_min == handles.img.settings.detect.th_int_min    && ...    
                            th_int_max == handles.img.settings.detect.th_int_max && ...
                            flag_detect_region == handles.img.settings.detect.flags.detect_region && ...
                            strcmp(detect_method,handles.img.settings.detect.method) && ...
                            isfield(handles.img.settings.detect,'data_th') && ~isempty(handles.img.settings.detect.data_th);
                        
            %- Save settings for pre-detection
            handles.img.status_detect_val_auto = 1;   
            handles.img.settings.detect.nTH                 = nTH;
            handles.img.settings.detect.th_int_min          = th_int_min;
            handles.img.settings.detect.th_int_max          = th_int_max;
            handles.img.settings.detect.th_int_diff         = th_int_max-th_int_min;
            handles.img.settings.detect.flags.detect_region = flag_detect_region;
            handles.img.settings.detect.flags.auto_th       = flag_auto_th;
            
            %- Roughly set detection threshold if it was never set
            if handles.img.settings.detect.thresh_int == -1
                handles.img.settings.detect.thresh_int = round(mean([th_int_min th_int_max]));
            end
            
            %- Set parameters
            set(handles.text_par_plot_N,'String',num2str(handles.img.settings.detect.nTH));
            set(handles.text_par_plot_int_min,'String',num2str(handles.img.settings.detect.th_int_min));
            set(handles.text_par_plot_int_max,'String',num2str(handles.img.settings.detect.th_int_max));

            set(handles.text_detect_region_xy,'String',num2str(handles.img.settings.detect.reg_size.xy))
            set(handles.text_detect_region_z,'String',num2str(handles.img.settings.detect.reg_size.z))   

            set(handles.text_detect_region_xy_sep,'String',num2str(handles.img.settings.detect.reg_size.xy_sep))
            set(handles.text_detect_region_z_sep,'String',num2str(handles.img.settings.detect.reg_size.z_sep)) 

            set(handles.text_detection_threshold,'String',handles.img.settings.detect.thresh_int);
            set_slider_int(handles,handles.img.settings.detect.thresh_int);
            set(handles.text_detect_th_qual,'String',handles.img.settings.detect.thresh_score);        

            set(handles.checkbox_smaller_detection,'Value',handles.img.settings.detect.flags.region_smaller);
            set(handles.checkbox_status_reg_detect_sep,'Value',handles.img.settings.detect.flags.reg_pos_sep);

            str_scores = get(handles.pop_up_detect_quality, 'String');
            str_match  = find(strcmpi(handles.img.settings.detect.score ,str_scores));        
            set(handles.pop_up_detect_quality,'Value',str_match);    
            
            %- Set selection for regions to analyze
            set(handles.popupmenu_region,'Value',flag_detect_region+1);

            %- Plot results
            if ~status_same_par
                handles = popupmenu_region_Callback(hObject, eventdata, handles);
                handles = popupmenu_predetect_mode_Callback(hObject, eventdata, handles);
            else
               
                switch detect_method
                    
                    case 'nonMaxSupr'
                        
                        handles.locmax_thresholds = handles.img.settings.detect.data_th(:,1);
                        handles.locmax_counts     = handles.img.settings.detect.data_th(:,2);
                        handles.status_nonMaxSupr = 1;
            
                    case  'connectcomp'
                        handles.thresholds  = handles.img.settings.detect.data_th(:,1);
                        handles.thresholdfn = handles.img.settings.detect.data_th(:,2);
                        handles.status_ccc = 1;
   
                end
                plot_hist_int(hObject, eventdata, handles)
            end            
            checkbox_status_reg_detect_sep_Callback(hObject, eventdata, handles)
        end 
    end
end


% Update handles structure
guidata(hObject, handles);

if not(handles.closeFigure) 
    uiwait(handles.h_fishquant_predetect);    % UIWAIT makes FISH_QUANT_predetect wait for user response (see UIRESUME)
end


%=== Get 3D mask
function handles = get_3D_masks(handles,ind_cell)


% --> logical operator with shortcut
%      proceed if field there is no field or if it's empty
if  ~isfield(handles.img.cell_prop(ind_cell),'mask_cell_3D') || isempty(handles.img.cell_prop(ind_cell).mask_cell_3D)
    
    %= Get masks for nucleus and cytoplasm    
    mask_cell_2D     = poly2mask(handles.img.cell_prop(ind_cell).x, handles.img.cell_prop(ind_cell).y, handles.img.dim.Y, handles.img.dim.X);
    mask_cell_3D     = repmat(mask_cell_2D,[1,1,handles.img.dim.Z]);   

    if not(isempty(handles.img.cell_prop(ind_cell).pos_Nuc))

        mask_nuc_2D     = poly2mask(handles.img.cell_prop(ind_cell).pos_Nuc.x, handles.img.cell_prop(ind_cell).pos_Nuc.y, handles.img.dim.Y, handles.img.dim.X);
        mask_nuc_3D     = repmat(mask_nuc_2D,[1,1,handles.img.dim.Z]);      

        mask_cyto_3D              = mask_cell_3D;
        mask_cyto_3D(mask_nuc_3D) = 0;

    else
        mask_nuc_3D  = mask_cell_3D;
        mask_cyto_3D = mask_cell_3D;
        disp('NO NUCLEUS DEFINED!');
    end     

    %- Save the masks
    handles.img.cell_prop(ind_cell).mask_cell_3D = mask_cell_3D;
    handles.img.cell_prop(ind_cell).mask_cell_2D = mask_cell_2D;
    handles.img.cell_prop(ind_cell).mask_nuc_3D  = mask_nuc_3D;
    handles.img.cell_prop(ind_cell).mask_cyto_3D = mask_cyto_3D;         
    
    %- Restrict image to cell
    dim_cell.min_X  = min(handles.img.cell_prop(ind_cell).x);
    dim_cell.max_X  = max(handles.img.cell_prop(ind_cell).x);

    dim_cell.min_Y  = min(handles.img.cell_prop(ind_cell).y);
    dim_cell.max_Y  = max(handles.img.cell_prop(ind_cell).y);

    %- Catch too small or too large values
    if dim_cell.min_X < 1; dim_cell.min_X = 1; end
    if dim_cell.min_Y < 1; dim_cell.min_Y = 1; end

    if dim_cell.max_X > handles.img.dim.X; dim_cell.max_X = handles.img.dim.X; end
    if dim_cell.max_Y > handles.img.dim.Y; dim_cell.max_Y = handles.img.dim.Y; end

    handles.img.cell_prop(ind_cell).dim_cell = dim_cell;

end

%== Outputs from this function are returned to the command line.
function varargout = FISH_QUANT_predetect_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.img;
    
if not(handles.closeFigure)
    delete(handles.h_fishquant_predetect);
else
    delete(handles.h_fishquant_predetect);
    %button_close_GUI_Callback(hObject, eventdata, handles)
end


%== Executes when user attempts to close h_fishquant_predetect.
function h_fishquant_predetect_CloseRequestFcn(hObject, eventdata, handles)
%delete(hObject);


%== Define properties of cells
function cell_prop = define_cell_prop(handles)

%- Dimension of entire image
w = handles.img.dim.X;
h = handles.img.dim.Y;

cell_prop(1).x      = [1 1 w w];
cell_prop(1).y      = [1 h h 1];
cell_prop(1).reg_type = 'Rectangle';
cell_prop(1).reg_pos  = [1 1 w h];

%- Other parameters
cell_prop(1).label = 'EntireImage';
cell_prop(1).FIT_Result     = {};
cell_prop(1).pos_TS         = [];
cell_prop(1).pos_Nuc         = [];
cell_prop(1).spots_fit       = [];
cell_prop(1).thresh          = [];
cell_prop(1).spots_proj      = 0;
cell_prop(1).status_filtered = 0;
cell_prop(1).str_list_TS     = [];
cell_prop(1).TS_counter      = 1;
cell_prop(1).status_image    = 1;
cell_prop(1).status_detect   = 0;
cell_prop(1).status_fit      = 0;
cell_prop(1).status_avg      = 0;
cell_prop(1).status_avg_rad  = 0;
cell_prop(1).status_avg_con  = 0;    


%= Function to analyze detected regions
function handles = analyze_cellprop(hObject, eventdata, handles)

cell_prop = handles.img.cell_prop;

%- Populate pop-up menu with labels of cells
N_cell = size(cell_prop,2);

[dim.Y, dim.X, dim.Z] = size(handles.img.raw);

if N_cell > 0

    %- Call pop-up function to show results and bring values into GUI
    for i = 1:N_cell
        str_menu{i,1} = cell_prop(i).label;
    end  
else
    str_menu = {' '};
end

%- Save and analyze results
set(handles.pop_up_cell_select,'String',str_menu);
set(handles.pop_up_cell_select,'Value',handles.cell_ind_main);

handles.img.cell_prop  = cell_prop;

%- Save everything
guidata(hObject, handles); 


%==========================================================================
%== Closing GUI
%==========================================================================

%== With pre-detection on all cells
function button_finished_Callback(hObject, eventdata, handles)

%- Parameters of cells
cell_prop  = handles.img.cell_prop;
N_cells    = length(cell_prop);

%- Get parameters for pre-detection
handles.img.settings.detect.flags.output              = 0;  
handles.img.settings.detect.flags.detect_region       = get(handles.popupmenu_region,'Value') - 1; % Correspondin flags start at 0 (that's why the -1 is needed)
handles.img.settings.detect.flags.region_smaller      = get(handles.checkbox_smaller_detection,'Value');
handles.img.settings.detect.flags.reg_pos_sep         = get(handles.checkbox_status_reg_detect_sep,'Value');
handles.img.settings.detect.thresh_int                = str2double(get(handles.text_detection_threshold,'String'));


%- Get quality score
str = get(handles.pop_up_detect_quality, 'String');
val = get(handles.pop_up_detect_quality,'Value');
handles.img.settings.detect.score        = str{val};
handles.img.settings.detect.thresh_score = str2double(get(handles.text_detect_th_qual,'String'));

%- Used to compensate for spots that were close the edge 
dim_sub_xy = 2*handles.img.settings.detect.reg_size.xy+1;
dim_sub_z  = 2*handles.img.settings.detect.reg_size.z+1;

%- Loop over all cells
for ind_cell = 1:N_cells
     
    %- Predetect & calculate and apply quality score
    handles.img.spots_predect(ind_cell);
    handles.img.spots_quality_score(ind_cell);
    handles.img.spots_quality_score_apply(ind_cell,1);  % 1 is for flag_remove --> spots will be removed after thresholding
    
    N_spots    = size( handles.img.cell_prop(ind_cell).spots_detected,1);
    
    if N_spots > 0
    
        %- Calculate projections for plot with montage function
        for k=1:N_spots

            %- MIP in XY, padd if necessary
            MIP_xy =  max(handles.img.cell_prop(ind_cell).sub_spots{k},[],3);
            [dim_MIP_1,dim_MIP_2] = size(MIP_xy);
            MIP_xy = padarray(MIP_xy,[dim_sub_xy-dim_MIP_1 dim_sub_xy-dim_MIP_2],'post'); 
            spots_proj.xy(:,:,1,k) = MIP_xy;
            
            %- MIP in XZ, padd if necessary
            MIP_xz = squeeze(max(handles.img.cell_prop(ind_cell).sub_spots{k},[],1))';
            [dim_MIP_1,dim_MIP_2] = size(MIP_xz);
            MIP_xz = padarray(MIP_xz,[dim_sub_z-dim_MIP_1 dim_sub_xy-dim_MIP_2],'post'); 
            spots_proj.xz(:,:,1,k) = MIP_xz;
        end

         %- Save results
         handles.img.cell_prop(ind_cell).status_detect  = 1;
         handles.img.cell_prop(ind_cell).spots_proj     = spots_proj; 
    else
         handles.img.cell_prop(ind_cell).status_detect  = 1;
         handles.img.cell_prop(ind_cell).spots_proj     = [];
    end
end
    
guidata(hObject, handles); 
uiresume(handles.h_fishquant_predetect)


%== Just closing without pre-detection
function button_close_GUI_Callback(hObject, eventdata, handles)
uiresume(handles.h_fishquant_predetect)


%==========================================================================
%== Change pre-detection mode
%==========================================================================

%== Different method
function handles = popupmenu_predetect_mode_Callback(hObject, eventdata, handles)

val = get(handles.popupmenu_predetect_mode,'Value');
str = get(handles.popupmenu_predetect_mode,'String');

%- Parameters to calc # of spots
parameters.nTH         = str2double(get(handles.text_par_plot_N,'String'));
parameters.th_int_min  = str2double(get(handles.text_par_plot_int_min,'String'));
parameters.th_int_max  = str2double(get(handles.text_par_plot_int_max,'String'));
parameters.flag_detect_region  = get(handles.popupmenu_region,'Value') - 1; % -1 because of the way the flag is defined (starts at 0)

size_detect            = handles.img.settings.detect.reg_size; 

%- Determine if the parameters are new
if parameters.nTH ~= handles.img.settings.detect.nTH                || ...
   parameters.th_int_min ~= handles.img.settings.detect.th_int_min  || ...
   parameters.th_int_max ~= handles.img.settings.detect.th_int_max  || ...
   handles.status_region_changed

   handles.status_nonMaxSupr = 0;
   handles.status_ccc        = 0;
end

%- Save the parameters
handles.img.settings.detect.nTH             = parameters.nTH;
handles.img.settings.detect.th_int_min      = parameters.th_int_min;
handles.img.settings.detect.th_int_max      = parameters.th_int_max;

flag_reg_pos_sep = get(handles.checkbox_status_reg_detect_sep,'Value');


%- Process
switch str{val}
    
    case 'Local maximum'
        handles.img.settings.detect.method = 'nonMaxSupr';
        
        if handles.status_nonMaxSupr == 0
        
            thresholds = linspace(parameters.th_int_min,parameters.th_int_max,parameters.nTH);
            
            if thresholds(2) - thresholds(1) < 1
                thresholds = parameters.th_int_min:1:parameters.th_int_max;
                warndlg(['Spacing of thresholds smaller than 1. Will set # of tested values to ', num2str(length(thresholds)), ' such that spacing is 1.']) 
                parameters.nTH = length(thresholds);
            end
          
            if flag_reg_pos_sep == 0
                rad_detect = round([size_detect.xy size_detect.xy size_detect.z]);
            else
                rad_detect = round([size_detect.xy_sep size_detect.xy_sep size_detect.z_sep]);
            end

            %- Check if 2D & then use only 2D parameters
            if ~handles.img.status_3D
                rad_detect = rad_detect(1:2);
            end
            
            %- Number of thresholds to compute
            set(handles.h_fishquant_predetect,'Pointer','watch');
            status_text = {' ';'== Determining local maximum ... please wait ... '};
            status_update(hObject, eventdata, handles,status_text);
            
            fprintf('- Computing threshold (of %d):    1',parameters.nTH);

            for i_th = 1:parameters.nTH 

              %- Apply threshold
              detect_th_loop = thresholds(i_th);
              pos_pre_detect = nonMaxSupr(double(handles.image_filt_mask), rad_detect,detect_th_loop);

              counts(i_th) = size(pos_pre_detect,1);
              fprintf('\b\b\b%3i',i_th);
            end;

            fprintf('\n');
            
            handles.locmax_thresholds = thresholds;
            handles.locmax_counts     = counts;
            handles.status_nonMaxSupr = 1;
            
            %- Save calculated thresholds
            data_th(:,1) = thresholds;
            data_th(:,2) = counts;

            set(handles.h_fishquant_predetect,'Pointer','arrow');
            status_text = {' ';'   Local maxium detection finished!'};
            status_update(hObject, eventdata, handles,status_text);
        end
        
    case 'Connected components'
        
        handles.img.settings.detect.method = 'connectcomp';
        
        if handles.status_ccc == 0
        
            set(handles.h_fishquant_predetect,'Pointer','watch');
            status_text = {' ';'== Determining connected components ... please wait ... '};
            status_update(hObject, eventdata, handles,status_text);
            

            parameters.conn        = 26;   % Connectivity in 3D
            parameters.thresholds  = [];
            [thresholdfn, thresholds] = multithreshstack_v4(handles.image_filt_mask,parameters);      
             
            %- Save calculated thresholds
            data_th(:,1) = thresholds;
            data_th(:,2) = thresholdfn;
            
            %- Save results
            handles.thresholdfn = thresholdfn;
            handles.thresholds  = thresholds;
            
            handles.status_ccc = 1;
            
            set(handles.h_fishquant_predetect,'Pointer','arrow');
            status_text = {' ';'   Connected components DETECTED!'};
            status_update(hObject, eventdata, handles,status_text); 
        end
end

%= Automatically calculate thresholds
if handles.img.settings.detect.flags.auto_th 
    par.flag_plot = 100;
    [int_th, count_th] = handles.img.calc_auto_det_th(data_th,par);
    handles.int_th     = int_th;
    set(handles.text_detection_threshold,'String',num2str(round(handles.int_th.mean)));
end

%= Provide them as a global variable
global FQ_data_th
FQ_data_th = data_th;

%= Save detection tresholds
handles.img.settings.detect.data_th = data_th;

%= Save data and plot
set(handles.text_par_plot_N,'String', num2str(length(thresholds)));

handles.region_changed = 0;
guidata(hObject, handles);
plot_hist_int(hObject, eventdata, handles)


%== Different region
function handles = popupmenu_region_Callback(hObject, eventdata, handles)


%- set image to zero in relevant regions
flag_detect_region = get(handles.popupmenu_region,'Value') - 1;     % Has to be +1 because of the way the flag is defined (starts at 0)

%- Check if masks have already been calculated or not
ind_analyze = get(handles.pop_up_cell_select,'Value');
handles     = get_3D_masks(handles,ind_analyze);
dim_cell    = handles.img.cell_prop(ind_analyze).dim_cell;


%- Restrict image to cell
image_filt_mask = handles.img.filt;
switch flag_detect_region

    %- Entire cell
    case 0
        image_filt_mask(not(handles.img.cell_prop(ind_analyze).mask_cell_3D)) = 0;
        handles.image_filt_mask = image_filt_mask(dim_cell.min_Y:dim_cell.max_Y,dim_cell.min_X:dim_cell.max_X,:);     
        
    %- Only cyto
    case 1
        image_filt_mask(not(handles.img.cell_prop(ind_analyze).mask_cyto_3D)) = 0;
        handles.image_filt_mask = image_filt_mask(dim_cell.min_Y:dim_cell.max_Y,dim_cell.min_X:dim_cell.max_X,:);   
        
    %- Only nuc    
    case 2
       image_filt_mask(not(handles.img.cell_prop(ind_analyze).mask_nuc_3D)) = 0;
       handles.image_filt_mask = image_filt_mask(dim_cell.min_Y:dim_cell.max_Y,dim_cell.min_X:dim_cell.max_X,:);     
       
    %- All cells 
    case 3
      % image_filt_mask(not(handles.mask_cell_3D)) = 0;     
       handles.image_filt_mask = image_filt_mask;
        
    otherwise
        disp('Bad selection: popupmenu_region_Callback');
end

handles.status_region_changed = 1;
 
guidata(hObject, handles);
            
  

%==========================================================================
%== Different region for detection of position
%==========================================================================

function checkbox_status_reg_detect_sep_Callback(hObject, eventdata, handles)

status_sep = get(handles.checkbox_status_reg_detect_sep,'Value');

if status_sep
    set(handles.text_detect_region_xy_sep,'Enable','on'); 
    set(handles.text_detect_region_z_sep,'Enable','on'); 
    
    set(handles.text_detect_region_xy_sep,'Value',handles.img.settings.detect.reg_size.xy_sep); 
    set(handles.text_detect_region_xy_sep,'Value',handles.img.settings.detect.reg_size.z_sep); 
  
else
    set(handles.text_detect_region_xy_sep,'Enable','off'); 
    set(handles.text_detect_region_z_sep,'Enable','off');   
end


%==========================================================================
%== Pre-detection of location
%==========================================================================

%== Function to set slider for intensity threshold for detection
 function set_slider_int(handles,int_value)
 
%- Set slider for detection threshold            
slider_value = (int_value-handles.img.settings.detect.th_int_min)/handles.img.settings.detect.th_int_diff;

if slider_value > 1; slider_value = 1; end
if slider_value < 0; slider_value = 0; end

set(handles.slider_hist_int,'Value',slider_value);


%== Intensity threshold: change slider value
function slider_hist_int_Callback(hObject, eventdata, handles)

%- Set text value
slider_value = get(handles.slider_hist_int,'Value');

th_int_min  = handles.img.settings.detect.th_int_min;
th_int_diff  = handles.img.settings.detect.th_int_diff;

int_value = round(th_int_min + th_int_diff*slider_value);
set(handles.text_detection_threshold,'String',num2str(int_value));

%- Plot
handles.img.settings.detect.flags.auto_th = 0;
plot_hist_int(hObject, eventdata, handles)
guidata(hObject, handles);


%== Intensity threshold: change text box
function text_detection_threshold_Callback(hObject, eventdata, handles)

%- Set slider
int_value    = str2double(get(handles.text_detection_threshold,'String'));
set_slider_int(handles,int_value);

%- Plot
handles.img.settings.detect.flags.auto_th = 0;
plot_hist_int(hObject, eventdata, handles)
guidata(hObject, handles);


%== Plot histogram of intensity
function plot_hist_int(hObject, eventdata, handles)

detect_th = str2double(get(handles.text_detection_threshold,'String'));

%- Detection parameters
detect = handles.img.settings.detect;

%- Select axis
axes(handles.axes_hist_int)

%- Specify global variable that allows judging pre-detection sensitivity
global data_predetect
data_predetect = [];


switch handles.img.settings.detect.method
    
    case 'nonMaxSupr'

        data_predetect(:,1) = handles.locmax_thresholds;
        data_predetect(:,2) = handles.locmax_counts;
        
        %- Plot histogram
        plot(handles.locmax_thresholds,handles.locmax_counts) 
        v = axis;
        hold on
        plot([detect_th, detect_th], [0.1, 1e5],'-r')
        hold off
        axis([min(handles.locmax_thresholds) max(handles.locmax_thresholds) v(3) 1.05*v(4)])
        xlabel('Threshold [intensity]');
        ylabel('Number of detected spots')
        title('Histogram of all pixel intensities [filtered image]')

    case 'connectcomp'
        
        data_predetect(:,1) = handles.thresholds;
        data_predetect(:,2) = handles.thresholdfn;
        
        
        mean_val = mean(handles.thresholdfn);
        
        %- Plot histogram
        plot(handles.thresholds, handles.thresholdfn);
        xlabel('Threshold [intensity]');
        ylabel('Number of detected spots')
        ylim([0 3*mean_val]); % Zoom in on important area
        v = axis;
        hold on
        plot([detect_th, detect_th], [0.1, 1e5],'-r')
        hold off
        %axis(v)
        axis([detect.th_int_min detect.th_int_max 0 3*mean_val])
end
   
        
%== Perform pre-detection
function button_analyze_localization_Callback(hObject, eventdata, handles)

     
%- Get parameters for pre-detection
handles.img.settings.detect.flags.output              = 1;  
handles.img.settings.detect.flags.detect_region       = get(handles.popupmenu_region,'Value') - 1; % Correspondin flags start at 0 (that's why the -1 is needed)
handles.img.settings.detect.flags.region_smaller      = get(handles.checkbox_smaller_detection,'Value');
handles.img.settings.detect.flags.reg_pos_sep         = get(handles.checkbox_status_reg_detect_sep,'Value');
handles.img.settings.detect.thresh_int                = str2double(get(handles.text_detection_threshold,'String'));

%- Detection and other things
ind_analyze = get(handles.pop_up_cell_select,'Value');
handles.img.spots_predect(ind_analyze);

%- Update status
N_spots     = size(handles.img.cell_prop(ind_analyze).spots_detected,1);
status_text = {' ';['== Intensity: ', num2str(handles.img.settings.detect.thresh_int),', # of spot-candidates: ',num2str(N_spots)]};
status_update(hObject, eventdata, handles,status_text);

%- Save results
handles.flag_spots           = 1;
handles.status_pre_detect    = 1;
handles.status_quality_score = 0;
guidata(hObject, handles);

%- Plot results
plot_hist_int(hObject, eventdata, handles);
handles = plot_image(hObject,handles,handles.axes_img,[]);
cla(handles.axes_hist_qual)

%- Calculate the corresponding quality scores
handles = pop_up_detect_quality_Callback(hObject, eventdata, handles);

% Update handles structure
guidata(hObject, handles);


%== Show detected spots
function button_show_detected_spots_Callback(hObject, eventdata, handles)
  
handles.ind_cell_sel = get(handles.pop_up_cell_select,'Value');
FISH_QUANT_spots('HandlesMainGui',handles);  



%==========================================================================
%== Quality score
%==========================================================================

%== Function to set slider for quality score
function set_slider_qual(handles,qual_value)
        
%- Set slider
slider_value = (qual_value-handles.thresh.qual_min)/handles.thresh.qual_diff;

if slider_value > 1; slider_value = 1; end

if slider_value < 0; slider_value = 0;end

set(handles.slider_qual_score,'Value',slider_value);


%== Calculate the quality score
function handles = pop_up_detect_quality_Callback(hObject, eventdata, handles)

%- Get quality score
str   = get(handles.pop_up_detect_quality, 'String');
val   = get(handles.pop_up_detect_quality,'Value');
score = str{val};

if ~handles.img.status_3D  && strcmp(score,'Curvature')

    score = 'Standard deviation';
    set(handles.pop_up_detect_quality,'Value',1);
    status_text = {' '; 'CURVATURE is only available for 3D images.';'Will use standard deviation instead.'};
    status_update(hObject, eventdata, handles,status_text);
end
    
handles.img.settings.detect.score = score;

%- Calculate quality score
ind_analyze    = get(handles.pop_up_cell_select,'Value');
handles.img.spots_quality_score(ind_analyze);
spots_detected = handles.img.cell_prop(ind_analyze).spots_detected;

% Spots found
if ~isempty(spots_detected)
    
    [handles.qual_count,handles.qual_bin] = hist(spots_detected(:,12),30);
    handles.thresh.qual_max               = max(spots_detected(:,12));
    handles.thresh.qual_min               = min(spots_detected(:,12));
    handles.thresh.qual_diff              = handles.thresh.qual_max-handles.thresh.qual_min;
    handles.status_quality_score          = 1;
   
    %- Save, plot and give some information
    guidata(hObject, handles);
    plot_qualityscore(hObject, eventdata, handles)

    status_text = {' '; 'Quality scores calculated'};
    status_update(hObject, eventdata, handles,status_text);

% No spots found
else
    
    status_text = {' '; 'Not spots detected'};
    status_update(hObject, eventdata, handles,status_text);
    handles.thresh.qual_max = []; 
    guidata(hObject, handles);
end


%== Apply threshold
function button_qual_apply_Callback(hObject, eventdata, handles)

%- Parameters
ind_analyze                              = get(handles.pop_up_cell_select,'Value');
handles.img.settings.detect.thresh_score = str2double(get(handles.text_detect_th_qual,'String'));

%- Apply & give some information
th_counts = handles.img.spots_quality_score_apply(ind_analyze,0);  % 0 is for flag_remove --> spots will not be removed after thresholding
status_text = {' ';['== Score threshold: ', num2str(handles.img.settings.detect.thresh_score),', # spots total/in/out: ',num2str(th_counts(1)),'/',num2str(th_counts(2)),'/',num2str(th_counts(3))]};
status_update(hObject, eventdata, handles,status_text);

%- Only if spots were actually detected
if th_counts(1) > 0
    handles.flag_spots = 2;
    guidata(hObject, handles);
    plot_qualityscore(hObject, eventdata, handles)
    handles = plot_image(hObject,handles,handles.axes_img,[]);
    guidata(hObject, handles);
end


%== Plot histogram of intensity
function plot_qualityscore(hObject, eventdata, handles)

detect_th_score = str2double(get(handles.text_detect_th_qual,'String'));

%- Plot histogram
axes(handles.axes_hist_qual)
bar(handles.qual_bin,handles.qual_count,'FaceColor','b') 
v = axis;
hold on
plot([detect_th_score, detect_th_score], [0.0, +20*max(handles.qual_count)],'-r')
hold off
axis(v)
xlabel('Quality score')
ylabel('Counts')
title('Histogram of quality score of all candidates')


%== Change slider of quality score
function slider_qual_score_Callback(hObject, eventdata, handles)

if not(isempty(handles.thresh.qual_max))
    
    %- Set text value
    slider_value = get(handles.slider_qual_score,'Value');

    qual_min   = handles.thresh.qual_min;
    qual_diff  = handles.thresh.qual_diff;

    qual_value = round(qual_min + qual_diff*slider_value);
    set(handles.text_detect_th_qual,'String',num2str(qual_value));    
  
    %- Plot
    plot_qualityscore(hObject, eventdata, handles)
    guidata(hObject, handles);
else
    status_text = {' ';'== NO SPOTS DETECTED'};
    status_update(hObject, eventdata, handles,status_text);
end


%== Text value for threshold
function text_detect_th_qual_Callback(hObject, eventdata, handles)

if not(isempty(handles.thresh.qual_max))
    
    %- Set slider
    qual_value    = str2double(get(handles.text_detect_th_qual,'String'));
    set_slider_qual(handles,qual_value)

    %- Plot
    plot_qualityscore(hObject, eventdata, handles)
    guidata(hObject, handles);
else
    status_text = {' ';'== NO SPOTS DETECTED'};
    status_update(hObject, eventdata, handles,status_text);
end



%==========================================================================
%== Mixed functions
%==========================================================================

%= Zoom in
function toolbar_zoom_in_ClickedCallback(hObject, eventdata, handles)
h_zoom = zoom;
set(h_zoom,'Enable','on');
set(h_zoom, 'Direction','in')


%= Zoom in
function toolbar_zoom_out_ClickedCallback(hObject, eventdata, handles)
h_zoom = zoom;
set(h_zoom,'Enable','on');
set(h_zoom, 'Direction','out')

%= Pan
function toolbar_pan_ClickedCallback(hObject, eventdata, handles)
pan on


%== Show filtered image
function pushbutton_show_filtered_Callback(hObject, eventdata, handles)
imtool(uint16(handles.img_plot),[]);


%== Apply new intensity range
function pushbutton_redo_plot_Callback(hObject, eventdata, handles)
handles = popupmenu_region_Callback(hObject, eventdata, handles);
handles = popupmenu_predetect_mode_Callback(hObject, eventdata, handles);
guidata(hObject, handles); 


%== Update status
function status_update(hObject, eventdata, handles,status_text)
status_old = get(handles.list_box_status,'String');
status_new = [status_old;status_text];
set(handles.list_box_status,'String',status_new)
%set(handles.list_box_status,'ListboxTop',round(size(status_new,1)))
set(handles.list_box_status,'Value',round(size(status_new,1)))
drawnow
guidata(hObject, handles); 


%== Plot detected spots
function handles  = plot_image(hObject,handles,axes_select,flag_spots)

%- Might be called with no cell properties defined
ind_cell       = get(handles.pop_up_cell_select,'Value');
cell_prop      = handles.img.cell_prop;
spots_detected = cell_prop(ind_cell).spots_detected;
status_sep_ccc = 0;

        
%- 1. Plot image in separate window
if isempty(axes_select)
    figure
    
    v = axis;
    if strcmpi(handles.img.settings.detect.method,'connectcomp')
        ax(2) = subplot(1,2,2);
        status_sep_ccc = 1;
    end
    
    imshow(handles.img_plot,[]);
else
    axes(axes_select);
    v = axis;
    h = imshow(handles.img_plot,[]);
    set(h, 'ButtonDownFcn', @axes_img_ButtonDownFcn)
end

title('Maximum projection of loaded image','FontSize',9);
colormap(hot)

%- 2. Plot-spots
if not(isempty(spots_detected))
    
    %- Spots that will be shown 
    ind_plot_in  = spots_detected(:,handles.img.col_par.det_qual_score_th)  == 1; 
    ind_plot_out = not(ind_plot_in);
    
    %- Plot spots        
    hold on
        plot(spots_detected(ind_plot_in,2),  spots_detected(ind_plot_in,1),'+g','MarkerSize',10);
        plot(spots_detected(ind_plot_out,2), spots_detected(ind_plot_out,1),'+r','MarkerSize',10); 
    hold off
    title(['Detected spots', num2str(length(ind_plot_in))],'FontSize',9); 
    colormap(hot)
    freezeColors(gca)
    
    %- Provide the appropriate legends
    is_IN  = sum(ind_plot_in);
    is_OUT = sum(ind_plot_out);
    
    
    if is_IN && is_OUT 
        legend('Selected Spots','Rejected Spots');      
    elseif is_IN && not(is_OUT) 
        legend('Selected Spots');
    elseif not(is_IN) && is_OUT 
        legend('Rejected Spots');
    end 
end


%- 3. Plot outline if specified

hold on
if isfield(handles,'cell_prop')    

    if not(isempty(cell_prop))  
        for i_cell = 1:size(cell_prop,2)
            x = cell_prop(i_cell).x;
            y = cell_prop(i_cell).y;
            plot([x,x(1)],[y,y(1)],'b','Linewidth', 2)  
            
            %- Nucleus
            pos_Nuc   = cell_prop(i_cell).pos_Nuc;   
            if not(isempty(pos_Nuc))  
                for i_nuc = 1:size(pos_Nuc,2)
                    x = pos_Nuc(i_nuc).x;
                    y = pos_Nuc(i_nuc).y;
                    plot([x,x(1)],[y,y(1)],':b','Linewidth', 2)  
               end                
            end                    

            %- TS
            pos_TS   = cell_prop(i_cell).pos_TS;   
            if not(isempty(pos_TS))  
                for i_TS = 1:size(pos_TS,2)
                    x = pos_TS(i_TS).x;
                    y = pos_TS(i_TS).y;
                    plot([x,x(1)],[y,y(1)],'b','Linewidth', 2)  

                end                
            end            
            
        end

        
        %- Plot selected cell in different color
        x = cell_prop(ind_cell).x;
        y = cell_prop(ind_cell).y;
        plot([x,x(1)],[y,y(1)],'y','Linewidth', 2)  

        %- Nucleus
        pos_Nuc   = cell_prop(ind_cell).pos_Nuc;   
        if not(isempty(pos_Nuc))  
            for i_nuc = 1:size(pos_Nuc,2)
                x = pos_Nuc(i_nuc).x;
                y = pos_Nuc(i_nuc).y;
                plot([x,x(1)],[y,y(1)],':y','Linewidth', 2)  
           end                
        end           

        %- TS
        pos_TS   = cell_prop(ind_cell).pos_TS;   
        if not(isempty(pos_TS))  
            for i = 1:size(pos_TS,2)
                x = pos_TS(i).x;
                y = pos_TS(i).y;
                plot([x,x(1)],[y,y(1)],'y','Linewidth', 2)  

            end                
        end                        
    end        
end
hold off
    

if status_sep_ccc == 1
    
    label_best     = labelmatrix(handles.CC_best);
    ims_comp_xy    = max(round(label_best),[],3);
    Lrgb           = label2rgb(ims_comp_xy, 'jet', 'k', 'shuffle');
    
    ax(1) = subplot(1,2,1);
    imshow(Lrgb,[],'Parent',ax(1));
    linkaxes(ax);
end

%- Same zoom as before
if not(handles.status_1st_plot)
    if axes_select == handles.axes_img
        axis(v);
    end
end

handles.status_1st_plot = 0;

% Update handles structure
guidata(hObject, handles);

%== Double click opens in new window
function axes_img_ButtonDownFcn(hObject, eventdata, handles)
sel_type = get(gcf,'selectiontype');    % Normal for single click, Open for double click
   
if strcmp(sel_type,'open')
    handles = guidata(hObject);        % Appears that handles are not always input parameter for function call
    plot_image(hObject,handles,[],[]);
end


%= Change size of detection region
function text_detect_region_xy_Callback(hObject, eventdata, handles)
size_xy = str2double(get(handles.text_detect_region_xy,'String')); 
handles.img.settings.detect.reg_size.xy = size_xy; % handles.size_detect.xy = size_xy;
guidata(hObject, handles);


%= Change size of detection region
function text_detect_region_z_Callback(hObject, eventdata, handles)
size_z = str2double(get(handles.text_detect_region_z,'String'));
handles.img.settings.detect.reg_size.z = size_z; %handles.size_detect.z = size_z; 
guidata(hObject, handles);


%= Change size of separate detection region
function text_detect_region_xy_sep_Callback(hObject, eventdata, handles)
size_xy = str2double(get(handles.text_detect_region_xy_sep,'String')); 
handles.img.settings.detect.reg_size.xy_sep = size_xy; % handles.size_detect.xy = size_xy;
guidata(hObject, handles);


%= Change size of separate detection region
function text_detect_region_z_sep_Callback(hObject, eventdata, handles)
size_z = str2double(get(handles.text_detect_region_z_sep,'String'));
handles.img.settings.detect.reg_size.z_sep = size_z; %handles.size_detect.z = size_z; 
guidata(hObject, handles);



%==========================================================================
%== Not used functions
%==========================================================================

function checkbox_proc_all_cells_Callback(hObject, eventdata, handles)

function checkbox_parallel_computing_Callback(hObject, eventdata, handles)

function text_detect_region_xy_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_detect_region_z_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pop_up_detect_quality_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_detection_threshold_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function slider_hist_int_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function list_box_status_Callback(hObject, eventdata, handles)

function list_box_status_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_detect_th_qual_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function slider_qual_score_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function pushbutton5_Callback(hObject, eventdata, handles)

function h_fishquant_predetect_ButtonDownFcn(hObject, eventdata, handles)

function checkbox_smaller_detection_Callback(hObject, eventdata, handles)

function popupmenu_predetect_mode_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_par_plot_int_min_Callback(hObject, eventdata, handles)

function text_par_plot_int_min_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_par_plot_N_Callback(hObject, eventdata, handles)

function text_par_plot_N_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_par_plot_int_max_Callback(hObject, eventdata, handles)

function text_par_plot_int_max_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_detect_region_xy_sep_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_detect_region_z_sep_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pop_up_outline_sel_cell_Callback(hObject, eventdata, handles)

function pop_up_outline_sel_cell_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popupmenu_region_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pop_up_cell_select_Callback(hObject, eventdata, handles)

function pop_up_cell_select_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
