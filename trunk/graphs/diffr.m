% diffraction by a slit

Lx = 5;
Ly = Lx/2;
lambda=0.15;
Sl = 2*lambda;
k = 2*pi/lambda;

np = 30;
N = 200;

[X, Y] = meshgrid(linspace(0, Lx, N), linspace(-Ly, Ly, N));
Sources = linspace(-Sl, Sl, np);

Z = 0*X;
I = sqrt(-1);

for i=1:np

   x0 = -lambda/3; y0 = Sources(i);

   R = sqrt((X-x0).^2+(Y-y0).^2);

   % trapezoidal rule
   if i==1 | i == np
      weight = 0.5;
   else
      weight = 1;
   end

   Z = Z + weight*(-I/lambda)*exp(I*k*R).*X./(R.*R);

end

Z = Z/np;

Z=[exp(I*k*(X-Lx)), Z];
figure(1);
imagesc(real(Z)); axis equal; axis off;