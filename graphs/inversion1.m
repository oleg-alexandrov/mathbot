function main()

   line_thickness=2.5; font_size=25; ball_rad=0.035; 
   N=100; Theta=0:1/N:2*pi; X=cos(Theta); Y=sin(Theta);
   red=[1, 0, 0]; black=[0, 0, 0]; green=[0, 1, 0]; blue=[0, 0, 1]; white=0.99*[1, 1, 1];

   clf; hold on; axis equal; axis off

   r=1; z=0.0; p=0.2*i+0.3; pp=r/conj(p);

   plot(X, Y, 'color', red, 'linewidth', line_thickness);
   plot([real(z), real(pp)], [imag(z), imag(pp)], 'color', blue, 'linewidth', line_thickness)
   
   color_ball(real(z), imag(z), ball_rad, red);   place_text_smartly (z, font_size, 3, 'O');
   color_ball(real(p), imag(p), ball_rad, blue);   place_text_smartly (p, font_size, 2, 'P');
   color_ball(real(pp), imag(pp), ball_rad, blue); place_text_smartly (pp, font_size, 2, 'P\prime');

   V=2.5; plot(V, V, '.', 'color', white)
   V=1.3; plot(-V, -V, '.', 'color', white)
   saveas(gcf, 'inversion_illustration1.eps', 'psc2');
   

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