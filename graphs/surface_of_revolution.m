% illustration of a surface of revolution
function main()

   % the number of data points. More points means prettier picture.
   N = 300;

   a=-3; b = 4.3;

   % polar coordinates
   ZZ = linspace(a, b, N);
   TTheta = linspace(0, 2*pi, N);

   % mesh grid
   [Z, Theta] = meshgrid(ZZ, TTheta);

   % the curve we will revolve
   R = cos(Z)+2; 
   
   X = R.*cos(Theta); Y = R.*sin(Theta);

   figure(2); clf; hold on; axis equal; axis off;
  
% plot the surface
   H=surf(X, Y, Z); shading faceted;

   % pick a color
   mycolor=[184, 77, 66]/256; % pink brick
   mycolor=[184, 224, 98]/256; % light green
%   mycolor=[225, 168, 48]/256; % golden brown
%   mycolor=[0, 66, 17]/256; % dark green
%   mycolor=[225, 0, 84]/256; % pink

   % set some propeties
   set(H, 'FaceColor', mycolor, 'EdgeColor','none', 'FaceAlpha', 1);
   set(H, 'SpecularColorReflectance', 0.1, 'DiffuseStrength', 0.8);
   set(H, 'FaceLighting', 'phong', 'AmbientStrength', 0.3);
   set(H, 'SpecularExponent', 108);
   
% viewing angle
   view(0, 12);

% add in a source of light
   camlight (-50, 54); lighting phong;
   
   % save as png
  print('-dpng', '-r200', 'Surface_of_revolution_illustration.png');
