% Illustration of a biholomorphim, in this case w=exp(z)

function main()

   N = 15; % num of grid points
   epsilon = 0.1; % displacement for each small diffeomorphism
   num_comp = 10; % number of times the diffeomorphism is composed with itself
 
   Sx = linspace(-1, 1, N);
   Sy = linspace(0, pi/2, N);

   [X, Y] = meshgrid(Sx, Sy);

   % graphing settings
   lw = 3.5;

   % KSmrq's colors
   blue   = [0, 129, 205]/256;
   green  = [0, 200,  70]/256;
   yellow = [254, 194,   0]/256;
   white = 0.99*[1, 1, 1];

   mycolor = blue;
   
   % start plotting
   figno=1; figure(figno); clf;

   A=-1.1; B=1.2; C=-0.1; D=1.8;
   do_plot(X, Y, lw, figno, mycolor, A, B, C, D)
   saveas(gcf, 'Biholom1.eps', 'psc2');
   
   I=sqrt(-1);
   Z = X+I*Y;

   F=exp(Z);
   
   XF = real(F); YF=imag(F);

   figno = 2;
   A=-0.1; B=3.0; C=A; D=B;
   do_plot(XF, YF, lw, figno, mycolor, A, B, C, D)

   saveas(gcf, 'Biholom2.eps', 'psc2');
   
   
function do_plot(X, Y, lw, figno, mycolor, A, B, C, D)
   figure(figno); clf; hold on;
   axis equal; axis off;

   
%   plot([A B], [0, 0], 'linewidth', lw, 'color', black);
%   plot([0, 0], [C, D], 'linewidth', lw, 'color', black);

   [M, N] = size(X);

   for i=1:N
      plot(X(:, i), Y(:, i), 'linewidth', lw, 'color', mycolor);
      plot(X(i, :), Y(i, :), 'linewidth', lw, 'color', mycolor);
   end
   
   red    = [0.867 0.06 0.14];
   gray = 0.2*[1, 1, 1];

   arrow_size = 0.07*max(B, D);
   sharpness = 20;
   arrow_type = 1; 
   arrlen = 0.3; % arrow length
   tiny = 0.01;
   scale = 0.8;
   
   arrow([A, 0], [B, 0], scale*lw, arrow_size, sharpness, arrow_type, gray);
   arrow([0, C], [0, D], scale*lw, arrow_size, sharpness, arrow_type, gray);


   fs = 10*max(B, D);
   myrad = 0.009*max(B, D);
      
   minX = min(min(X)); 
   maxX = max(max(X));

   % in the two pictures, the text to be displayed is different
   if maxX ~= exp(1)

      smallx = -0.03*max(B, D);
      smally = -0.12*max(B, D);

      text (minX+smallx, smally, sprintf('%d', minX), 'fontsize', fs, 'color', gray);
      text (maxX+smallx, smally, sprintf('%d', maxX), 'fontsize', fs, 'color', gray);

%      ball(minX, 0, myrad, mycolor);
%      ball(maxX, 0, myrad, mycolor);
%      ball(0, 0, myrad, mycolor);

   else
      smallx = -0.01*max(B, D);
      smally = -0.12*max(B, D);
      
      text (minX+smallx, smally, 'e^{-1}', 'fontsize', fs, 'color', gray);
      text (maxX+smallx, smally, 'e', 'fontsize', fs, 'color', gray);

      
%      ball(exp(-1), 0, myrad, mycolor);
%      ball(maxX, 0, myrad, mycolor);

   end
   
function ball(x, y, radius, color) % draw a ball of given uniform color 
   Theta=0:0.1:2*pi;
   X=radius*cos(Theta)+x;
   Y=radius*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', color);


function arrow(start, stop, thickness, arrow_size, sharpness, arrow_type, color)
 
% Function arguments:
% start, stop:  start and end coordinates of arrow, vectors of size 2
% thickness:    thickness of arrow stick
% arrow_size:   the size of the two sides of the angle in this picture ->
% sharpness:    angle between the arrow stick and arrow side, in degrees
% arrow_type:   1 for filled arrow, otherwise the arrow will be just two segments
% color:        arrow color, a vector of length three with values in [0, 1]
 
% convert to complex numbers
   i=sqrt(-1);
   start=start(1)+i*start(2); stop=stop(1)+i*stop(2);
   rotate_angle=exp(i*pi*sharpness/180);
 
% points making up the arrow tip (besides the "stop" point)
   point1 = stop - (arrow_size*rotate_angle)*(stop-start)/abs(stop-start);
   point2 = stop - (arrow_size/rotate_angle)*(stop-start)/abs(stop-start);
 
   if arrow_type==1 % filled arrow
 
      % plot the stick, but not till the end, looks bad
      t=0.5*arrow_size*cos(pi*sharpness/180)/abs(stop-start); stop1=t*start+(1-t)*stop;
      plot(real([start, stop1]), imag([start, stop1]), 'LineWidth', thickness, 'Color', color);
 
      % fill the arrow
      H=fill(real([stop, point1, point2]), imag([stop, point1, point2]), color);
      set(H, 'EdgeColor', 'none')
 
   else % two-segment arrow
      plot(real([start, stop]), imag([start, stop]),   'LineWidth', thickness, 'Color', color); 
      plot(real([stop, point1]), imag([stop, point1]), 'LineWidth', thickness, 'Color', color);
      plot(real([stop, point2]), imag([stop, point2]), 'LineWidth', thickness, 'Color', color);
   end