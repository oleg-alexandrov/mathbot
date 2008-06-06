function main()

   line_thickness=2.5; font_size=25; ball_rad=0.03; 
   N=100; Theta=0:1/N:2*pi; X=cos(Theta); Y=sin(Theta);
   red=[1, 0, 0]; black=[0, 0, 0]; green=[0, 1, 0.2]; blue=[0, 0, 1]; white=0.99*[1, 1, 1];

   clf; hold on; axis equal; axis off

   r=1; z=0.0; p=0.2*i+0.23; q=i*p;
   L=1000; T=-L:(1/N):L; T=p+q*T; Tp=1./conj(T)+1.6*p; T=1./conj(Tp); 

   plot(X, Y, 'color', red, 'linewidth', line_thickness);
   plot(real(Tp), imag(Tp), 'color', blue, 'linewidth', line_thickness)
   plot(real(T), imag(T), 'color', green, 'linewidth', line_thickness)
   
   color_ball(real(z), imag(z), ball_rad, red);   place_text_smartly (z, font_size, 5, 'O');

   V1=3.4; plot(V1, V1, '.', 'color', white)
   V2=1.3; plot(-V2, -V2, '.', 'color', white)
   axis([-V2 V1 -V2 V1]);
   
   saveas(gcf, 'inversion_illustration3.eps', 'psc2');
   

function place_text_smartly (z, font_size, pos, tx)

   N=8;  d=0.013; shiftx=0.002; shifty=0.006;
   p=cos(2*pi/N)+sqrt(-1)*sin(2*pi/N);
   z = z + p^pos * d * font_size;
   x = real (z); y=imag(z);
   H=text(x+shiftx*font_size, y+shifty*font_size, tx); 
   set(H, 'fontsize', font_size, 'HorizontalAlignment', 'c', 'VerticalAlignment', 'c')
   
function color_ball(x, y, r, color)
   Theta=0:0.1:2*pi;
   X=r*cos(Theta)+x;
   Y=r*sin(Theta)+y;
   H=fill(X, Y, color);
   set(H, 'EdgeColor', 'none');
		


