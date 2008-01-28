% an illustration of convex metric spaces
function main()
   

   N=100;
   A=-0.4; B=-0.1;
   X=linspace(A, B, N);
   Y=2*(1-X.^2);

   figure(1); clf; hold on; axis equal; axis off;
   lw=1.5; black=[0, 0, 0];
   plot(X, Y, '--', 'linewidth', lw)

%  plot some balls, to emphasize where the points are
   ball_rad=0.007;
   blue=[0, 0, 1]; red=[1, 0, 0];
   ball(X(1), Y(1), ball_rad, blue)
   ball(X(N), Y(N), ball_rad, blue)
   t=0.4; M = floor(N*t);
   ball(X(M), Y(M), ball_rad, red)

%  plot text
   fs=50;
   d=0.0015;
   ii=sqrt(-1);
   place_text_smartly (X(1)+i*Y(1), fs, 3, 0.6*d, '\it{x}', 6)
   place_text_smartly (X(M)+i*Y(M), fs, 2, d, '\it{z}', 6)
   place_text_smartly (X(N)+i*Y(N), fs, 1, d, '\it{y}', 6)

   % a phony box to avoid matlab bugs in saving to eps
   h0=0.1; 
   white=0.99*[1, 1, 1];
   plot(X(N), Y(N)+h0, 'color', white)
   
   saveas(gcf, 'Convex_metric_illustration.eps', 'psc2');
   
function ball(x, y, r, color)
   Theta=0:0.1:2*pi;
   X=r*cos(Theta)+x;
   Y=r*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', 'none');


function place_text_smartly (z, font_size, pos, d, tx, N)
   p=cos(2*pi/N)+sqrt(-1)*sin(2*pi/N);
   z = z + p^pos * d * font_size;
   x = real (z); y=imag(z);
   H=text(x, y, tx);
   set(H, 'fontsize', font_size, 'HorizontalAlignment', 'c', 'VerticalAlignment', 'c')
   