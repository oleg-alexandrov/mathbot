function main ()

N=12; line_thickness=2.2; font_size=25; d=0.13; big_rad=10; ball_rad=0.5; ii=sqrt(-1);
red=[1, 0, 0]; green=[0, 1, 0]; blue=[0, 0, 1];
All=[red' green' blue'];

figure(1); clf; hold on; axis equal; axis off;

Theta=0:0.1:3*pi;
X=big_rad*cos(Theta);
Y=big_rad*sin(Theta);
plot(X, Y, 'linewidth', line_thickness, 'color', [0 0 0]);

for i=0:(N-1)
   z=big_rad*exp(i*ii*2*pi/N);
   place_text_smartly (z, font_size, i, d, sprintf('%d\\pi/%d', i, N/2), N);
   color_ball(real(z), imag(z), ball_rad, All(:, mod(i, 3)+1)'); 
end

scale=1.4;plot(scale*big_rad,  scale*big_rad)
scale=-1.4;plot(scale*big_rad,  scale*big_rad)

saveas(gcf, 'Normal_subgroup_illustration.eps', 'psc2')
saveas(gcf, 'Normal_subgroup_illustration.png')

function place_text_smartly (z, font_size, pos, d, tx, N)
 p=cos(2*pi/N)+sqrt(-1)*sin(2*pi/N);
 z = z + p^pos * d * font_size;
 shiftx=0.0003; shifty=0.03;
 x = real (z); y=imag(z);
 H=text(x+shiftx*font_size, y+shifty*font_size, tx); 
 set(H, 'fontsize', font_size, 'HorizontalAlignment', 'c', 'VerticalAlignment', 'c')

 function color_ball(x, y, r, color)
    Theta=0:0.1:2*pi;
    X=r*cos(Theta)+x;
    Y=r*sin(Theta)+y;
    H=fill(X, Y, color);
    set(H, 'EdgeColor', 'none');
		
