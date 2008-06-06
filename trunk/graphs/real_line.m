function main()

   figure(1); clf; hold on; axis equal; axis off;
   
   Lx = [0.004, 0.004, 0.001];
   Ly = [0.25, 0.1,  0.05];
   S  = [1, 0.1, 0.01];
   
   a = 1.95;
   b = 4.2;
   thickness = 0.01;
   
   black = [0, 0, 0];
   
   plot_rectagle((a+b)/2, b-a, thickness, black)

   for i=1:length(S)

	  i
	  A = S(i)*ceil(a/S(i));
	  X = A:S(i):b;

	  for j=1:length(X)
		 plot_rectagle(X(j), Lx(i), Ly(i), black)
	  end
	  
   end
   

   saveas(gcf, 'Real_line_ruler.eps', 'psc2')
   
function plot_rectagle(x0, Lx, Ly, color)
% plot a rectange with given width and height
% given the x coordinate of the midpoint of the upper edge
% (the y coordiante is zero)

   u = x0-Lx/2; v = x0+Lx/2;
   X = [u, v, v, u, u];

   Y = [0, 0, -Ly, -Ly, 0];

   fill(X, Y, color);
   
   

