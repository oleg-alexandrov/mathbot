function secant()
   a=-0.9; b=0.75;
   fs=20;
   thickness1=1.5; thickness2=1; arrowsize=4; arrow_type=2;

   h=0.01;
   X=a:h:b;
   f=inline('1*x.*exp(x/1.3-0.1)+0.1');
   x0=0.6; y0=f(x0);
   Y=f(X);
   
   clf; hold on; axis equal; axis off

   plot(X, Y, 'linewidth', thickness1)
   XT=-0.8:h:b;
   x1=-0.7; y1=f(x1);
   m=(y1-y0)/(x1-x0);
   YT=y0+(XT-x0)*m;


   plot(XT, YT, 'r', 'linewidth', thickness1)
   plot([x0 x0], [0, y0], '--', 'linewidth', thickness2, 'color', [0 0 0])
   plot([x1 x1], [0, y1], '--', 'linewidth', thickness2, 'color', [0 0 0])

%H=legend('y=f(x)', 'tangent line');
%set(H, 'fontsize',fs-5, 'Position', [0.5, 0.8 0.3 0.1]);
   arrow([1.2*a 0], [b, 0], thickness2, arrowsize, pi/8,arrow_type, [0, 0, 0]) % horizontal

   small=-.05;
   arrow([a+small, -0.2], [a+small, 1.*max(Y)], thickness2, arrowsize, pi/8,arrow_type, [0, 0, 0])


%   H=text(-0.29, -0.06,  'x'); set(H, 'fontsize', fs)
%   set(H,'horizontalalignment', 'center')

   root=-y0/m+x0;
   H=text(root, 0.1,  'c'); set(H, 'fontsize', fs)
   set(H,'horizontalalignment', 'center')

   H=text(x0, -0.1,  'b'); set(H, 'fontsize', fs)
   set(H,'horizontalalignment', 'center')
   H=text(x1, 0.1,  'a'); set(H, 'fontsize', fs)
   set(H,'horizontalalignment', 'center')

   tp=0.8*b;
   H=text(tp, 0.19+f(tp), 'f(x)'); set(H, 'fontsize', fs)
   set(H,'horizontalalignment', 'center')

   circrad=0.015;
   ball(x0, y0, circrad, 'b')
   ball(root, 0, circrad, 'r')
   ball(x1, y1, circrad, 'b')
   
   saveas(gcf, 'secant_iteration.eps', 'psc2')


   
function ball(x, y, r, color)
   Theta=0:0.1:2*pi;
   X=r*cos(Theta)+x;
   Y=r*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', 'none');
   