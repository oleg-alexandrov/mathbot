function discontinuity() % graph a function which has discontinuity

%  set up the plotting window, and some graphing paramenters
   figure(2); clf; hold on; axis equal; axis off;
   thick_line=2.5; thin_line=2; arrow_size=0.4; arrow_type=1; arrow_angle=20; %(angle in degrees)
   font_size=30; ball_rad=0.06;
   black=[0, 0, 0]; red=[1, 0, 0];

%  define the function; plot the x and y axes and the function
   a=-1.5; b=3; h=0.02; x0=1;
   X1=a:h:x0; X2=x0:h:b; X=[X1 X2];
   Y1=X1.^2; Y2=2-(X2-x0).^2; Y=[Y1 Y2]; y01=Y1(length(Y1)); y02=Y2(1);
   arrow([a 0],       [b, 0],      thin_line, arrow_size, arrow_angle, arrow_type, black)  
   arrow([0, min(Y)], [0, max(Y)], thin_line, arrow_size, arrow_angle, arrow_type, black); 
   plot(X1, Y1, 'linewidth', thick_line); plot(X2, Y2, 'linewidth', thick_line)

%  graph some suggestive balls
   ball_full (x0, 0, ball_rad, [0 0 0 ]); 
   ball_empty(x0, y01, thick_line, ball_rad, red);
   ball_empty(x0, y02, thick_line, ball_rad, red); 

%   text, sir
   H=text(x0, -0.006*font_size,  'x_0');
   set(H, 'fontsize', font_size, 'HorizontalAlignment', 'c', 'VerticalAlignment', 'c')

%  save to postscript
   saveas(gcf, 'Discontinuity_jump.eps', 'psc2')
   
function ball_full(x, y, r, color)
   Theta=0:0.1:2*pi;
   X=r*cos(Theta)+x;
   Y=r*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', 'none');


function ball_empty(x, y, thick_line, r, color)
   Theta=0:0.1:2*pi;
   X=r*cos(Theta)+x;
   Y=r*sin(Theta)+y;
   H=fill(X, Y, [1 1 1]);
   plot(X, Y, 'color', color, 'linewidth', thick_line);


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
