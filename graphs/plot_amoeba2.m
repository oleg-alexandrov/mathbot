A=load('data.txt');

plot(A(:, 1), A(:, 2), '.');
axis equal; grid on;

B=8;
axis([-B, B -B B])
fs = 20; set(gca, 'fontsize', fs)
axis([-4 6 -5 5])
saveas(gcf, 'amoeba2.eps', 'psc2');
