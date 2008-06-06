% Swastika curve

function main()

   % linewidth and font size
   lw= 4; 
   fs = 25;

% colors
   red=[0.867 0.06 0.14];
   blue = [0, 129, 205]/256;
   green = [0, 200,  70]/256;
   black = [0, 0, 0];
   white = 0.99*[1, 1, 1];

   % Set up the plotting window
   figure(1); clf; set(gca, 'fontsize', fs, 'linewidth', lw/4);
   hold on; axis equal; grid on;

   N=500;  % number of points (don't make it big, code will be slow)
   Lx1 = -2; Lx2 = 2; Ly1 = -2; Ly2 = 2;
   
   [X, Y]=meshgrid(linspace(Lx1, Lx2, N), linspace(Ly1, Ly2, N));   % X and Y coordinates

   Ncurves = 10;
   A = linspace(0, 1, Ncurves);

   figure(2); clf; hold on; axis equal; axis off;

   x = X; y = Y;
   Z = y.^4-x.^4-x.*y;
          
%  graph the curves using 'contour' in figure (2)
   figure(2); [c, stuff] = contour(X, Y, Z, [0, 0]);
          
%  extract the curves from c and graph them in figure(1) using 'plot'
%  need to do this kind of convoluted work since plot2svg can't save
%  the result of 'contour' but can save the result of 'plot'   
          
   [m, n] = size(c);
   while n > 0
          
          l=c(2, 1);
          x=c(1,2:(l+1));  y=c(2,2:(l+1)); % get x and y of contours
          figure(1); plot(x, y, 'color', red, 'linewidth', lw);
          
          c = c(:, (l+2):n);
          [m, n] = size(c);
                 
   end
   
   figure(1); axis equal; axis ([Lx1, Lx2, Ly1, Ly2]);

   set(gca, 'XTick', [-2, -1, 0, 1, 2]);  set(gca, 'YTick', [-2, -1, 0, 1, 2]);
   set(gca, 'GridLineStyle', '--');

   H=xlabel('x'); set(H, 'fontsize', fs);
   H=ylabel('y'); set(H, 'fontsize', fs);
   
   saveas(gcf, 'Swastica_curve3.eps', 'psc2')

