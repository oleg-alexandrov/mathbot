%function main()

   clear X; clear Y;
   M=10; i=sqrt(-1); lw=2.5;
   figure(1); clf; hold on; axis equal; axis off;

%  a dummy plot to avoid a matlab bug causing some lines to appear too thin
   plot(8.5, 7.5, '*', 'color', 0.99*[1, 1, 1]);
   plot(-4.5, -5, '*', 'color', 0.99*[1, 1, 1]);

% plot the outer polygonal curve
   color = [139;10;80]/256;

%   X=[-1.4539 1.6162 0.4101 3.5168 -1.8925 0.8487 1.2507 3.9920 2.3838 4.9423  1.3238 4.5402];
%   Y=[2.3282 -0.1206 3.8268 0.9393 5.2887 1.7069 1.4876 -1.0344 3.0958 5.0329  2.2551 -0.6323];
%   X=[-1.4539 1.6162 0.4101 3.5168 -1.8925 0.8487 1.2507 3.9920 2.3838 4.9423 0.2639 3.4803 1.3238 4.5402];
%   Y=[2.3282 -0.1206 3.8268 0.9393 5.2887 1.7069 1.4876 -1.0344 3.0958 5.0329 -0.0841 -1.3999 2.2551 -0.6323];

%   n=length(X)/2;
%   for i=1:n
%      ax=X(2*i-1); bx=X(2*i);
%      ay=Y(2*i-1); by=Y(2*i);
%      
%      plot([ax bx bx ax ax], [ay ay by by ay]);
%      text((ax+bx)/2, (ay+by)/2, sprintf('%d', i));
%   end
   
   for i=1:1000
   [ax, ay, but]=ginput(1); plot(ax, ay, '*'); if but == 2; break; end;
      [bx, by, but]=ginput(1); plot(bx, by, '*'); if but == 2; break; end;

      plot([ax bx bx ax ax], [ay ay by by ay]);
      
      X(2*i-1)=ax; X(2*i)=bx;
      Y(2*i-1)=ay; Y(2*i)=by;
   end
%   
   X
   Y
   saveas(gcf, 'simple_set.eps', 'psc2');

%function plot_poly (Start, Dir, Sign, f, lw, color)
%
%   Current_point = Start;
%   Current_dir   = Dir;
%
%   Ball_rad = 0.03;
%   
%   for k=1:100
%      
%      Next_dir=-Current_dir;
%
%      % from the current point, search to the left, down, and right and see where to go next
%      for l=1:3
%	 Next_dir = Next_dir*(Sign*i);
%	 
%	 if Sign*f(Current_point+Next_dir)>=0 & Sign*f(Current_point+(Sign*i)*Next_dir) < 0
%	    break;
%	 end
%      end
%      
%      Next_point = Current_point+Next_dir;
%
%      plot([real(Current_point), real(Next_point)], [imag(Current_point), imag(Next_point)], 'linewidth', lw, 'color', color);
%
%      round_ball(Current_point, Ball_rad, color'); % just for beauty, to round off some rough corners
%      
%      Current_dir=Next_dir;
%      Current_point = Next_point;
%
%   end
%
%
%function round_ball(z, r, color)
%   x=real(z); y=imag(z);
%   Theta = 0:0.1:2*pi;
%   X = r*cos(Theta)+x;
%   Y = r*sin(Theta)+y;
%   Handle = fill(X, Y, color);
%   set(Handle, 'EdgeColor', color);