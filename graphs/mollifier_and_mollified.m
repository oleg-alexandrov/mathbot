function main() 
   thickness1=2.5; thickness2=1.5; arrowsize=8; arrow_type=2; ball_rad=0.005;
   blue=[0, 0, 1]; fontsize=30; dist=0.002;

   figure(1); clf;
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   subplot(2, 1, 1); hold on; axis equal; axis off;
   
   a=-1.4; b=1.4; epsilon=0.25;
   h=0.005; X=a:h:b; m=length(X); m = 2*floor(m/2); X=linspace(a, b, m);

   Y=get_mollifier(X, epsilon);
   Y=Y/sum(Y);

   scale=55;
   arrow([a 0], [b+0.2, 0], thickness2, arrowsize, pi/8,arrow_type, [0, 0, 0])
   arrow([0 -0.3], [0 1.3*scale*max(Y)], thickness2, arrowsize, pi/8,arrow_type, [0, 0, 0])
   plot(X, scale*Y, 'linewidth', thickness1, 'color', [0 0 1]);
   arrow([b+0.1 0], [b+0.2, 0], thickness2, arrowsize, pi/8,arrow_type, [0, 0, 0])

   place_text_smartly(1.*epsilon, fontsize, 6, dist, '\epsilon');
   place_text_smartly(-1.2*epsilon, fontsize, 6, dist, '-\epsilon');

   m=length(X);
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   subplot(2, 1, 2); hold on; axis equal; axis off;
   a=-1.9; b=2.3;
   X=a:h:b;
   mm=length(X);
   for i=1:length(X)
      x=X(i);
      if x < -0.7;
	 Z(i)=x+1.2;
      elseif  x<1
	 Z(i) = x^2;
      else
	 Z(i)=1.5-x;
      end
   end
   
   q=40;  arrowsize=10;
   arrow([a 0], [b+0.1, 0], thickness2, arrowsize, pi/8,arrow_type, [0, 0, 0])
   arrow([0 -0.2], [0 1.1*max(Z)], thickness2, arrowsize, pi/8,arrow_type, [0, 0, 0]);
   plot(X(q:(mm-q)), Z(q:(mm-q)), 'linewidth', thickness1, 'color', [1 0 0]);
   arrow([b 0], [b+0.1, 0], thickness2, arrowsize, pi/8,arrow_type, [0, 0, 0])
   
   W=conv(Y, Z)*(b-a)*0.239;
   p=floor(m/2); w=length(W);
   W=W(p:(w-p-1));
   length(W)
   length(X)
%   plot(X, W, 'linewidth', thickness1, 'color', [0 0 1]);
   plot(X(q:(mm-q-1)), W(q:(mm-q-1)), 'linewidth', thickness1, 'color', [0 0 1]);
% 
   
saveas(gcf, 'Mollified_illustration.eps', 'psc2')

function Y=get_mollifier(X, epsilon)
   Y=zeros(length(X), 1);
   for i=1:length(X)
      x=X(i);
      if x < epsilon & x > -epsilon
	 Y(i)=exp(-1/(1-x^2/epsilon^2));
      end
   end

function place_text_smartly (z, fs, pos, d, tx)
 p=cos(pi/4)+sqrt(-1)*sin(pi/4);
 z = z + p^pos * d * fs; 
 shiftx=0.0003;
 shifty=0.002;
 x = real (z); y=imag(z); 
 H=text(x+shiftx*fs, y+shifty*fs, tx); set(H, 'fontsize', fs, 'HorizontalAlignment', 'c', 'VerticalAlignment', 't')


function ball(x, y, r, color)
   Theta=0:0.1:2*pi;
   X=r*cos(Theta)+x;
   Y=r*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', color);



    function arrow(start, stop, thickness, arrowsize, sharpness, arrow_type, color)

   
%  draw a line with an arrow at the end
%  start is the x,y point where the line starts
%  stop is the x,y point where the line stops
%  thickness is an optional parameter giving the thickness of the lines   
%  arrowsize is an optional argument that will give the size of the arrow 
%  It is assumed that the axis limits are already set
%  0 < sharpness < pi/4 determines how sharp to make the arrow
%  arrow_type draws the arrow in different styles. Values are 0, 1, 2, 3.
   
%       8/4/93    Jeffery Faneuff
%       Copyright (c) 1988-93 by the MathWorks, Inc.
%       Modified by Oleg Alexandrov 2/16/03

   
   if nargin <=6
      color=[0, 0, 0];
   end
   
   if (nargin <=5)
      arrow_type=0;   % the default arrow, it looks like this: ->
   end
   
   if (nargin <=4)
      sharpness=pi/4; % the arrow sharpness - default = pi/4
   end

   if nargin<=3
      xl = get(gca,'xlim');
      yl = get(gca,'ylim');
      xd = xl(2)-xl(1);            
      yd = yl(2)-yl(1);            
      arrowsize = (xd + yd) / 2;   % this sets the default arrow size
   end

   if (nargin<=2)
      thickness=0.5; % default thickness
   end
   
   
   xdif = stop(1) - start(1);
   ydif = stop(2) - start(2);

   if (xdif == 0)
      if (ydif >0) 
	 theta=pi/2;
      else
	 theta=-pi/2;
      end
   else
      theta = atan(ydif/xdif);  % the angle has to point according to the slope
   end

   if(xdif>=0)
      arrowsize = -arrowsize;
   end

   if (arrow_type == 0) % draw the arrow like two sticks originating from its vertex
      xx = [start(1), stop(1),(stop(1)+0.02*arrowsize*cos(theta+sharpness)),NaN,stop(1),...
	    (stop(1)+0.02*arrowsize*cos(theta-sharpness))];
      yy = [start(2), stop(2), (stop(2)+0.02*arrowsize*sin(theta+sharpness)),NaN,stop(2),...
	    (stop(2)+0.02*arrowsize*sin(theta-sharpness))];
      plot(xx,yy, 'LineWidth', thickness, 'color', color)
   end

   if (arrow_type == 1)  % draw the arrow like an empty triangle
      xx = [stop(1),(stop(1)+0.02*arrowsize*cos(theta+sharpness)), ...
	    stop(1)+0.02*arrowsize*cos(theta-sharpness)];
      xx=[xx xx(1) xx(2)];
      
      yy = [stop(2),(stop(2)+0.02*arrowsize*sin(theta+sharpness)), ...
	    stop(2)+0.02*arrowsize*sin(theta-sharpness)];
      yy=[yy yy(1) yy(2)];

      plot(xx,yy, 'LineWidth', thickness, 'color', color)
      
%     plot the arrow stick
      plot([start(1) stop(1)+0.02*arrowsize*cos(theta)*cos(sharpness)], [start(2), stop(2)+ ...
		    0.02*arrowsize*sin(theta)*cos(sharpness)], 'LineWidth', thickness, 'color', color)
      
   end
   
   if (arrow_type==2) % draw the arrow like a full triangle
      xx = [stop(1),(stop(1)+0.02*arrowsize*cos(theta+sharpness)), ...
	    stop(1)+0.02*arrowsize*cos(theta-sharpness),stop(1)];
      
      yy = [stop(2),(stop(2)+0.02*arrowsize*sin(theta+sharpness)), ...
	    stop(2)+0.02*arrowsize*sin(theta-sharpness),stop(2)];
      
%     plot the arrow stick
      plot([start(1) stop(1)+0.01*arrowsize*cos(theta)], [start(2), stop(2)+ ...
		    0.01*arrowsize*sin(theta)], 'LineWidth', thickness, 'color', color)
      H=fill(xx, yy, color);% fill with black
      set(H, 'EdgeColor', 'none')

   end

   if (arrow_type==3) % draw the arrow like a filled 'curvilinear' triangle
      curvature=0.5; % change here to make the curved part more curved (or less curved)
      radius=0.02*arrowsize*max(curvature, tan(sharpness));
      x1=stop(1)+0.02*arrowsize*cos(theta+sharpness);
      y1=stop(2)+0.02*arrowsize*sin(theta+sharpness);
      x2=stop(1)+0.02*arrowsize*cos(theta)*cos(sharpness);
      y2=stop(2)+0.02*arrowsize*sin(theta)*cos(sharpness);
      d1=sqrt((x1-x2)^2+(y1-y2)^2);
      d2=sqrt(radius^2-d1^2);
      d3=sqrt((stop(1)-x2)^2+(stop(2)-y2)^2);
      center(1)=stop(1)+(d2+d3)*cos(theta);
      center(2)=stop(2)+(d2+d3)*sin(theta);

      alpha=atan(d1/d2);
      Alpha=-alpha:0.05:alpha;
      xx=center(1)-radius*cos(Alpha+theta);
      yy=center(2)-radius*sin(Alpha+theta);
      xx=[xx stop(1) xx(1)];
      yy=[yy stop(2) yy(1)];


%     plot the arrow stick
      plot([start(1) center(1)-radius*cos(theta)], [start(2), center(2)- ...
		    radius*sin(theta)], 'LineWidth', thickness, 'color', color);

      H=fill(xx, yy, color);% fill with black
      set(H, 'EdgeColor', 'none')

   end
