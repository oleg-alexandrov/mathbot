% Syntractrix illustration

function main()

   % linewidth and font size
   lw= 6; 
   fs = 20;

% colors
   red=[0.867 0.06 0.14];
   blue = [0, 129, 205]/256;
   green = [0, 200,  70]/256;
   black = [0, 0, 0];
   white = 0.99*[1, 1, 1];


   N=500;  % number of points (don't make it big, code will be slow)

   a = 1.6; b = 1;
   Lx1 = -5; Lx2 = 30; Ly1 = -b; Ly2 = b;

   bd = 0.2;
   figure(1); clf; 
   hold on; axis equal; grid on;
   set(gca, 'fontsize', fs, 'linewidth', lw/4);
   
% Set up the plotting window
   figure(2); clf; hold on; axis equal; 
   
   [X, Y]=meshgrid(linspace(Lx1, Lx2, N), linspace(Ly1, Ly2, N));  
   x = X+eps; y = Y+eps;
   
   Z = x+sqrt(b^2-y.^2)- a*log((b+sqrt(b^2-y.^2))./y);
	  
%  graph the curves using 'contour' in figure (2)
   figure(2); [c, stuff] = contour(X, Y, Z, [0, 0]);
   
%  extract the curves from c and graph them in figure(1) using 'plot'
%  need to do this kind of convoluted work since plot2svg can't save
%  the result of 'contour' but can save the result of 'plot'   
   
   
   [m, n] = size(c);
   while n > 0
	  
	  l=c(2, 1);
	  x=c(1,2:(l+1));  y=c(2,2:(l+1)); % get x and y of contours
	  figure(1); plot(x, y, 'color', red, 'linewidth', lw/2);
	  
	  c = c(:, (l+2):n);
	  [m, n] = size(c);
	  
%		 Lx1 = min(Lx1, min(x) - bd); Lx2 = max(Lx2, max(x) + bd);
%		 Ly1 = min(Ly1, min(y) - bd); Ly2 = max(Ly2, max(y) + bd);
	  Lx1 = min(x) - bd; Lx2 = max(x) + bd;
	  Ly1 = min(y) - bd; Ly2 = max(y) + bd;
   end
   
   
   figure(1); axis equal; axis([Lx1 Lx2 -b-bd b+bd]);
   
   saveas(gcf, sprintf('Syntractrix_a=%0.2g_b=%0.2g.eps', a, b), 'psc2')
   
   