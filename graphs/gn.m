function [X, Y] = main()
   
   f=inline('beta1*x/(beta2+x)', 'beta1', 'beta2', 'x');
   f1=inline('x/(beta2+x)', 'beta1', 'beta2', 'x');
   f2=inline('-beta1*x/(beta2+x)^2', 'beta1', 'beta2', 'x');

   X = [0.038 	0.194 	    0.425 	0.626 	1.253 	2.500 	3.740];
   Y = [0.05    0.127       0.094    0.2122    0.2729    0.2665    0.3317];

   beta10 = 0.3; beta20 = 0.3;

   m = length(X);
   R = zeros(m, 1);
   J = zeros(m, 2);

   v = [beta10, beta20]';
   
   for i=0:10 % iterate

      disp(sprintf('%0.9g %0.9g %0.9g', v(1), v(2), norm(R)));
      
      for i=1:length(X)
	 R(i)    = Y(i) - f (beta10, beta20, X(i));
	 J(i, 1) =       -f1(beta10, beta20, X(i));
	 J(i, 2) =       -f2(beta10, beta20, X(i));
      end

      v = v - (J'*J)\(J'*R);

      
      beta10 = v(1);
      beta20 = v(2);

   end
   
   % KSmrq's colors
   red=[0.867 0.06 0.14];
   blue = [0, 129, 205]/256;
   green = [0, 200,  70]/256;
   black = [0, 0, 0];
   white = 0.99*[1, 1, 1];
   gray = 0.8*white;

   fs = 30;
   lw = 7;

   figure(1); clf; hold on;
   set(gca, 'fontsize', fs);

   Hx=xlabel('[S]')
   set(gca, 'linewidth', lw/2);

   Hy=ylabel('reaction rate');

   
   hold on; %axis equal;
   
   h=0.1;
   xs = 0; xl = max(X)+0.2;
   Xe = xs:h:xl;
   Ye = 0*Xe;
   for i=1:length(Xe)
      Ye(i) = f(beta10, beta20, Xe(i));
   end
   plot(Xe, Ye, 'color', blue, 'linewidth', lw);

   for i=1:length(X)
      plot(X(i), Y(i), 'color', red, 'marker', 'd', 'linewidth', lw);
   end



   axis([0 4 0 0.35]);
   set(gca, 'XTick', [0 1 2 3 4]);
   set(gca, 'YTick', [0 0.05 0.1 0.15 0.2 0.25 0.3 0.35]);

   saveas(gcf, 'Gauss_Newton_illustration.eps', 'psc2'); % save as eps
   return


   
function ball(x, y, r, color)
   Theta=0:0.1:2*pi;
   X=r*cos(Theta)+x;
   Y=r*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', 'none');

   