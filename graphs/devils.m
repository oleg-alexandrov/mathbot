% An illustration of Devil's curve

function main()

   % linewidth and font size
   lw= 30; 
   fs = 250;

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
   Lx = 2; Ly = 2;
   
   [X, Y]=meshgrid(linspace(-Lx, Lx, N), linspace(-Ly, Ly, N));   % X and Y coordinates

   Ncurves = 10;
   A = linspace(0, 1, Ncurves);

   figure(2); clf; hold on; axis equal; axis off;
   Color = jet;
   
   for a = A

	  b = 1;
	  Z = Y.^2.*(Y.^2 - a.^2) - X.^2.*(X.^2 - b.^2);
	  
%  graph the curves using 'contour' in figure (2)
	  figure(2); [c, stuff] = contour(X, Y, Z, [0, 0]);
	  
%  extract the curves from c and graph them in figure(1) using 'plot'
%  need to do this kind of convoluted work since plot2svg can't save
%  the result of 'contour' but can save the result of 'plot'   
	  
	  [m, n] = size(c);
	  while n > 0
		 
		 l=c(2, 1);
		 x=c(1,2:(l+1));  y=c(2,2:(l+1)); % get x and y of contours
		 figure(1); plot(x, y, 'color', Color(floor(58*a^2)+1, :), 'linewidth', lw/2);
		 
		 c = c(:, (l+2):n);
		 [m, n] = size(c);
		 
	  end
	  
   end;
   
   figure(1); axis equal; axis ([-Lx, Lx, -Ly, Ly]);

   plot2svg(sprintf('Devils_curve_a=0.0-1.0_b=%0.2g.svg', b));
%   saveas(gcf, sprintf('Devils_curve_a=%0.2g_b=%0.2g.eps', a, b), 'psc2');

   