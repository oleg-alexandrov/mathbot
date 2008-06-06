% illustrate homotopy with fixed endpoints
function main()

   lw=2;  % line width
   fs=25; % font size 
   h=1/100;
   tiny = 0.004;
   tinyrad=0.02;
   red = [1, 0, 0];
   white = 0.99*[1 1 1];

   % prepare the figure
   figure(1); clf; hold on; axis equal; axis off;

   % generate the curve on which the analytic continuation will take place
   XX=[-0.1, 0.3, 0.1]; YY=[0, 1, 1.5];
   Y=YY(1):h:YY(length(YY)); X=spline(YY, XX, Y);
   
   % plot a circle
   rad=0.4; plot_circle(X(1), Y(1), rad, lw)

   % plot the curves
   t=0; X=spline(YY, XX+[0, t, 0], Y); plot(X, Y, 'color', red, 'linewidth', lw);
   t=0.5; X=spline(YY, XX+[0, t, 0], Y); plot(X, Y, 'color', red, 'linewidth', lw);
   t=-0.8; X=spline(YY, XX+[0, t, 0], Y); plot(X, Y, 'color', red, 'linewidth', lw);
   t=-0.6; X=spline(YY, XX+[0, t, 0], Y); plot(X, Y, 'color', red, 'linewidth', lw);
   t=-0.4; X=spline(YY, XX+[0, t, 0], Y); plot(X, Y, 'color', red, 'linewidth', lw);

   % plot text
   N = length(X);
   Nh = floor(N/2);
   text(X(1), Y(1)-tiny*fs, '\it{P}', 'fontsize', fs)
   text(X(N), Y(N)+tiny*fs, '\it{Q}', 'fontsize', fs)
   text(X(Nh)-0.65, Y(Nh), '\gamma_0', 'fontsize', fs)
   text(X(Nh)+0.06, Y(Nh), '\gamma_s', 'fontsize', fs)
   text(X(Nh)+1.1, Y(Nh), '\gamma_1', 'fontsize', fs)
   text(X(1)-0.26, Y(1)-0.16, '\it{U}', 'fontsize', fs)
   

   % plot some balls for emphasis
   ball(X(1), Y(1), tinyrad, red);
   ball(X(N), Y(N), tinyrad, red);

  % plot a dummy point to avoid having the picture cutt off at edges
  % when saving to eps (a matlab bug)
   plot(X(1), Y(1)-1.1*rad, '*', 'color', white)
   
   saveas(gcf, 'homotopy_with_fixed_endpoints.eps', 'psc2');
   
function plot_circle(x, y, r, lw)

   N=100;
   Theta=0:(1/N):2.1*pi;
   X=r*cos(Theta);
   Y=r*sin(Theta);

   plot(x+X, y+Y, 'linewidth', lw);

function plot_text(x, y, shiftx, shifty, str, fs, tinyrad, color)
   text(x+shiftx, y+shifty, str, 'fontsize', fs);
   ball(x, y, tinyrad, color);
      
function ball(x, y, r, color)
   Theta=0:0.1:2*pi;
   X=r*cos(Theta)+x;
   Y=r*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', 'none');

