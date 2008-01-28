% an illustration of the surface normal

function main ()

% a few settings
   BoxSize=5;
   N=100;
   gridsize=BoxSize/N;
   lw=5;  % linewidth
   fs=35; % fontsize

% the function giving the surface and its gradient
   f=inline('10-(x.^2+y.^2)/15', 'x', 'y');
   fx=inline('-2*x/15', 'x', 'y');
   fy=inline('-2*y/15', 'x', 'y');

% calc the surface
   XX=-BoxSize:gridsize:BoxSize; 
   YY=-BoxSize:gridsize:BoxSize;
   [X, Y]=meshgrid(XX, YY);
   Z=f(X, Y);

% plot the surface
   H=figure(1); clf; hold on; axis equal; axis off;
   view (-19, 14); 
   surf(X, Y, Z, 'FaceColor','red', 'EdgeColor','none', ...
	'AmbientStrength', 0.3, 'SpecularStrength', 1, 'DiffuseStrength', 0.8);
   surf(X, Y, 0*Z+f(0, 0)+0.02, 'FaceColor', [0, 0, 1], 'EdgeColor','none', 'FaceAlpha', 0.4)

   camlight right; lighting phong; % make nice lightning 

% the vector at the current point, as well as its tangent and normal components
   Z0=[0, 0, f(0, 0)];
   n=[fx(0, 0), fy(0, 0), 1];
   n=2*n/norm(n);
   
% graph the vectors
   HH=quiver3(Z0(1), Z0(2), Z0(3), n(1), n(2), n(3), 0.8); set(HH(1), 'linewidth', lw);

   set(HH(2), 'linewidth', lw)
   set(HH(2), 'XData', 0.4*[-0.78408 0 0.78408 NaN])
   set(HH(2), 'YData', 0.4*[0.78408 0 -0.78408 NaN])
   set(HH(2), 'ZData', 1*[14.824 17.2 14.824 NaN])
%   get(HH(2))

   scale=8.5;
   text(scale*n(1), scale*n(2)-2, scale*n(3), '\it{n}', 'fontsize', fs)
   text(scale*n(1), scale*n(2)-1.1, scale*n(3), '\^', 'fontsize', fs)

%  save to file
   print('-dpng',  '-r300', 'surface_normal_illustration.png');
