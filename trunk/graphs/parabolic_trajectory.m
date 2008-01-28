% illustration of a parabolic trajectory

function main()

   L=0.8;
   s=0.1;
   q=-0.4;
   N=100;

   arrow_size = 0.1;
   sharpness = 20;
   arrow_type = 1; 
   arrlen = 0.3; % arrow length
   tiny = 0.01;

   ball_radius = 0.05;
   
   X=linspace(-L, L, N);
   Y =L^2 - X.^2;

   Xl = linspace(-L-s, L+s, N);
   
   
% KSmrq's colors
   red    = [0.867 0.06 0.14];
   blue   = [0, 129, 205]/256;
   green  = [0, 200,  70]/256;
   yellow = [254, 194,   0]/256;
   white = 0.99*[1, 1, 1];
   black = [0, 0, 0];
   gray = 0.5*white;
   lw = 2.3;
   

   figure(1); clf; hold on; axis equal; axis off;

   plot(X, Y, 'linewidth', lw, 'linestyle', '--', 'color', blue);

   arrow([q-tiny, L^2-q^2], [q+arrlen-tiny, L^2-q^2-2*q*arrlen], lw, arrow_size, sharpness, arrow_type, red);
      
   ball(q, L^2 - q^2, ball_radius, gray)


   plot(Xl, 0*Xl, 'linewidth', 2*lw, 'color', black);

   
%saveas(gcf, 'Parabolic_trajectory.eps', 'psc2')
plot2svg('Parabolic_trajectory.svg');

function ball(x, y, radius, color) % draw a ball of given uniform color 
   Theta=0:0.1:2*pi;
   X=radius*cos(Theta)+x;
   Y=radius*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', [0, 0, 0]);

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
