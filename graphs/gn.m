function main()
   r1 = inline('2.*x+4.*y-x.^3-1.3',    'x', 'y');
   r2 = inline('3.*x-2.*y+2.*x.*y+0.1', 'x', 'y');
   r3 = inline('5.*x+y+x.*y.^2-0.9',    'x', 'y');

   
   lw = 2;

   % colors
   red=[0.867 0.06 0.14];
   blue = [0, 129, 205]/256;
   green = [0, 200,  70]/256;
   black = [0, 0, 0];
   white = 0.99*[1, 1, 1];


   Box=[0, 1, 0, 1];
   figure(1); clf;
   %set(gca, 'fontsize', fs);
   hold on;
   axis equal;
   %axis off; 

   plot_contours (r1, r2, r3, Box, lw, red);

   a = 0.1248;
   b = 0.2639;
   r1(a, b)
   r2(a, b)
   r3(a, b)
   
   
function plot_contours (r1, r2, r3, Box, lw, color);
   
   N=200;  % number of points (don't make it big, code will be slow)

   % X and Y coordinates
   [X, Y]=meshgrid(linspace(Box(1), Box(2), N), linspace(Box(3), Box(4), N)); 

   Z = r1(X, Y).^2 + r2(X, Y).^2 + r3(X, Y).^2;

   No = 25; % number of contours
   Levels = linspace(0, 1, No).^2; 

% Plot the contours with 'contour' in figure(2), and then with 'plot' in figure(1).
% This is to avoid a bug in plot2svg, it can't save output of 'contour'.
   figure(2); clf; hold on;
   for i=1:length(Levels)

      figure(2);
      [c, stuff] = contour(X, Y, Z, [Levels(i), Levels(i)]);

      [m, n]=size(c);
      if m > 1 & n > 0

	 % extract the contour from the contour matrix and plot in figure(1)
	 l=c(2, 1);
	 x=c(1,2:(l+1));  y=c(2,2:(l+1)); 
	 figure(1); plot(x, y, 'color', color, 'linewidth', lw/2);

      end
   end
   figure(1);
