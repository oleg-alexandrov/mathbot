% Illustration of approximating the Dirac delta function with gaussians.
 
function main()
 
   % KSmrq's colors
   red    = [0.867 0.06 0.14];
   blue   = [0, 129, 205]/256;
   green  = [0, 200,  70]/256;
   yellow = [254, 194,   0]/256;
   white = 0.99*[1, 1, 1];
   gray = 0.5*[1, 1, 1];
   black = [0, 0, 0];
   
  % Set up the grid and other parameters
   N = 300;
   A = 0.2; B = 2.8+A; 
   C=-1; D = 3;
 
   X = linspace(A, B, N);

   s = 1.4 + A;

   Y = (X-s).^3 - (X - s);
   Y = (Y-min(Y))/(max(Y)-min(Y))*(D-C)+C;
   
   lw = 3.4; % linewidth
   fs = 28; % font size

   smallrad = 0.07;
   
   numP = 15;

   for p=1:numP

      t = (p-1)/(numP-1);
      x = A+t*(B-A);
      y = interp1(X, Y, x);
      
      
      figure(1); clf; 
 
      set(gca, 'fontsize', fs);
      set(gca, 'linewidth', 0.4*lw)
      hold on;

      shifty1 = 1.2*smallrad;
      shifty2 = 0.5;
      
      plot_axes (-0.4, B+0.1, C-shifty1, D + shifty2, lw/1.5, fs, gray);
      axis([A-0.5, B, C-shifty1, D + shifty2]);
      
      plot([0, x], [y, y], 'linewidth', lw/2, 'linestyle', '--', 'color', gray);
      
      plot(X, Y, 'color', blue, 'linewidth', lw);

      ball(x, y, smallrad, green);
      ball(0, y, smallrad, red);
      
      axis equal; axis off;
       
      % save to disk
      file = sprintf('Frame%d.eps', 1000+p);
      disp(file);
      saveas(gcf, file, 'psc2')

      pause(0.1);
 
   end
   
 % Converted to gif with the command
 % convert -antialias -loop 10000  -delay 20 -scale 65% -compress LZW Frame10* Total_variation.gif
 
function plot_axes (A, B, C, D, lw, fs, color)
 
   arrow_size = 0.3;
   sharpness = pi/7;
   arrow_type = 1;
   arrow([A, 0], [B, 0], lw, arrow_size, sharpness, arrow_type, color);
   arrow([0, C], [0, D], lw, arrow_size, sharpness, arrow_type, color);

   small = 0.4;
   text(B-0.5*small, -0.7*small, 'x', 'fontsize', fs);
   text(-small, D - 0.3*small, 'y', 'fontsize', fs);

function arrow(start, stop, thickness, arrow_size, sharpness, arrow_type, color)

% Function arguments:
% start, stop:  start and end coordinates of arrow, vectors of size 2
% thickness:    thickness of arrow stick
% arrow_size:   the size of the two sides of the angle in this picture ->
% sharpness:    angle between the arrow stick and arrow side, in radians
% arrow_type:   1 for filled arrow, otherwise the arrow will be just two segments
% color:        arrow color, a vector of length three with values in [0, 1]

% convert to complex numbers
   i=sqrt(-1);
   start=start(1)+i*start(2); stop=stop(1)+i*stop(2);
   rotate_angle=exp(i*sharpness);

% points making up the arrow tip (besides the "stop" point)
   point1 = stop - (arrow_size*rotate_angle)*(stop-start)/abs(stop-start);
   point2 = stop - (arrow_size/rotate_angle)*(stop-start)/abs(stop-start);

   if arrow_type==1 % filled arrow

      % plot the stick, but not till the end, looks bad
      t=0.5*arrow_size*cos(sharpness)/abs(stop-start); stop1=t*start+(1-t)*stop;
      plot(real([start, stop1]), imag([start, stop1]), 'LineWidth', thickness, 'Color', color);

      % fill the arrow
      H=fill(real([stop, point1, point2]), imag([stop, point1, point2]), color);
      set(H, 'EdgeColor', 'none')

   else % two-segment arrow
      plot(real([start, stop]), imag([start, stop]),   'LineWidth', thickness, 'Color', color);
      plot(real([stop, point1]), imag([stop, point1]), 'LineWidth', thickness, 'Color', color);
      plot(real([stop, point2]), imag([stop, point2]), 'LineWidth', thickness, 'Color', color);
   end

function ball(x, y, radius, color) % draw a ball of given uniform color 
   Theta=0:0.1:2*pi;
   X=radius*cos(Theta)+x;
   Y=radius*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', color);
