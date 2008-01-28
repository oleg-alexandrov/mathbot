% Illustration of the bernoulli inequality

function main()

   r = 3; % the power in the Bernoulli inequality
   
   % KSmrq's colors
   red    = [0.867 0.06 0.14];
   blue   = [0, 129, 205]/256;
   green  = [0, 200,  70]/256;
   yellow = [254, 194,   0]/256;
   white = 0.99*[1, 1, 1];

% Set up the grid and other parameters
   N = 100;
   A = -2; B = 2; 
   X = linspace(A, B, N);
   Y1 = 1+r*X;
   Y2 = (1+X).^r;

   C=-4; D = 4;
   
   % Set up the figure
   lw = 3; % linewidth
   fs = 12; % font size
   figure(1); clf;

   set(gca, 'fontsize', fs);
   set(gca, 'linewidth', 0.6*lw)
   hold on;% grid on;
   
   plot_axes (A, B, C, D, lw/1.3);
   
   plot(X, Y1, 'color', blue, 'linewidth', lw);
   plot(X, Y2,   'color', red, 'linewidth', lw);
   
   axis equal; axis([A, B, C, D]); 

   saveas(gcf, 'Bernoulli_inequality.eps'); % save as eps
   plot2svg('Bernoulli_inequality.svg'); % save as svg
   
function plot_axes (A, B, C, D, lw)
   
   black = [0, 0, 0];

   plot([A B], [0, 0], 'linewidth', lw, 'color', black);
   plot([0, 0], [C, D], 'linewidth', lw, 'color', black);
   