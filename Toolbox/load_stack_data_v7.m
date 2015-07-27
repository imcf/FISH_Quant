function [img, status_file] = load_stack_data_v7(file_name,parameters)
% Load a stack of images and return a structure:
%
%   img.data  : the stack of images
%   img.h     : the height of the images
%   img.w     : the width of the images
%   img.size  : the number of images in the stack 

% v3 
% - based on bfopen_v1 rather than tiff-read. Allows reading in
% deltavision files as well.

%- Get parameters - set default if parameters is not defined (backward compatible)
if nargin == 1
    flag.bfopen = 1;
    flag.output = 0;
else
    flag = parameters.flag;
end

%- Default output-parameters
status_file = 1;
img.data    = [];

%- Open files
[dum, dum, ext] = fileparts(file_name);

if exist(file_name,'file') == 2

    if 0 % strcmpi(ext,'.tif') || strcmpi(ext,'.stk')
%         img = tiffread29(file_name);
%         img = dat2mat3d_v1(img);
        
    else
        if flag.bfopen

            data = bfopen(file_name);
            dum  = data{1};

            %-Dimensions of image
            [img.h,   img.w]  = size(dum{1});
            img.size = size(dum,1);

            %- Intensity values of image
            data_mat = zeros(img.h,img.w,img.size);
            for iP =1:img.size
               data_mat(:,:,iP) = dum{iP,1};        
            end
            img.data = data_mat;
        else
            img.data = [];
            
            %- Show warning if output flag is defined and set to 1
            if isfield(flag,output)
                if flag.output
                    warndlg('Cant open file (bfopen not defined)',mfilename)
                end
            end
            
            status_file = 0;
        end

    end
    
else
    if flag.output
        warndlg(['File: ', file_name,' not found'],mfilename)
    end
    img.data    = [];
    status_file = 0;
    
end
    
    