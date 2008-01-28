function main()

%   Illustration of the Mittag-Leffler star
   
   lw=3.5;
   lightblue = [0.8 0.8 1];
   red=[0.867 0.06 0.14];
   blue = [0, 129, 205]/256;
   green = [0, 146,  70]/256;
   white=0.99*[1, 1, 1];
   
   figure(2); clf; hold on; axis equal; axis off;

%  plot central circle and its center
   O=[0, 0]; 
   radius=0.32; 
   plot_circle(O(1), O(2), radius, lw, red);
   tinyrad = 0.013;
   ball(O(1), O(2), tinyrad, red);

%  draw a spline-interpolated curve
   XX=[0.0543 -0.4058 -0.8211 -0.5463 -0.1310  0.1821  0.5847  0.2907];
   YY=[0.7796  0.3578  0.1661 -0.1597 -0.5495 -0.2748 -0.1278  0.3323];
   N=100; % how fine to make the interpolation
   [X, Y] = get_spline(N, XX, YY);
   plot(X, Y, 'LineWidth', lw, 'color', blue);

%  text
   fontsize = 35;
   tiny=0.0022*fontsize;
   text(O(1)-tiny, O(2)-tiny, '\it{a}', 'fontsize', fontsize);

%   plot a box around the figure to avoid bugs with saving to eps
   offset=0.04;
   plot(min(X)-offset, min(Y)-offset, '*', 'color', white)
   plot(max(X)+offset, max(Y)+offset, '*', 'color', white)

   saveas(gcf, 'ML_expansion_illustration.eps', 'psc2')
%  to later convert from eps to png use
   
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