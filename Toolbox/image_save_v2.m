function image_save_v2(img,name_save,bit_depth)
%
% Function to save PSF as actual image. 
%
% Florian Mueller, muef@gmx.net
%
% === INPUT PARAMETER
% img       ... 3d array with actual image
% name_save ... Name to save file (path+file name). If empty user will be
%               asked to specify name
%
% === FLAGS
%
%
% === OUTPUT PARAMETERS
%
%
% === VERSION HISTORY
%
% v1 Feb 8,2011
% - Initial implementation

%- Get default parameters
if isempty(name_save)
    file_default                    = ['IMG_',datestr(date, 'yymmdd'),'.tif'];
    [file_name_save,path_name_save] = uiputfile(file_default,'Specify file name to save image'); 

    name_save = fullfile(path_name_save,file_name_save);
else
    file_name_save = 1;
end

%- Number of input paramters 
if nargin < 3
    
      int_max = max(max(img));
      
      if int_max < 65536
            bit_depth = 16; 
            disp('Image currently saved as 16-bit ....')
       else
            bit_depth = 16; 
            disp('Image currently saved as 32-bit ....')
      end
end

%% Convert image
switch bit_depth
    
    case 8
      img = uint8(img);
      flag_write_TIFF_struct = 0;
      
    case 16
       img = uint16(img);
       flag_write_TIFF_struct = 0;
       
    case 32
       img = uint32(img);
       flag_write_TIFF_struct = 1;
       
    otherwise
        errordlg('Bit depth has to be 8,16, or 32','Save TIFF file')
        return
end


%% Write image only if file name was specified

if file_name_save ~= 0

    
    %- Use standard image write
    if ~flag_write_TIFF_struct
    
    
        %= Dimensions of image
        [dim.Y dim.X dim.Z] = size(img);

        %= Write first plane in not append mode
        img_plane = uint16(round(img(:,:,1)));
        imwrite(img_plane,name_save,'tif','Compression','none','WriteMode','overwrite')  

        %- Write image
        for iZ = 2:1:dim.Z
            img_plane = uint16(round(img(:,:,iZ)));
            imwrite(img_plane,name_save,'tif','Compression','none','WriteMode','append')   
        end

        
    %- Use TIFF struct to generate 32-bit image    
    else


        %-- Generate tag structure
        tagstruct.ImageLength     = size(img,1);
        tagstruct.ImageWidth      = size(img,2);
        tagstruct.BitsPerSample   = bit_depth;
        tagstruct.Software        = 'Matlab';
        tagstruct.Photometric     = Tiff.Photometric.MinIsBlack;
        tagstruct.Compression     = 1; % None
        tagstruct.SamplesPerPixel = 1;
        tagstruct.RowsPerStrip    = size(img,2);
        tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
        tagstruct.SampleFormat     = 1;

        %% Write image

        %- Write first plane
        t = Tiff(name_save,'w');   % Open to write
        t.setTag(tagstruct);
        t.write(img(:,:,1));

        %- Write other planes
        for iZ = 2:1:size(img,3)

            t = Tiff(name_save,'a');  % Open to append
            t.setTag(tagstruct);
            t.write(img(:,:,iZ));

        end

        t.close()
    end
end

disp('Image was saved!')