% illustration of a standing wave in two dimensions

% box size
Lx = 3; 
Ly = 4; 

h= 0.1; % grid size
[X, Y] = meshgrid(0:h:Lx, 0:h:Ly);

numP_x = 2; numP_y = 3; % number of peaks in x and y

Z=0.5*sin(2*pi*numP_x*X/Lx).*sin(2*pi*numP_y*Y/Ly);

% normalize from 0 to scale
scale = 0.5;
%Z = Z - min(min(Z));
%Z = Z/max(max(Z));

M=11;
T=linspace(0.0, 2*pi, M); T=T(1:(M-1)); T = T + 0.5*pi/(M-1);
shift = 1;

for p=1:1
   for iter=1:length(T)

      %figure(1); clf; hold on;

      t = T(iter);

      figure(1); clf;  hold on;
      surf(X, Y, Z*cos(t));
      caxis([-1, 1]);
      shading faceted;
      colormap autumn;

      
      axis equal; axis off;
      axis([0, Lx, 0, Ly, -1, 1]);

      % viewing angle
      view(38, 42);

      %H=text(0, -0.3, 1.4, sprintf('(%d, %d) mode', k, p), 'fontsize', 25);
      %image(scale*((Z*sin(t)+shift)));
      %axis equal; axis xy;
      %axis off;

      file=sprintf('Frame%d.png', 1000+iter);
      disp(sprintf('Saving to %s', file));
      print('-dpng',  '-zbuffer',  '-r100', file);
      pause(0.2);
      
   end

end

% saved to gif with the command
% convert -density 100 -loop 1000 -delay 20 Frame1* Two_dim_standing_wave.gif
% then cropped and scaled in Gimp.
