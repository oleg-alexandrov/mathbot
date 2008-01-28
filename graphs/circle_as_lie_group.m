function main()
   
% KSmrq's colors
   red    = [0.867 0.06 0.14];
   blue   = [0, 129, 205]/256;
   green  = [0, 200,  70]/256;
   yellow = [254, 194,   0]/256;
   white = 0.99*[1, 1, 1];
   black = 0*white;

   lw = 2;

   Theta = 0:0.01:2*pi;

   X = cos(Theta);
   Y = sin(Theta);


   figure(1); clf; hold on; axis equal; axis off;

% plot the axes
   L = 1.3;
   thin = 0.6*lw;
   plot([-L, L], [0, 0], 'linewidth', lw, 'color', black);
   plot([0, 0], [-L, L], 'linewidth', lw, 'color', black);
   
   plot(X, Y, 'color', 'green', 'linewidth', lw);

% dummy plot to increase the size of the bounding box
   small = 0.1;
   plot(1+small, 1+small, '*', 'color', white);
   plot(-1-small, -1-small, '*', 'color', white);

   % plot text
   fs = 20;
   small_rad = 0.03;
   d=0.02;
   
   theta1=0.4*pi;
   place_text_smartly (exp(i*theta1), fs, d, 'e^{i\theta}');
   ball(cos(theta1), sin(theta1), small_rad, green);

   theta2=0.8*pi;
   place_text_smartly (exp(i*theta2), fs, d, 'e^{i\phi}');
   ball(cos(theta2), sin(theta2), small_rad, green);

   theta3=theta1+theta2;
   place_text_smartly (exp(i*theta3), fs, d, 'e^{i(\theta+\phi)}');
   ball(cos(theta3), sin(theta3), small_rad, green);

   % plot the circle center and the point 1.
   place_text_smartly (exp(i*0.1), fs, d, '1');

   place_text_smartly (0.01, fs, d, '0');
   ball(1, 0, small_rad, black);

   plot2svg('Circle_as_Lie_group.svg');
   
function ball(x, y, radius, color) % draw a ball of given uniform color 
   Theta=0:0.1:2*pi;
   X=radius*cos(Theta)+x;
   Y=radius*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', color);


function place_text_smartly (z, fs, d, tx);

   z = z*(1 + d*fs);
   shiftx=0.0003; shifty=0.003;
   x = real (z); y=imag(z);
   H=text(x+shiftx*fs, y+shifty*fs, tx); 
   set(H, 'fontsize', fs, 'HorizontalAlignment', 'c', 'VerticalAlignment', 'c')

