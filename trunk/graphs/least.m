% Illustration of linear least squares.
function main()
   
   % KSmrq's colors
   red    = [0.867 0.06 0.14];
   blue   = [0, 129, 205]/256;
   green  = [0, 200,  70]/256;
   yellow = [254, 194,   0]/256;
   white = 0.99*[1, 1, 1];
   gray = 0.3*white;
   
% Set up the grid and other parameters
   N = 100;
   A = -2.2; B = 2; 
   X = linspace(A, B, N);

   C=-4; D = 4;
   
   % Set up the figure
   lw = 4; % linewidth
   fs = 26; % font size
   figure(1); clf; hold on;

   set(gca, 'fontsize', fs);
   set(gca, 'linewidth', lw/2)
   hold on; grid on;

   a = 1.2; b = 3; c = 1.4;
   M = 50;
   XX=linspace(A+0.3, B-0.3, M+1);
   Xr = 0*(1:M);
   Yr = Xr;
   for i=1:M
      r=rand(1);
      Xr(i) = XX(i)*r+XX(i+1)*(1-r);
      Yr(i) = a*Xr(i) + b + c*rand(1);
   end

   myrad = 0.05;
   for i=1:length(Xr)
      ball(Xr(i), Yr(i), myrad, red);
   end

   Yr = Yr';
   Mat = [Xr' (0*Xr+1)'];
   
   V=Mat'*Yr;
   V=(Mat'*Mat)\V;

   ae = V(1); be = V(2);
   
   plot(X, ae*X+be, 'b', 'linewidth', lw);
   
%   
   axis equal; %axis([A, B, C, D]); 
%
%   set(gca, 'XTick', [-2, -1, 0, 1, 2]) % text labels on the x axis
   grid on;
   set(gca, 'GridLineStyle', '-', 'xcolor', gray);
   set(gca, 'GridLineStyle', '-', 'ycolor', gray);
   set(gca, 'XTick', [-2 -1 0 1 2 3]);
   set(gca, 'YTick', [1 2 3 4 5 6]);
   
   s = 0.1;
   mnx = min(Xr); mxx = max(Xr);
   mny = min(Yr); mxy = max(Yr);

   axis equal;
   axis([-2, 2, 1, 6]);
   
   saveas(gcf, 'Linear_least_squares.eps', 'psc2'); % save as eps
   %plot2svg('Linear_least_squares.svg'); % save as svg

   
function ball(x, y, r, color)
   Theta=0:0.1:2*pi;
   X=r*cos(Theta)+x;
   Y=r*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', 'none');
