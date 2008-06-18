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


   N=5000;  % number of points (don't make it big, code will be slow)

   a = 1.5; b = 1;
   Lx1 = -0.3; Lx2 = 5; Ly1 = -b; Ly2 = b;

   bd = 0.1;
   figure(1); clf; 
   hold on; axis equal; grid on;
   set(gca, 'fontsize', fs, 'linewidth', lw/4);
   
   Y = linspace(eps, Ly2, N);  
   X =  -sqrt(b^2-Y.^2) + a*log((b+sqrt(b^2-Y.^2))./Y);
   X(1) = Lx2;
   
   figure(1); plot(X, Y, 'color', red, 'linewidth', lw/2);
          
   figure(1); axis equal; axis([Lx1-bd Lx2 -bd b+bd]);
   
   saveas(gcf, sprintf('Syntractrix_a=%0.2g_b=%0.2g.eps', a, b), 'psc2')
         
