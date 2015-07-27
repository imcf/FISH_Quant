function [A] = hessian_finite_differences_v1(F,h1,k1)


[X,Y,Z] = size(F);
x0      = (X-1)/2+1;
y0      = (Y-1)/2+1;
z0      = (Z-1)/2+1;

h=h1;
k=k1;


Axx = (F(x0+h,y0,z0 ) - 2*F(x0,y0,z0) +  F(x0-h,y0,z0))./h1.^2;
Ayy = (F(x0,y0+h,z0 ) - 2*F(x0,y0,z0) +  F(x0,y0-h,z0))./h1.^2;
Azz = (F(x0,y0,z0+h ) - 2*F(x0,y0,z0) +  F(x0,y0,z0-h))./k1.^2;
Axy = (F(x0+h,y0+h,z0 ) - F(x0+h,y0-h,z0) - F(x0-h,y0+h,z0 ) - F(x0-h,y0-h,z0))./(4.*h1*k1);
Axz = (F(x0+h,y0,z0+k ) - F(x0+h,y0,z0-k) - F(x0-h,y0,z0+k ) - F(x0-h,y0,z0-k))./(4.*h1*k1);
Ayz = (F(x0,y0+h,z0+k ) - F(x0,y0+h,z0-k) - F(x0,y0-h,z0+k ) - F(x0,y0-h,z0-k))./(4.*h1*k1);


A=[Axx, Axy, Axz;...
   Axy, Ayy, Ayz;...
   Axz, Ayz, Azz]; 