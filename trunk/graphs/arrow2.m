function main()

% This MATLAB code demonstates matlab commands for drawing math graphs
   
   clf; hold on; % clean the screen and hold
   axis equal;   % same scale on both axes

   % some parameters
   thick_line=2; thin_line=1; font_size=20;
   arrow_size=0.1; arrow_type=1; red=[1, 0, 0]; sharpness=45; % arrow specs
   red=[1, 0, 0]; green=[0, 1, 0]; blue=[0, 0, 1]; whiteish=0.99*[1, 1, 1];

   
   start=[0, 0]; stop=[1, 0];
   
   

   arrow(start, stop, thick_line, arrow_size, sharpness, arrow_type, red)

%%%%%% Done!!!! Below are the ball and arrow routines. %%%%%%%
   
function full_ball  (x, y, rad, color)
   Theta=0:0.1:2*pi;
   X=rad*cos(Theta)+x;
   Y=rad*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', 'none');

function empty_ball (x, y, thick_line, rad, color)
   Theta=0:0.1:2*pi;
   X=rad*cos(Theta)+x;
   Y=rad*sin(Theta)+y;
   H=fill(X, Y, [1 1 1]); % fill in with white
   plot(X, Y, 'color', color, 'linewidth', thick_line); % draw a circle
   
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
   