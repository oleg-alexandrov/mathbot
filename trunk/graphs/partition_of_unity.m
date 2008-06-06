% illustration of partitition of unity.
% For simplicity, we cheat by using scaled sums of gaussians
% instead of bump functions.

function main()

   figure(1); clf; hold on; axis equal; axis off;
   lw = 2; % linewidth

   h=0.1; % grid size

%  endpoints of the interval
   a = -5; b = 10;

   Sample=[-2.1 -1.3 -0.4 1.3 1.8 3.1 4.5]; 

   red    = [0.867 0.06 0.14];
   blue   = [0, 129, 205]/256;
   green  = [0, 200,  70]/256;
   yellow = [254, 194,   0]/256;
   Colors = [red', blue', green', yellow']';

   L = [2 4 6 8];
   
   X=a:h:b;
   Y = zeros(length(L), length(X));
   Yt = 0*X;

   % gaussian with mean zero variance zsigma
   zsigma=0.55;
   f=inline('exp(-x.^2/2/zsigma)/zsigma/sqrt(2*pi)'); 

   pos = 1;
   for i=1:length(Sample)

      if i > L(pos)
         pos = pos+1;
      end

      Ycur = f(X-Sample(i), zsigma);
      Y(pos, :) = Y(pos, :) + Ycur;
      Yt = Yt+Ycur;
      
   end

   [Xtp, Ytp] = make_periodic (a, b, h, X, Yt);
   Yr = 0*Xtp;
   
   for pos=1:length(L)
      [Xp, Yp] = make_periodic (a, b, h, X, Y(pos, :));
      
      Yp = Yp./Ytp;
      Yr = Yr + Yp;
      plot(Xp, Yp, 'color',  Colors(pos, :), 'linewidth', lw);
   end
   
   plot(Xtp, 0*Yr, 'k', 'linewidth', lw);
   plot(Xtp, Yr, 'k', 'linewidth', lw/1.4, 'linestyle', '--');

   fs = 20;
   shiftx = -0.3;
   shifty = -0.0;
   
   text(Xtp(1)+shiftx, 0+shifty, '0', 'fontsize', fs);
   text(Xtp(1)+shiftx, 1+shifty, '1', 'fontsize', fs);
   
   saveas(gcf, 'Partition_of_unity_illustration.eps', 'psc2');
   %plot2svg('Partition_of_unity_illustration.svg');

function [Xp, Yp] = make_periodic (a, b, h, X, Y)
   
%  Take a function defined on the real line.
%  Wrap the real line around. Sum the overlapping parts.
%  Get a periodic function.
   
   T = 8;
   as = -3; bs = as+T;
   A = (as-a)/h;
   B = (bs-a)/h;

   N = length(Y);
   
   Y((B-A+1):B) = Y((B-A+1):B) + Y(1:A);
   Y((A+1):(A+N-B)) = Y((A+1):(A+N-B)) + Y((B+1):N);

   Yp = Y((A+1):B);
   Xp = X((A+1):B);


