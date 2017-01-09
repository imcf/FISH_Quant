function [spots_array] = FQ_spots_array_v1(img,spots_detected,spots_array)

%===  Extract immediate environment for each spot in 3d


%- Get relevant parameters
size_crop  = img.settings.avg_spots.crop;
dim        = img.dim;

disp('... spot mosaicing...');    

%- Create empty array (with dimension 0 for the 4th one = where the different spots are saved)
if isempty(spots_array)
    spots_array = zeros(2*size_crop.xy+1,2*size_crop.xy+1,2*size_crop.z+1,0);
end
     

for i = 1:size(spots_detected,1)    

    y_min = spots_detected(i,1)-size_crop.xy;
    y_max = spots_detected(i,1)+size_crop.xy;

    x_min = spots_detected(i,2)-size_crop.xy;
    x_max = spots_detected(i,2)+size_crop.xy;

    z_min = spots_detected(i,3)-size_crop.z;
    z_max = spots_detected(i,3)+size_crop.z;

    if y_min < 1;     continue;     end
    if y_max > dim.Y; continue; end  
    
    if x_min < 1;     continue;     end
    if x_max > dim.X; continue; end  
    
    if z_min < 1;     continue;     end
    if z_max > dim.Z; continue; end        

    %- For raw data
    sub_spot   = double(img.raw(y_min:y_max,x_min:x_max,z_min:z_max));

    %- Assign
    spots_array(:,:,:,end+1) = sub_spot;
end


