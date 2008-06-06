% A wave travelling on a string with
% fixed endpoints

function main()

   % KSmrq's colors
   red    = [0.867 0.06 0.14];
   blue   = [0, 129, 205]/256;
   green  = [0, 200,  70]/256;
   yellow = [254, 194,   0]/256;
   white = 0.99*[1, 1, 1];
   
   % length of the string and the grid
   L = 5;
   N = 151;
   X=linspace(0, L, N);

   h = X(2)-X(1); % space grid size
   c = 0.5; % speed of the wave
   tau = 0.25*h/c; % time grid size
   
   K = 5; % steepness of the bump
   S = 0; % shift the wave
   f=inline('exp(-K*(x-S).^2)', 'x', 'S', 'K'); % a gaussian as an initial wave
   df=inline('-2*K*(x-S).*exp(-K*(x-S).^2)', 'x', 'S', 'K'); % derivative of f
   
   U0 = 0*f(X, S, K);
   U1 = U0 - 2*tau*c*df(X, S, K);
   
   U = 0*U0; % current U

   Big=10000;
   Ut = zeros(Big, N);
   Ut(1, :) = U0;
   Ut(2, :) = U1;
   
   % hack to capture the first period of the wave
   min_k = 2*N; k_old = min_k; turn_on = 0; 

   for j=3:Big

      last_j = j;
      
      %  fixed end points
      U(1)=0; U(N)=0;
      
      % finite difference discretization in time
      for i=2:(N-1)
         U(i) = (c*tau/h)^2*(U1(i+1)-2*U1(i)+U1(i-1)) + 2*U1(i) - U0(i);
      end

      Ut(j, :) = U;
      
      % update info, for the next iteration
      U0 = U1; U1 = U;

     
      k = find ( abs(U) == max(abs(U)) );
      k = k(1);

      if k > N/2
         turn_on = 1;
      end

      % hack to capture the first period of the wave
      min_k = min(min_k, k_old);
      if k > min_k & min_k == k_old & turn_on == 1
         break;
      end
      k_old = k; 
      
   end

   % truncate to the first period
   last_j = last_j - 1;
   Ut = Ut(1:last_j, :);

  % shift the wave by a certain amount
   shift = floor(last_j/4);
   Vt=Ut;
   Ut((last_j-shift+1):last_j, :) = Vt(1:shift, :);
   Ut(1:(last_j-shift), :)        = Vt((shift+1):last_j, :);

   last_j

   num_frames = 100;
   spacing=floor(last_j/num_frames)
   
   % plot the wave
   for j=1:(last_j-spacing+1)

      U = Ut(j, :);

      if rem(j, spacing) == 1

         figure(1); clf; hold on;
	 axis equal; axis off; 
	 lw = 3; % linewidth
	 plot(X, U, 'color', red, 'linewidth', lw);
	 
         % plot the ends of the string
	 small_rad = 0.06;
	 ball(0, 0, small_rad, red);
	 ball(L, 0, small_rad, red);
	 
         % size of the window
	 ys = 1.1;
	 axis([-small_rad, L+small_rad, -ys, ys]);
      
         % small markers to keep the bounding box fixed when saving to eps
	 plot(-small_rad, ys, '*', 'color', white);
	 plot(L+small_rad, -ys, '*', 'color', white);

	 frame_no = floor(j/spacing)+1;
	 frame=sprintf('Frame%d.eps', 1000+frame_no);
	 disp(frame)
	 saveas(gcf, frame, 'psc2');

      end
   end
   
function ball(x, y, radius, color) % draw a ball of given uniform color 
   Theta=0:0.1:2*pi;
   X=radius*cos(Theta)+x;
   Y=radius*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', color);

