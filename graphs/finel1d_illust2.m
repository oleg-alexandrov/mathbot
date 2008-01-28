function main () % draw an illustration for finite element method

% prepare the scrreen and define some parameters   
clf; hold on; axis equal; axis off; 
fontsize=30; thick_line=3; thin_line=2; black=[0, 0, 0]; red=[1, 0, 0]; blue=[0, 0, 1];
arrowsize=0.1; arrow_type=1; arrow_angle=20; % (angle in degrees)
circrad=0.01; % radius of ball showing up in places

a=0; b=1; % interval endpoints
X=a:0.01:b; f=inline('2*x.*(1-x).^1.1'); Y=f(X); % the function
h=0.2; Xh=a:h:b; Yh=f(Xh);  % the linear approximation

% x and y axes
arrow([a-0.2 0], [b+0.2, 0], thin_line, arrowsize, arrow_angle, arrow_type, black) 
arrow([-0.15 -0.05], [-0.15, 1.5*max(Y)], thin_line, arrowsize, arrow_angle, arrow_type, black) 

% plot the graphs
plot(Xh, Yh, 'linewidth', thick_line, 'color', red)

%% place some dashed lines
height=0.6;
for i=2:(length(Xh)-1)
   plot([Xh(i) Xh(i)], [0, height], 'linewidth', thin_line, 'linestyle', '--', 'color', 'black');   
end

%% plot the basis functions
for i=2:(length(Xh)-1)
   plot([Xh(i-1) Xh(i) Xh(i+1)], [0, height 0], 'linewidth', thick_line, 'color', blue);   
end


% some balls for beauty
ball(a, 0, circrad, black);
ball(b, 0, circrad, black);
for i=2:(length(Xh)-1)
   ball(Xh(i), 0, circrad, black);
end

%% place text 
tiny=0.07; 
H=text(a+0.05, -tiny,  'x_0=0'); set(H, 'fontsize', fontsize, 'HorizontalAlignment', 'r', 'VerticalAlignment', 'top');
H=text(b-0.05, -tiny,  'x_5=1'); set(H, 'fontsize', fontsize, 'HorizontalAlignment', 'l', 'VerticalAlignment', 'top');
for i=2:(length(Xh)-1)
   H=text(Xh(i), -tiny,  sprintf('x_%d', i-1));
   set(H, 'fontsize', fontsize, 'HorizontalAlignment', 'c', 'VerticalAlignment', 'top');
end

saveas(gcf, 'Finite_element_method_1D_illustration2.eps', 'psc2') % export to eps

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
   