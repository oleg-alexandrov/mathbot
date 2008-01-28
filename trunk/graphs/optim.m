function optim()
   L=2;
   xx=[-0.9*L -0.6*L 0.3*L 0.1*L]; yy=xx.^2;
   for i=0:4%length(xx)
      make_graph(L, xx, yy, i);
   end

function make_graph(L, xx, yy, P)

   figure(1); clf; hold on; axis equal; axis off;
   set(gcf, 'color', 'white');set(gcf, 'InvertHardCopy', 'off');
   fontsize=25; lw=2;
   
   N=100;h=1/N;
   
   dist=0.15*L;
   X=-L:h:L;
   Y=X.^2;
   plot(X, Y, 'linewidth', lw)

   for i=1:P
      x0=xx(i); y0=yy(i);
      plot(x0, y0, 'rx', 'linewidth', 2*lw)

      r0=sqrt(4*x0*x0+1);
      a0=dist*2*x0/r0; b0=-dist*1/r0;

      H=text(x0+a0, y0+b0, sprintf('x%d', i-1));
      set(H, 'fontsize', fontsize, 'HorizontalAlignment', 'center');

      if i<P
	 plot([xx(i) xx(i+1)], [yy(i), yy(i+1)], 'r', 'linewidth', lw)
      end
      
   end

   Ax1=-1.2*L; Ax2=1.1*L; Ay1=-0.2*L; Ay2=1.1*L*L;
   plot(Ax1, Ay1, '.', 'color', [1, 1 ,1])
   plot(Ax2, Ay2, '.', 'color', [1, 1 ,1])
   axis([Ax1 Ax2 Ay1 Ay2])
   char=sprintf('optim%d.eps', P);
   disp(char);
   saveas(gcf, char, 'psc2');


