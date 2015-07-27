function varargout = FISH_QUANT_restrict_par(varargin)
% FISH_QUANT_RESTRICT_PAR MATLAB code for FISH_QUANT_restrict_par.fig
% Last Modified by GUIDE v2.5 24-Nov-2011 13:38:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FISH_QUANT_restrict_par_OpeningFcn, ...
                   'gui_OutputFcn',  @FISH_QUANT_restrict_par_OutputFcn, ...
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


% --- Executes just before FISH_QUANT_restrict_par is made visible.
function FISH_QUANT_restrict_par_OpeningFcn(hObject, eventdata, handles, varargin)


%= Export figure handle to workspace 
assignin('base','h_FQ_restrict',handles.h_FQ_restrict)

%== Set font-size to 10 - In WIN all the fonts set back to 8
h_font_8 = findobj(handles.h_FQ_restrict,'FontSize',8);
set(h_font_8,'FontSize',10)

handles.fit_limits.sigma_xy_min = 0;
handles.fit_limits.sigma_xy_max = 500;

handles.fit_limits.sigma_z_min = 0;
handles.fit_limits.sigma_z_max = 2000;


if not(isempty(varargin))
    
    handles.child = 1; 
    parameters = varargin{1};
    
    handles.fit_limits        = parameters.fit_limits;
    handles.summary_fit_all   = parameters.summary_fit_all;    
    handles.col_par           = parameters.col_par;
   
    [handles.fit_stat ]       = analyze_cells(handles.summary_fit_all,handles.col_par);

end
       
%- Default range is not specified in settings file
handles.fit_limits.sigma_xy_min_def = 0;
handles.fit_limits.sigma_xy_max_def = 500;

handles.fit_limits.sigma_z_min_def = 0;
handles.fit_limits.sigma_z_max_def = 2000;


% Choose default command line output for FISH_QUANT_restrict_par
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
plot_all(hObject, eventdata, handles)

% UIWAIT makes FISH_QUANT_restrict_par wait for user response (see UIRESUME)
uiwait(handles.h_FQ_restrict);


% --- Outputs from this function are returned to the command line.
function varargout = FISH_QUANT_restrict_par_OutputFcn(hObject, eventdata, handles) 

%- Only if called from another GUI
if handles.child
    varargout{1} = handles.fit_limits;   
    delete(handles.h_FQ_restrict);
end


%== Executes when user attempts to close h_FQ_restrict.
function h_FQ_restrict_CloseRequestFcn(hObject, eventdata, handles)
if handles.child 
    uiresume(handles.h_FQ_restrict)
else
    delete(handles.h_FQ_restrict) 
end


%== Finished with assignment
function button_done_Callback(hObject, eventdata, handles)
uiresume(handles.h_FQ_restrict)



%== Range back to default
function [fit_stat]= analyze_cells(summary_fit_all,col_par)

if not(isempty(summary_fit_all))
    
    %- Calculate mean, median, stdev
    fit_stat.sigmaxy_mean =  round(mean(summary_fit_all(:,col_par.sigmax )));
    fit_stat.sigmaz_mean  =  round(mean(summary_fit_all(:,col_par.sigmaz )));


    fit_stat.sigmaxy_median =  round(median(summary_fit_all(:,col_par.sigmax )));
    fit_stat.sigmaz_median  =  round(median(summary_fit_all(:,col_par.sigmaz )));


    fit_stat.sigmaxy_stdev =  round(std(summary_fit_all(:,col_par.sigmax )));
    fit_stat.sigmaz_stdev  =  round(std(summary_fit_all(:,col_par.sigmaz)));

else
    %- Calculate mean, median, stdev
    fit_stat.sigmaxy_mean =  [];
    fit_stat.sigmaz_mean  =  [];


    fit_stat.sigmaxy_median =  [];
    fit_stat.sigmaz_median  =  [];


    fit_stat.sigmaxy_stdev =  [];
    fit_stat.sigmaz_stdev  =  [];
end
       
       
%== Range back to default
function button_range_no_Callback(hObject, eventdata, handles)

handles.fit_limits.sigma_xy_min = handles.fit_limits.sigma_xy_min_def;
handles.fit_limits.sigma_xy_max = handles.fit_limits.sigma_xy_max_def;
handles.fit_limits.sigma_z_min  = handles.fit_limits.sigma_z_min_def;
handles.fit_limits.sigma_z_max  = handles.fit_limits.sigma_z_max_def;

guidata(hObject, handles);
plot_all(hObject, eventdata, handles)


%== Assign default range: mean +/- stdev for sigma, mean for amp
function button_range_default_Callback(hObject, eventdata, handles)

fit_stat = handles.fit_stat;

handles.fit_limits.sigma_xy_min = fit_stat.sigmaxy_median - fit_stat.sigmaxy_stdev;
handles.fit_limits.sigma_xy_max = fit_stat.sigmaxy_median + fit_stat.sigmaxy_stdev;
handles.fit_limits.sigma_z_min  = fit_stat.sigmaz_median  - fit_stat.sigmaz_stdev;
handles.fit_limits.sigma_z_max  = fit_stat.sigmaz_median  + fit_stat.sigmaz_stdev;

guidata(hObject, handles);
plot_all(hObject, eventdata, handles)



%== Assign range: mean +/- stdev
function button_range_stdev_Callback(hObject, eventdata, handles)

fit_stat = handles.fit_stat;

handles.fit_limits.sigma_xy_min = fit_stat.sigmaxy_median - fit_stat.sigmaxy_stdev;
handles.fit_limits.sigma_xy_max = fit_stat.sigmaxy_median + fit_stat.sigmaxy_stdev;
handles.fit_limits.sigma_z_min  = fit_stat.sigmaz_median  - fit_stat.sigmaz_stdev;
handles.fit_limits.sigma_z_max  = fit_stat.sigmaz_median  + fit_stat.sigmaz_stdev;

guidata(hObject, handles);
plot_all(hObject, eventdata, handles)



%== Assign range: mean 
function button_range_mean_Callback(hObject, eventdata, handles)

fit_stat = handles.fit_stat;
      
handles.fit_limits.sigma_xy_min = fit_stat.sigmaxy_median ;
handles.fit_limits.sigma_xy_max = fit_stat.sigmaxy_median +1;
handles.fit_limits.sigma_z_min  = fit_stat.sigmaz_median  ;
handles.fit_limits.sigma_z_max  = fit_stat.sigmaz_median  +1;  

guidata(hObject, handles);
plot_all(hObject, eventdata, handles)



%== Sigma-XY: min
function text_sigmaxy_min_Callback(hObject, eventdata, handles)
handles.fit_limits.sigma_xy_min = str2double(get(handles.text_sigmaxy_min,'String'));
guidata(hObject, handles);
plot_all(hObject, eventdata, handles)


%== Sigma-XY: max
function text_sigmaxy_max_Callback(hObject, eventdata, handles)
handles.fit_limits.sigma_xy_max = str2double(get(handles.text_sigmaxy_max,'String'));
guidata(hObject, handles);
plot_all(hObject, eventdata, handles)


%== Sigma-Z: min
function text_sigmaz_min_Callback(hObject, eventdata, handles)
handles.fit_limits.sigma_z_min = str2double(get(handles.text_sigmaz_min,'String'));
guidata(hObject, handles);
plot_all(hObject, eventdata, handles)


%== Sigma-Z: max
function text_sigmaz_max_Callback(hObject, eventdata, handles)
handles.fit_limits.sigma_z_max = str2double(get(handles.text_sigmaz_max,'String'));
guidata(hObject, handles);
plot_all(hObject, eventdata, handles)



%== Sigma-XY: max
function plot_all(hObject, eventdata, handles)

summary_fit_all = handles.summary_fit_all;
fit_stat = handles.fit_stat;
fit_limits = handles.fit_limits;
col_par = handles.col_par;

if not(isempty(summary_fit_all))
    
    %- Set levels   
    set(handles.text_sigmaxy_min,'String',num2str(fit_limits.sigma_xy_min));
    set(handles.text_sigmaxy_max,'String',num2str(fit_limits.sigma_xy_max));
 
    set(handles.text_sigmaz_min,'String',num2str(fit_limits.sigma_z_min));
    set(handles.text_sigmaz_max,'String',num2str(fit_limits.sigma_z_max));

    %- Set median and mean values
    set(handles.text_sigmaxy_median,'String',num2str(fit_stat.sigmaxy_median));
    set(handles.text_sigmaxy_mean,'String',num2str(fit_stat.sigmaxy_mean));
    
    set(handles.text_sigmaz_median,'String',num2str(fit_stat.sigmaz_median));
    set(handles.text_sigmaz_mean,'String',num2str(fit_stat.sigmaz_mean));

    
   %-- Sigma_xy
   axes(handles.axes_sigmaxy)
   hist(summary_fit_all(:,col_par.sigmax),50)
   v1 = axis;
   hold on
   plot([fit_limits.sigma_xy_min fit_limits.sigma_xy_min],[0 1e8],'g');
   plot([fit_limits.sigma_xy_max fit_limits.sigma_xy_max],[0 1e8],'r');
   if not(isempty(fit_stat.sigmaxy_median))
        plot([fit_stat.sigmaxy_median fit_stat.sigmaxy_median],[0 1e8],'b');
   end 
   hold off
   axis(v1)
   
   %-- Sigma_z
   axes(handles.axes_sigmaz)
   hist(summary_fit_all(:,col_par.sigmaz),50)
   v1 = axis;
   hold on
   plot([fit_limits.sigma_z_min fit_limits.sigma_z_min],[0 1e8],'g');
   plot([fit_limits.sigma_z_max fit_limits.sigma_z_max],[0 1e8],'r');
   if not(isempty(fit_stat.sigmaz_median))
        plot([fit_stat.sigmaz_median fit_stat.sigmaz_median],[0 1e8],'b');
   end 
   hold off
   axis(v1)
  
   
else
   cla(handles.axes_sigmaxy)
   cla(handles.axes_sigmaz)
  
    %- Set levels   
    set(handles.text_sigmaxy_min,'String',num2str(fit_limits.sigma_xy_min));
    set(handles.text_sigmaxy_max,'String',num2str(fit_limits.sigma_xy_max));
 
    set(handles.text_sigmaz_min,'String',num2str(fit_limits.sigma_z_min));
    set(handles.text_sigmaz_max,'String',num2str(fit_limits.sigma_z_max));

        
    %- Set median and mean values
    set(handles.text_sigmaxy_median,'String','NO cells');
    set(handles.text_sigmaxy_mean,'String','');
    
    set(handles.text_sigmaz_median,'String','NO cells');
    set(handles.text_sigmaz_mean,'String','');

   
end


% =========================================================================
% Not used
% =========================================================================

function text_sigmaxy_min_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_sigmaxy_max_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_sigmaz_min_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_sigmaz_max_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
