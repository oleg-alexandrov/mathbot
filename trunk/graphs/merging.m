function meging2()

   lw=2;
   levels=[0.7+eps, eps, -0.7+eps];
   for i=1:length(levels)
      plot_contours(levels(i), i, i, lw)
   end
   
function plot_contours(hh, count, fig,  lw)
   
   figure(fig);clf; hold on; axis equal; axis off;
   Lx=2;
   Ly=2;
   H=1;

   N=100;
   X=-Lx:(1/N):Lx;
   z=0.89*Lx;
   Z=0.7*(X-z).*X.^2.*(X+z);
   Z=-Z+hh;
   ZB=Z;
   height=2.5;
   x1=min(X); x2=max(X);

   XB=-(10*Lx):(1/N):(10*Lx);
   ZB=hh-0.7*(XB-z).*XB.^2.*(XB+z);
   plot(XB, ZB, 'linewidth', lw)

   set(gcf, 'color', 1*[1 1 1]);set(gcf, 'InvertHardCopy', 'off');

   figure(10); clf; hold on; axis equal; axis off;

   XX=-Lx:(1/N):Lx;
   YY=-Ly:(1/N):Ly;
   [X, Y]=meshgrid(XX, YY);

   Z=-0.7*((X-z).*X.^2.*(X+z)+Y.^2);
   Z=Z+hh;
   v=[-1 0 0.5];

   [c,h] = contour(Z, [0]);% clabel(c,h)   

   l=c(2, 1);
   x=c(1,2:(l+1));
   y=c(2,2:(l+1));
   x=(x-1)*(1/N)-Lx;
   y=(y-1)*(1/N)-Ly;
   fill(x, y, 0.6*[1, 1, 1]);
   
   
   figure(fig);
   y=y/5;
   plot(x, y, '--', 'linewidth', lw)

   [m, n]=size(c);
   if n > l+2 

      x=c(1,(l+3):(2*l));
      y=c(2,(l+3):(2*l));
      x=(x-1)*(1/N)-Lx;
      y=(y-1)*(1/N)-Ly;
      y=y/5;
      plot(x, y, '--', 'linewidth', lw)

   end


   z2=+height;
   z1=-height;

   k=1.2;
   x1=k*x1;
   x2=k*x2;

   plot(x1, z1, '*', 'color', [1, 1 ,1])
   plot(x2, z2, '*', 'color', [1, 1 ,1])
   axis([x1 x2 z1 z2])

   saveas(gcf, sprintf('merging_graphs%d.eps', count))
   disp(sprintf('merging_graphs%d.eps', count))
