function res = erf2(a,b,mux,sigmax)

alpha = (a - mux)/(sqrt(2)*sigmax);
beta  = (b - mux)/(sqrt(2)*sigmax);


%- Rescaling necessary because of definition of erf in Matlab and
%  transformation of variables
%
%  Erf describes integrated intensity in pixel.

%res = sigmax*sqrt(2) * (sqrt(pi)/2)*( erf(beta)-erf(alpha));

res = sigmax * sqrt(pi/2) * ( erf(beta)-erf(alpha));
