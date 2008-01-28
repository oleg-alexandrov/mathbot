% illustrate the analytic continuation along a curve
function main()

   lw=2;  % line width
   fs=20; % font size 
   h=1/100;
   tinyrad = 0.04;
   red = [1, 0, 0];
   
   figure(1); clf; hold on; axis equal; axis off;

   % generate the curve on which the analytic continuation will take place
   XX=[-0.1, 0.3, 0.4 0.28 0.0]; YY=1.4*[0, 1, 1.5 2 2.8];
   Y=YY(1):h:YY(length(YY)); X=spline(YY, XX, Y);
   N = length(X);

   % plot the circles of analytic continuation
   rad=0.8;
   spacing = 1; gap = spacing/h;
   k=1;
   while k <= N
	  plot_circle(X(k), Y(k), rad, lw);
	  k = k+gap;
   end
   plot_circle(X(N), Y(N), rad, lw);

   % plot the curve
   plot(X, Y, 'color', red, 'linewidth', lw);

   % plot the text
   tiny=0.003*fs;
   plot_text(X(1), Y(1), -2*tiny, -3.5*tiny, '\gamma(0)', fs, tinyrad, red);
   t=0.5; k=floor(N*t);
   plot_text(X(k), Y(k), tiny, tiny, '\gamma(\it{t})', fs, tinyrad, red);
   plot_text(X(N), Y(N), -4*tiny, 4.5*tiny, '\gamma(1)', fs, tinyrad, red);


   % plot arrows showing the direction along the curve
   thickness = lw;
   arrow_size = 0.27;
   sharpness=25;
   arrow_type=1;
   t= 0.2; s=0.1; k = floor(N*t); l = floor(N*(t+s));
   arrow([X(k), Y(k)], [X(l), Y(l)], thickness, arrow_size, sharpness, arrow_type, red)
   t= 0.8; s=0.1; k = floor(N*t); l = floor(N*(t+s));
   arrow([X(k), Y(k)], [X(l), Y(l)], thickness, arrow_size, sharpness, arrow_type, red)
   
   % plot a phony box around the graph to avoid a bug in matlab
   % with truncating around the edges when exporting to eps
   white=0.99*[1 1 1]; factor=1.1;
   plot(X(1)-factor*rad, Y(1)-factor*rad, '*', 'color', white);
   plot(X(N)+factor*rad, Y(N)+factor*rad, '*', 'color', white);
   saveas(gcf, 'analytic_continuation_along_a_curve.eps', 'psc2');
   
function plot_circle(x, y, r, lw)

   N=100;
   Theta=0:(1/N):2.1*pi;
   X=r*cos(Theta);
   Y=r*sin(Theta);

   plot(x+X, y+Y, 'linewidth', lw);

function plot_text(x, y, shiftx, shifty, str, fs, tinyrad, color)
   text(x+shiftx, y+shifty, str, 'fontsize', fs);
   ball(x, y, tinyrad, color);
      
function ball(x, y, r, color)
   Theta=0:0.1:2*pi;
   X=r*cos(Theta)+x;
   Y=r*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', 'none');

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