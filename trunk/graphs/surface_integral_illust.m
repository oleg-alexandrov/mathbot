% An illustration of the surface integral.
% It shows how a surface is split into surface elements.

function main ()

% the function giving the surface and its gradient
   f=inline('10-(x.^2+y.^2)/15', 'x', 'y');

   BoxSize=5; % surface dimensions are 2*BoxSize x 2*BoxSize
   M = 10; % M x M = the number of surface elements into which to split the surface
   N=100;  % N x N = number of points in each surface element
   spacing = 0.1; % spacing between surface elements
   H=2*BoxSize/(M-1); % size of each surface element
   gridsize=H/N;      % distance between points on a surface element 

   figure(1); clf; hold on; axis equal; axis off;

   for i=1:(M-1)
	  for j=1:(M-1)
		 Lx = -BoxSize + (i-1)*H+spacing; Ux = -BoxSize + (i  )*H-spacing;
		 Ly = -BoxSize + (j-1)*H+spacing; Uy = -BoxSize + (j  )*H-spacing;
		 
%        calc the surface element
		 XX=Lx:gridsize:Ux; 
		 YY=Ly:gridsize:Uy;
		 [X, Y]=meshgrid(XX, YY);
		 Z=f(X, Y);
		 
%        plot the surface element
		 surf(X, Y, Z, 'FaceColor','red', 'EdgeColor','none', ...
			  'AmbientStrength', 0.3, 'SpecularStrength', 1, 'DiffuseStrength', 0.8);

	  end
   end
   

   view (-18, 40);                     % viewing angle 
   camlight headlight; lighting phong; % make nice lightning 

%  save to file
   print('-dpng',  '-r200', 'Surface_integral_illustration.png');
