% Illustration of approximating the Dirac delta function with gaussians.

function main()

   r = 3; % the power in the Bernoulli inequality
   
   % KSmrq's colors
   red    = [0.867 0.06 0.14];
   blue   = [0, 129, 205]/256;
   green  = [0, 200,  70]/256;
   yellow = [254, 194,   0]/256;
   white = 0.99*[1, 1, 1];

  % Set up the grid and other parameters
   N = 300;
   A = -2; B = 2; 
   C=-1; D = 6;

   X = linspace(A, B, N);
   
   % Set up the figure
   lw = 3; % linewidth
   fs = 18; % font size

   for p=1:10

      a=1/p;

      % gaussian
      Y=(1/(a*sqrt(pi)))*exp(-X.^2/a^2);

      figure(1); clf; 

      set(gca, 'fontsize', fs);
      set(gca, 'linewidth', 0.4*lw)
      hold on;
      
      plot_axes (A, B, C, D, lw/1.5);
      
      plot(X, Y, 'color', blue, 'linewidth', lw);
      
      axis equal; axis([A, B, C, D]); 
      
      set(gca, 'XTick', [-2, -1, 0, 1, 2]) % text labels on the x axis
      grid on;
      
      H=text(B-1.5, D-0.5, sprintf('a=1/%d', p), 'fontsize', fs);

      % save to disk
      file = sprintf('Frame%d.eps', 1000+p);
      disp(file);
      saveas(gcf, file, 'psc2')
      
      pause(0.1);

   end

 % Converted to gif with the command
 % convert -antialias -density 100 -delay 20 -loop 10000 Frame10* Dirac_function_approximation.gif
 % then scaled in Gimp   
   
function plot_axes (A, B, C, D, lw)
   
   gray = 0.5*[1, 1, 1];
   
   plot([A B], [0, 0], 'linewidth', lw, 'color', gray);
   plot([0, 0], [C, D], 'linewidth', lw, 'color', gray);
   