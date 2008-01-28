% Compute a diffeomorphism from a square to a square which leave
% the boundary fixed.

function main()

   N = 15; % num of grid points
   epsilon = 0.1; % displacement for each small diffeomorphism
   num_comp = 10; % number of times the diffeomorphism is composed with itself
 
   S = linspace(-1, 1, N);

   [X, Y] = meshgrid(S);

   
   % graphing settings
   lw = 1.0;

   % KSmrq's colors
   red    = [0.867 0.06 0.14];
   blue   = [0, 129, 205]/256;
   green  = [0, 200,  70]/256;
   yellow = [254, 194,   0]/256;
   white = 0.99*[1, 1, 1];

   mycolor = blue;
   
   % start plotting
   figno=1; figure(figno); clf;

   shiftx = 0; shifty = 0; scale = 1;
   do_plot(X, Y, lw, figno, mycolor, shiftx, shifty, scale)

   I=sqrt(-1);
   Z = X+I*Y;

   % tweak these numbers for a pretty map
   z0 = 1+ 2*I;
   z1 = 0.1+ 0.2*I;
   z2 = 0.2+ 0.3*I;
   a = 0.01;
   b = 0.02;
   shiftx = 0.1; shifty = 1.2; scale = 1.4;
   F = (Z+z0).^2 +a*(Z+z1).^3 +b*(Z+z2).^4;
   F = (1+2*I)*F;
   
   XF = real(F); YF=imag(F);

   do_plot(XF, YF, lw, figno, mycolor, shiftx, shifty, scale)

   axis ([-1 1.3 -2 2]); axis off;

   saveas(gcf, 'Conformal_map.eps', 'psc2');
   
   
function do_plot(X, Y, lw, figno, mycolor, shiftx, shifty, scale)
   figure(figno); hold on;

   [M, N] = size(X);

   X = X - min(min(X));
   Y = Y - min(min(Y));

   a = max(max(max(abs(X))), max(max(abs(Y))));
   X = X/a; Y = Y/a;

   X = scale*(X-shiftx);
   Y = scale*(Y-shifty);
   
   for i=1:N
      plot(X(:, i), Y(:, i), 'linewidth', lw, 'color', mycolor);
      plot(X(i, :), Y(i, :), 'linewidth', lw, 'color', mycolor);
   end
%   axis([-1-small, 1+small, -1-small, 1+small]);
   axis equal; axis off;
   
