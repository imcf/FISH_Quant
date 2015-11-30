function [img, status_file] = img_load_stack_v1(file_name,par)
% Load a stack of images and return a structure:
%
%   img.data  : the stack of images
%   img.NY    : the height of the images
%   img.NX    : the width of the images
%   img.NZ    : the number of images in the stack 


%- Get parameters - set default if parameters is not defined (backward compatible)

%- If no additional parameters are defined
if nargin == 1
    par.flag_output = 0;
    par.range  = [];
    par.status_3D = 1;
end

% If only some additional parameters are defined
if ~isfield(par,'flag_output')
    par.flag_output = 0;
end
    
if ~isfield(par,'range')
    par.range = [];
end
   
if ~isfield(par,'status_3D')
    par.status_3D = 1;
end


%- Default output-parameters
status_file = 1;
img.data    = [];

%- Open files
if exist(file_name,'file') == 2

    %- Check if file is multi-stack
    r     = bfGetReader(file_name);
    N_img = r.getImageCount();
    N_Z   = r.getSizeZ();


    %- If not loading range is specified and the z-stack is too large
    if isempty(par.range)
        
        %- For 2D images
        if ~par.status_3D && N_img > 1

            dlg_title = ['Image has ', num2str(N_img),' frames'];
            prompt    = {'Specify which stack should be loaded                       :'};    
            num_lines = 1; def = {'1'};
            answer    = inputdlg(prompt,dlg_title,num_lines,def,'on');
            ind_load  = str2double(answer{1});

            if ind_load > 0

                %- Get start and end index of z-slice
                par.range.start = ind_load;
                par.range.end   = ind_load;
            end
        
   
        %- If number of z-stacks is larger than 1
        elseif par.status_3D && N_Z>1 && N_Z<N_img

            dlg_title = ['Image appears to have ', num2str(N_img/N_Z),' z-stacks'];
            prompt    = {'Specify which stack should be loaded (0 for all)                      :'};    
            num_lines = 1; def = {'1'};
            answer    = inputdlg(prompt,dlg_title,num_lines,def);
            ind_load  = str2double(answer{1});

            if ind_load > 0

                %- Get start and end index of z-slice
                par.range.start = (ind_load-1)*N_Z+1;
                par.range.end   = ind_load*N_Z;
            end

        %- If number of images is very large    
        elseif par.status_3D && N_img>500

            dlg_title = ['Image has many planes. Is it multi-stack?'];

            prompt{1}    = 'Number of planes per z-stack [0 for NO multi-stack]';
            prompt{2}    = 'Specify which stack should be loaded                              :';    
            num_lines = 1; def = {'6','1'};
            answer    = inputdlg(prompt,dlg_title,num_lines,def);
            N_Z       = str2double(answer{1});
            ind_load  = str2double(answer{2});

            if N_Z > 0

                %- Get start and end index of z-slice
                par.range.start = (ind_load-1)*N_Z+1;
                par.range.end   = ind_load*N_Z;
            end    

        end
    end

    %-Open image
    if isempty(par.range)
    
        data = bfopen(file_name);
        dum  = data{1};
       
         %-Dimensions of image
        [img.NY, img.NX]  = size(dum{1});
        img.NZ            = size(dum,1);

        %- Intensity values of image
        data_mat = zeros(img.NY,img.NX,img.NZ);

        for iP =1:img.NZ
           data_mat(:,:,iP) = dum{iP,1};        
        end

    else
        
      
        %== Get size in Y and X
        img.NY = r.getSizeY;
        img.NX = r.getSizeX;
        img.NZ = par.range.end-par.range.start+1;

        %- Get start and end index of z-slice
        ind_start = par.range.start;
        ind_end   = par.range.end;

        %- Open image: OPB
        data_mat = zeros(img.NY,img.NX,img.NZ);
        ind_loop = 1;
        for ind_load = ind_start:ind_end
            data_mat(:,:,ind_loop) = bfGetPlane(r, ind_load);
            ind_loop = ind_loop +1;
        end
  
    end

    %- Save image data
    img.data = data_mat;

else
    if par.flag_output
        warndlg(['File: ', file_name,' not found'],'mfilename')
    end
    img.data    = [];
    status_file = 0;
    
end
    
    