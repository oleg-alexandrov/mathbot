function main()

%   Illustration of the Mittag-Leffler star
   
   lw=3.5;
   lightblue = [0.8 0.8 1];
   red=[0.867 0.06 0.14];
   blue = [0, 129, 205]/256;
   green = [0, 146,  70]/256;
   white=0.99*[1, 1, 1];
   
   % will draw a spline-interpolated curve through these points
   XX=[0.0543 -0.4058 -0.8211 -0.5463 -0.1310  0.1821  0.5847  0.2907];
   YY=[0.7796  0.3578  0.1661 -0.1597 -0.5495 -0.2748 -0.1278  0.3323];

   figure(2); clf; hold on; axis equal; axis off;
   N=100; % how fine to make the interpolation
   [X, Y] = get_spline(N, XX, YY);
   plot(X, Y, 'LineWidth', lw, 'color', blue);
   
%  the number of circles to plot and their radii
   P = 6; R=1:P; R=1.09-1./R.^1.3; R=[0  0.4 R(2:length(R))];
   M=length(R);

%  plot rays
   O=[0, 0]; 
   Angles=[1.0 2.34 6.1];
   for l=1:length(Angles)
	  m = floor(Angles(l)*N)+1;
	  E = [X(m), Y(m)];
   
	  plot([O(1), E(1)], [O(2), E(2)], 'linewidth', lw, 'color', green);
   end;
   
   % plot central circle and its center
   radius=0.2; 
   plot_circle(O(1), O(2), radius, lw, red);
   tinyrad = 0.013;
   ball(O(1), O(2), tinyrad, green);

   % plot circles along the rays
   for l=1:length(Angles)
	  m = floor(Angles(l)*N)+1;
	  E = [X(m), Y(m)];
   
	  e=norm(E);
	  for i=2:(M-1)
		 t=R(i);
		 radius=0.85*(R(i+1)-R(i))*e;
		 C=t*E;
		 plot_circle(C(1), C(2), radius, lw, red);
	  end
   end


%  text
   fontsize = 35;
   tiny=0.0022*fontsize;
   text(O(1)-0.6*tiny, O(2)-tiny, '\it{a}', 'fontsize', fontsize);

%   plot a box around the figure to avoid bugs with saving to eps
   offset=0.04;
   plot(min(X)-offset, min(Y)-offset, '*', 'color', white)
   plot(max(X)+offset, max(Y)+offset, '*', 'color', white)

   plot2svg('ML_star.svg')
   saveas(gcf, 'ML-star.eps', 'psc2')
%  to later convert from eps to png use
%  convert -antialias -density 250 ML-star.eps ML-star.png
   
function [xx, yy] = get_spline(N, x, y)
   
   n=length(x); 
   P=5; Q=n+2*P+1; % P will denote the amount of overlap
   
% Make the 'periodic' sequence xp=[x(1) x(2) x(3) ... x(n) x(1) x(2) x(3) ... ]
% of length Q. Same for yp.
   for i=1:Q
	  j=rem(i, n)+1; % rem() is the remainder of division of i by n
	  xp(i)=x(j);
	  yp(i)=y(j);
   end
   
% do the spline interpolation
   t=1:length(xp);
   tt=1:(1/N):length(xp);
   xx=spline(t, xp, tt);
   yy=spline(t, yp, tt);
   
% discard the reduntant pieces
   start=N*(P-1)+1;
   stop=N*(n+P-1)+1;
   xx=xx(start:stop); 
   yy=yy(start:stop);

% to avoid plotting artifacts, add one more entry to xx and yy
   for i=1:2*length(xx)
      xx(length(xx)+1)=xx(i);
      yy(length(yy)+1)=yy(i);
   end
   
function plot_circle(x, y, r, lw, color)

   Theta=0:0.1:2.1*pi;
   X=r*cos(Theta)+x;
   Y=r*sin(Theta)+y;
   plot(X, Y, 'linewidth', lw, 'color', color);

function ball(x, y, r, color)
   Theta=0:0.1:2.1*pi;
   X=r*cos(Theta)+x;
   Y=r*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', 'none');