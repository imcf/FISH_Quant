function [sub_spots, sub_spots_filt, spots_detected] = FQ_spots_moscaic_v1(img,spots_detected)

%===  Extract immediate environment for each spot in 3d


%- Get relevant parameters
size_crop  = img.settings.detect.reg_size;  
dim        = img.dim;

%- Pre-allocate memory
N_Spots        = size(spots_detected,1);
sub_spots      = {};
sub_spots_filt = {};
y_min_spots = zeros(N_Spots,1);
y_max_spots = zeros(N_Spots,1);
x_min_spots = zeros(N_Spots,1);
x_max_spots = zeros(N_Spots,1);
z_min_spots = zeros(N_Spots,1);
z_max_spots = zeros(N_Spots,1);


disp('... sub-spot mosaicing...');    
sub_spots_max = [];

for i = 1:N_Spots    

    y_min = spots_detected(i,1)-size_crop.xy;
    y_max = spots_detected(i,1)+size_crop.xy;

    x_min = spots_detected(i,2)-size_crop.xy;
    x_max = spots_detected(i,2)+size_crop.xy;

    z_min = spots_detected(i,3)-size_crop.z;
    z_max = spots_detected(i,3)+size_crop.z;

    if y_min < 1;     y_min = 1;     end
    if y_max > dim.Y; y_max = dim.Y; end  
    
    if x_min < 1;     x_min = 1;     end
    if x_max > dim.X; x_max = dim.X; end  
    
    if z_min < 1;     z_min = 1;     end
    if z_max > dim.Z; z_max = dim.Z; end        

    %- For raw data
    dum           = double(img.raw(y_min:y_max,x_min:x_max,z_min:z_max));
    sub_spots{i}  = dum;
    sub_spots_max(i,1) = max(dum(:));
    
    %- For filtered data     
    if ~isempty(img.filt)
        sub_spots_filt{i} = double(img.filt(y_min:y_max,x_min:x_max,z_min:z_max));  
    end
    
    %- Save values
    y_min_spots(i) = y_min;
    y_max_spots(i) = y_max;     
    x_min_spots(i) = x_min;  
    x_max_spots(i) = x_max;
    z_min_spots(i) = z_min;
    z_max_spots(i) = z_max;
end


%- Assign values
spots_detected(:,4)   = y_min_spots;
spots_detected(:,5)   = y_max_spots;
spots_detected(:,6)   = x_min_spots;             
spots_detected(:,7)   = x_max_spots;
spots_detected(:,8)   = z_min_spots;
spots_detected(:,9)   = z_max_spots; 
spots_detected(:,10)  = sub_spots_max; 
