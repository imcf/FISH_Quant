function [center] = ait_centroid3d_v3(img,xdata)
% Function takes a picture as an argument (suitably should contain only one 
% object whose centroid is to be obtained) and returns the x and y
% coordinates of its centroid.
%
% 2D case developed by Fahd A. Abbasi (ait_centroid)
% http://www.mathworks.com/matlabcentral/fileexchange/5457-centroid-calculation-function
%
% 3D extension by Herve
%
% v3
% - vectors x,y,z are input paramters of the function

  
x1 = xdata(1,:);
y1 = xdata(2,:);

x = reshape(x1,size(img));
y = reshape(y1,size(img));

%= 2D
if( size(img,3)==1 )
    area = sum(img(:));
    meanx = sum(sum(sum(double(img).*x)))/area;
    meany = sum(sum(sum(double(img).*y)))/area;
    center=[meanx , meany];  

%= 3D
else
    z1 = xdata(3,:);    
    z = reshape(z1,size(img));
    
    area = sum(img(:));
    dx=(img).*x;
    dy=(img).*y;
    dz=(img).*z;
    meanx = sum(dx(:))/area;
    meany = sum(dy(:))/area;
    meanz = sum(dz(:))/area;
    center=[meanx , meany, meanz];
end;



%
%
%    [ny,nx] = size(z);
%    [px,py] = meshgrid(1:nx,1:ny);
%     sz = sum(z(:));
%    x0 = sum(sum(z.*px))/sz;
%    y0 = sum(sum(z.*py))/sz;