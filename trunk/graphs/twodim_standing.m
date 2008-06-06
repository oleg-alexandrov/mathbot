% illustration of a standing wave in two dimensions

% box size
Lx = 3; 
Ly = 4; 

h= 0.01; % grid size
[X, Y] = meshgrid(0:h:Lx, 0:h:Ly);

numP_x = 2; numP_y = 3; % number of peaks in x and y

Z=sin(2*pi*numP_x*X/Lx).*sin(2*pi*numP_y*Y/Ly);

% normalize from 0 to scale
scale = 33;
%Z = Z - min(min(Z));
%Z = Z/max(max(Z));

M=10;
T=linspace(0.0, 2*pi, M); T=T(1:(M-1));
shift = 1;

for p=1:1
   for iter=1:length(T)

      figure(1); clf; hold on;

      t = T(iter);
 
      %surf(X, Y, sin(t)*Z); shading flat;
      %axis([0, Lx, 0, Ly, -1, 1])
      
      image(scale*((Z*sin(t)+shift)));
      axis equal; axis xy;
      axis off;

      file=sprintf('Frame%d.png', 1000+iter);
      disp(sprintf('Saving to %s', file));
      print('-dpng',  '-zbuffer',  '-r100', file);
      pause(0.2);
      
   end

end

% saved to gif with the command
% convert -density 100 -loop 1000 -delay 10 Frame100* Two_dim_standing_wave.gif
% then cropped and scaled in Gimp