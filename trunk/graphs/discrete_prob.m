% plot a the cummulative distribution function for a
% (a) discrete distribution
% (b) continuous distribtuion
% (c) a distribution which has both a discrete and a continuous part

function main()

   clf; hold on; axis equal; axis off;
   L=4; h = 0.02;
   X=0:h:L;
   shift = 2;
   
   Y = [0*find(X < 0.2*L), 0.3+0*find( X >= 0.2*L & X < 0.4*L) 0.6+0*find(X >= 0.4*L & X < 0.8*L), 1+0*find(X>= 0.8*L)];
   plot_graph(X, Y, L, 0*shift)

   Y = 0.5*erf((4/L)*(X-L/2.5))+0.5;
   plot_graph(X, Y, L, shift);

   ds = 0.4;
   Y = 0.5*erf((2/L)*(X-L/1.5))+0.5;
   Y = Y + [0*find(X < ds*L) 0.4+0*find(X >= ds*L)]; Y = min(Y, 1);
   plot_graph(X, Y, L, 2*shift);

   % plot two dummy points to make matlab expand a bit the window before saving
   plot(L+0.15, 1.1, '*', 'color', 0.99*[1, 1, 1]);
   plot(-0.5, -2.1*shift, '*', 'color', 0.99*[1, 1, 1]);

   % save as eps
   saveas(gcf, 'Discrete_probability_distribution_illustration.eps', 'psc2')
   
function plot_graph(X, Y, L, shift)

   % settings
   N = length (X);
   tol = 0.1;
   thick_line = 3;
   thin_line = 2;
   small_rad = 0.07;
   red= [1, 0, 0];
   blue = [0, 0, 1];
   fs = 23;
   epsilon = 0.01;
   
% plot a blue box
   plot([0, L, L, 0, 0], [0, 0, 1, 1, 0]-shift, 'linewidth', thin_line, 'color', blue)

   % everything will be shifted down
   Y  = Y - shift;
   
   % if the given funtion has a jump, plot some balls. Otherwise plot a continous segment
   for i=1:(N-1)
      if abs(Y(i)-Y(i+1)) > tol
	 
	 ball       (X(i+1), Y(i+1), small_rad,                red);
	 empty_ball (X(i),   Y(i),   thin_line, 0.9*small_rad, red);

      else
	 plot([X(i)-epsilon, X(i+1)+epsilon], [Y(i), Y(i+1)], 'color', red, 'linewidth', thick_line);
      end
   end

   ball       (0, -shift, small_rad,             red);
   ball       (L, 1-shift, small_rad,             red);

%plot text
   small= 0.4;
   text(-small, 0-shift, '0', 'fontsize', fs)
   text(-small, 1-shift, '1', 'fontsize', fs)
   
   
function ball(x, y, r, color)
   Theta=0:0.1:2*pi;
   X=r*cos(Theta)+x;
   Y=r*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', 'none');


function empty_ball(x, y, thick_line, r, color)
   Theta=0:0.1:2*pi;
   X=r*cos(Theta)+x;
   Y=r*sin(Theta)+y;
   H=fill(X, Y, [1 1 1]);
   plot(X, Y, 'color', color, 'linewidth', thick_line);
