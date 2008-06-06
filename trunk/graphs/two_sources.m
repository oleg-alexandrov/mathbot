% illustration of interference of two point sources

L=6;
sep = 2;
N=500;
k= 5;

V=linspace(-L, L, N);
[X, Y] = meshgrid(V, V);

I=sqrt(-1);
R1= sqrt( (X-sep).^2 + Y.^2 );
R2= sqrt( (X+sep).^2 + Y.^2 );

% Sum of Green's functions for two point sources
Z = exp(I*k*R1)./R1 + exp(I*k*R2)./R2;

M=10;
T=linspace(0.0, 2*pi, M); T=T(1:(M-1));
cut = 0.8;
scale = 55/(2*cut);

for p=1:1
   for iter=1:length(T)
      
      figure(1); clf; hold on;

      W = real(Z*exp(-I*T(iter)));
      W = max(W, -cut);
      W = min(W, cut);
      
      image(scale*(W+cut));
      axis equal; axis off;

      file=sprintf('Frame%d.png', 1000+iter);
      disp(sprintf('Saving to %s', file));
      print('-dpng',  '-zbuffer',  '-r100', file);

      pause(0.1);
      
   end

end

% saved to gif with the command
% convert -density 100 -loop 1000 -delay 10 Frame100* Two_sources_interference.gif
% then cropped and scaled in Gimp