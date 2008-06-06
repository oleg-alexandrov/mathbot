% Illustration of an [[:en:Non-analytic smooth function|non-analytic smooth function]]
function main()

   thickness1=2.5; thickness2=1.5; arrowsize=0.15; arrow_type=1; ball_rad=0.03; arrow_angle=35;
   blue = [0, 129, 205]/256; black=[0 0 0]; fontsize=floor(20); dist=0.01;
   
   a=-1; b=5;
   h=0.01;
   X=a:h:b;
   Y=zeros(length(X), 1);
   for i=1:length(X)
      x=X(i);
      if x <= 0
	 Y(i)=0;
      else 
         Y(i)=exp(-1/x);
      end
   end

   
   figure(1);  clf; hold on; axis equal; axis off

   arrow([a 0], [b+0.2, 0], thickness2, arrowsize, arrow_angle, arrow_type, [0, 0, 0])
   arrow([0 -0.3], [0 2.*max(Y)], thickness2, arrowsize, arrow_angle, arrow_type, [0, 0, 0])
   plot(X, Y, 'linewidth', thickness1, 'color', blue);
   plot(X, 0*Y+1, 'linewidth', thickness2/1.5, 'color', black, 'linestyle', '--');
   arrow([b+0.1 0], [b+0.2, 0], thickness2, arrowsize, arrow_angle, arrow_type, [0, 0, 0])
   
   ball(0, 0, ball_rad, blue); place_text_smartly(0, fontsize, 5, dist, '0');
   ball(0, 1, ball_rad, black); place_text_smartly(sqrt(-1), fontsize, 5, dist, '1');

saveas(gcf, 'Non-analytic_smooth_function.eps', 'psc2')

function place_text_smartly (z, fs, pos, d, tx)
 p=cos(pi/4)+sqrt(-1)*sin(pi/4);
 z = z + p^pos * d * fs; 
 shiftx=0.0003;
 shifty=0.002;
 x = real (z); y=imag(z); 
 H=text(x+shiftx*fs, y+shifty*fs, tx); set(H, 'fontsize', fs, 'HorizontalAlignment', 'c', 'VerticalAlignment', 'c')


function ball(x, y, r, color)
   Theta=0:0.1:2*pi;
   X=r*cos(Theta)+x;
   Y=r*sin(Theta)+y;
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