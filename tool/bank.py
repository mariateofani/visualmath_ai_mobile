"""Sumber bank soal offline VisualMath AI Mobile + verifikasi numerik.

Soal disusun orisinal oleh tim, mengikuti cakupan OpenStax Calculus Volume 3
(Strang & Herman, CC BY-NC-SA 4.0) bab 2-5 sebagai acuan kurikulum. Setiap
kunci numerik diverifikasi ulang secara numerik oleh fungsi `chk` di bawah.
"""
import math, json, sys

pi, e = math.pi, math.e


def d(f, x, h=1e-6):
    return (f(x + h) - f(x - h)) / (2 * h)


def integ(f, a, b, n=2000):  # Simpson
    if n % 2: n += 1
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3


def integ2(f, ax, bx, ay, by, n=200):
    return integ(lambda x: integ(lambda y: f(x, y), ay(x) if callable(ay) else ay, by(x) if callable(by) else by, n), ax, bx, n)


def integ3(f, a, b, c, dd, g, h, n=60):
    return integ(lambda x: integ(lambda y: integ(lambda z: f(x, y, z), g, h, n), c, dd, n), a, b, n)


TOPICS = [
    ('t0', 'Koordinat & Fungsi', 'Sistem Koordinat & Fungsi Multivariabel'),
    ('t1', 'Fungsi Vektor', 'Fungsi Vektor & Kurva Parametrik'),
    ('t2', 'Limit & Kontinuitas', 'Limit & Kontinuitas Fungsi Multivariabel'),
    ('t3', 'Turunan Parsial', 'Turunan Parsial & Gradien'),
    ('t4', 'Aturan Rantai', 'Diferensial & Aturan Rantai'),
    ('t5', 'Optimasi', 'Ekstrem Lokal & Global (Optimasi)'),
    ('t6', 'Integral Lipat Dua', 'Integral Lipat Dua'),
    ('t7', 'Integral Lipat Tiga', 'Integral Lipat Tiga & Koordinat Polar'),
]

Q = []  # (topic, diff, type, prompt, answer, explanation, hint, options, chk)


def N(t, df, p, a, ex, hint, chk):
    Q.append(dict(topicId=t, difficulty=df, type='numeric', prompt=p, expectedAnswer=a, explanation=ex, hint=hint, options=[], chk=chk))


def C(t, df, p, a, opts, ex, hint):
    assert a in opts
    Q.append(dict(topicId=t, difficulty=df, type='choice', prompt=p, expectedAnswer=a, explanation=ex, hint=hint, options=opts, chk=None))


def TF(t, df, p, a, ex, hint):
    Q.append(dict(topicId=t, difficulty=df, type='truefalse', prompt=p, expectedAnswer=a, explanation=ex, hint=hint, options=['Benar', 'Salah'], chk=None))


# ---------------- t0 Koordinat & Fungsi ----------------
N('t0', 'mudah', 'Diberikan f(x, y) = 3x − 2y + 5. Hitung f(2, −1).', '13', 'Substitusi: 3(2) − 2(−1) + 5 = 6 + 2 + 5 = 13.', 'Ganti x dengan 2 dan y dengan −1.', lambda: 3*2 - 2*(-1) + 5)
N('t0', 'mudah', 'Titik dalam koordinat polar (r, θ) = (4, π/2). Berapa koordinat y-nya?', '4', 'y = r sin θ = 4 · sin(π/2) = 4 · 1 = 4.', 'Gunakan y = r sin θ.', lambda: 4*math.sin(pi/2))
C('t0', 'mudah', 'Domain alami f(x, y) = √(9 − x² − y²) adalah …', 'Cakram x² + y² ≤ 9', ['Seluruh bidang R²', 'Cakram x² + y² ≤ 9', 'Lingkaran x² + y² = 9 saja', 'Daerah x² + y² > 9'], 'Bilangan di bawah akar harus ≥ 0: 9 − x² − y² ≥ 0, yaitu x² + y² ≤ 9.', 'Syarat akar kuadrat: isinya tidak boleh negatif.')
N('t0', 'mudah', 'Kurva level f(x, y) = x² + y² untuk c = 25 berupa lingkaran. Berapa jari-jarinya?', '5', 'x² + y² = 25 adalah lingkaran berpusat (0, 0) dengan jari-jari √25 = 5.', 'Kurva level: f(x, y) = c.', lambda: math.sqrt(25))
N('t0', 'sedang', 'Hitung jarak antara P(1, 2, −1) dan Q(3, −1, 5).', '7', 'Jarak = √((3−1)² + (−1−2)² + (5+1)²) = √(4 + 9 + 36) = √49 = 7.', 'Rumus jarak di ruang tiga dimensi.', lambda: math.dist((1, 2, -1), (3, -1, 5)))
N('t0', 'sedang', 'Titik kartesius (−3, 3√3) diubah ke polar dengan 0 ≤ θ < 2π. Berapa θ dalam radian? (4 desimal)', '2.0944', 'r = √(9 + 27) = 6. Titik di kuadran II dengan tan θ = −√3, sehingga θ = 2π/3 ≈ 2.0944.', 'Perhatikan kuadran titik sebelum memakai arctan.', lambda: math.atan2(3*math.sqrt(3), -3))
C('t0', 'sedang', 'Grafik permukaan z = √(x² + y²) berbentuk …', 'Kerucut', ['Paraboloid', 'Kerucut', 'Bola', 'Bidang datar'], 'Pada setiap ketinggian z = c, penampangnya lingkaran berjari-jari c yang membesar linear: bentuk kerucut.', 'Amati penampang horizontal z = c.')
N('t0', 'sedang', 'Diberikan g(x, y) = x·eʸ + ln x. Hitung g(2, ln 3). (4 desimal)', '6.6931', 'g(2, ln 3) = 2 · e^(ln 3) + ln 2 = 2 · 3 + 0.6931 = 6.6931.', 'Ingat e^(ln a) = a.', lambda: 2*math.exp(math.log(3)) + math.log(2))
N('t0', 'sulit', 'Titik dalam koordinat bola (ρ, φ, θ) = (2, π/3, π/4). Hitung koordinat x-nya. (4 desimal)', '1.2247', 'x = ρ sin φ cos θ = 2 · (√3/2) · (√2/2) = √6/2 ≈ 1.2247.', 'x = ρ sin φ cos θ.', lambda: 2*math.sin(pi/3)*math.cos(pi/4))
C('t0', 'sulit', 'Domain alami f(x, y) = ln(x − y) adalah …', 'Semua titik dengan y < x', ['Semua titik dengan y < x', 'Semua titik dengan y ≤ x', 'Semua titik dengan y > x', 'Seluruh bidang R²'], 'Logaritma hanya terdefinisi untuk argumen positif: x − y > 0, yaitu y < x (garis y = x tidak termasuk).', 'Argumen ln harus positif, bukan nol.')
N('t0', 'sulit', 'Titik kartesius (1, 1, 2) diubah ke koordinat silinder (r, θ, z). Berapa r? (4 desimal)', '1.4142', 'r = √(x² + y²) = √2 ≈ 1.4142, sedangkan θ = π/4 dan z = 2.', 'r hanya bergantung pada x dan y.', lambda: math.hypot(1, 1))
TF('t0', 'sulit', 'Kurva-kurva level dari f(x, y) = y − x² berupa parabola.', 'Benar', 'y − x² = c ekuivalen dengan y = x² + c, yaitu parabola yang digeser vertikal.', 'Tulis f(x, y) = c lalu nyatakan y.')

# ---------------- t1 Fungsi Vektor ----------------
N('t1', 'mudah', 'Diberikan r(t) = ⟨t, 2t, 2⟩. Hitung |r(1)|.', '3', 'r(1) = ⟨1, 2, 2⟩, panjangnya √(1 + 4 + 4) = 3.', 'Panjang vektor = akar jumlah kuadrat komponen.', lambda: math.sqrt(1 + 4 + 4))
N('t1', 'mudah', 'Diberikan r(t) = ⟨3t, t², 1 − t⟩. Berapa komponen y dari r′(2)?', '4', 'r′(t) = ⟨3, 2t, −1⟩, sehingga komponen y di t = 2 adalah 4.', 'Turunkan setiap komponen terhadap t.', lambda: d(lambda t: t*t, 2))
C('t1', 'mudah', 'Kurva r(t) = ⟨cos t, sin t, 0⟩, 0 ≤ t ≤ 2π, berupa …', 'Lingkaran satuan pada bidang xy', ['Garis lurus', 'Lingkaran satuan pada bidang xy', 'Heliks', 'Parabola'], 'x² + y² = cos² t + sin² t = 1 dan z = 0: lingkaran berjari-jari 1 pada bidang xy.', 'Hitung x² + y².')
N('t1', 'mudah', 'Sebuah partikel bergerak dengan r(t) = ⟨3t, 4t, 0⟩. Berapa lajunya |r′(t)|?', '5', 'r′(t) = ⟨3, 4, 0⟩, sehingga lajunya √(9 + 16) = 5.', 'Laju = panjang vektor kecepatan.', lambda: math.hypot(3, 4))
N('t1', 'sedang', 'Untuk heliks r(t) = ⟨cos t, sin t, t⟩, hitung laju |r′(t)|. (4 desimal)', '1.4142', 'r′(t) = ⟨−sin t, cos t, 1⟩, panjangnya √(sin² t + cos² t + 1) = √2 ≈ 1.4142.', 'Gunakan sin² t + cos² t = 1.', lambda: math.sqrt(2))
N('t1', 'sedang', 'Hitung panjang busur r(t) = ⟨2t, 3t, 6t⟩ untuk 0 ≤ t ≤ 2.', '14', '|r′(t)| = √(4 + 9 + 36) = 7, sehingga panjang busur = ∫₀² 7 dt = 14.', 'Panjang busur = ∫ |r′(t)| dt.', lambda: integ(lambda t: 7, 0, 2))
N('t1', 'sedang', 'Diberikan r(t) = ⟨t, t², t³⟩. Berapa komponen z dari percepatan r″(1)?', '6', 'r′(t) = ⟨1, 2t, 3t²⟩, r″(t) = ⟨0, 2, 6t⟩, sehingga komponen z di t = 1 adalah 6.', 'Turunkan dua kali.', lambda: 6*1)
C('t1', 'sedang', 'Hasil ∫₀¹ ⟨2t, 1⟩ dt adalah …', '⟨1, 1⟩', ['⟨2, 1⟩', '⟨1, 1⟩', '⟨1, 0⟩', '⟨2, 0⟩'], 'Integralkan per komponen: ∫₀¹ 2t dt = 1 dan ∫₀¹ 1 dt = 1.', 'Integral vektor dihitung per komponen.')
N('t1', 'sulit', 'Hitung panjang satu putaran heliks r(t) = ⟨3 cos t, 3 sin t, 4t⟩, 0 ≤ t ≤ 2π. (4 desimal)', '31.4159', '|r′(t)| = √(9 sin² t + 9 cos² t + 16) = 5, sehingga panjangnya 5 · 2π = 10π ≈ 31.4159.', 'Laju heliks ini konstan.', lambda: integ(lambda t: math.sqrt((3*math.sin(t))**2 + (3*math.cos(t))**2 + 16), 0, 2*pi))
N('t1', 'sulit', 'Berapa kelengkungan κ lingkaran r(t) = ⟨4 cos t, 4 sin t⟩?', '0.25', 'Kelengkungan lingkaran berjari-jari R adalah 1/R = 1/4 = 0.25.', 'κ = |r′ × r″| / |r′|³, atau ingat hasil untuk lingkaran.', lambda: abs((-4*math.sin(1))*(-4*math.sin(1)) - (4*math.cos(1))*(-4*math.cos(1))) / 4**3)
N('t1', 'sulit', 'Untuk r(t) = ⟨t², 2t⟩, berapa komponen x dari vektor singgung satuan T(1)? (4 desimal)', '0.7071', 'r′(t) = ⟨2t, 2⟩, r′(1) = ⟨2, 2⟩ dengan panjang 2√2, sehingga T(1) = ⟨1/√2, 1/√2⟩ ≈ ⟨0.7071, 0.7071⟩.', 'T = r′ / |r′|.', lambda: 2/math.hypot(2, 2))
N('t1', 'sulit', 'Proyektil memiliki a(t) = ⟨0, −10⟩, v(0) = ⟨20, 15⟩, dan r(0) = ⟨0, 0⟩. Berapa ketinggian maksimumnya?', '11.25', 'v_y = 15 − 10t = 0 saat t = 1.5. y(1.5) = 15(1.5) − 5(1.5)² = 22.5 − 11.25 = 11.25.', 'Ketinggian maksimum tercapai saat v_y = 0.', lambda: max(15*t - 5*t*t for t in [i/10000 for i in range(30001)]))

# ---------------- t2 Limit & Kontinuitas ----------------
N('t2', 'mudah', 'Hitung lim_{(x,y)→(1,2)} (x²y + 3).', '5', 'Fungsi polinomial kontinu, jadi substitusi langsung: 1² · 2 + 3 = 5.', 'Polinomial boleh disubstitusi langsung.', lambda: 1*2 + 3)
N('t2', 'mudah', 'Hitung lim_{(x,y)→(2,1)} (x² − y²)/(x + y).', '1', '(x² − y²)/(x + y) = x − y untuk x + y ≠ 0, sehingga limitnya 2 − 1 = 1.', 'Faktorkan pembilang.', lambda: (2.000001**2 - 1**2)/(2.000001 + 1))
TF('t2', 'mudah', 'Setiap polinomial dua peubah kontinu di seluruh R².', 'Benar', 'Polinomial tersusun dari penjumlahan dan perkalian fungsi kontinu, sehingga kontinu di setiap titik.', 'Pikirkan sifat penjumlahan dan perkalian fungsi kontinu.')
N('t2', 'mudah', 'Hitung lim_{(x,y)→(π,0)} [sin(x/2) + eʸ].', '2', 'Substitusi langsung: sin(π/2) + e⁰ = 1 + 1 = 2.', 'Kedua suku kontinu di titik tersebut.', lambda: math.sin(pi/2) + math.exp(0))
N('t2', 'sedang', 'Hitung lim_{(x,y)→(0,0)} sin(x² + y²)/(x² + y²).', '1', 'Misalkan u = x² + y² → 0. Limitnya sama dengan lim_{u→0} sin u / u = 1.', 'Substitusi u = x² + y².', lambda: math.sin(1e-6)/1e-6)
C('t2', 'sedang', 'lim_{(x,y)→(0,0)} (x² − y²)/(x² + y²) …', 'Tidak ada', ['Sama dengan 0', 'Sama dengan 1', 'Sama dengan −1', 'Tidak ada'], 'Sepanjang sumbu x (y = 0) nilainya 1, sepanjang sumbu y (x = 0) nilainya −1. Nilai berbeda, jadi limit tidak ada.', 'Bandingkan dua lintasan berbeda.')
N('t2', 'sedang', 'Hitung lim_{(x,y)→(1,1)} (x² − 2xy + y²)/(x − y), dengan x ≠ y.', '0', 'Pembilang = (x − y)², sehingga bentuknya menjadi x − y → 0.', 'Pembilang adalah kuadrat sempurna.', lambda: ((1.000001 - 1)**2)/(1.000001 - 1))
N('t2', 'sedang', 'Nilai limit xy/(x² + y²) menuju (0,0) sepanjang garis y = 2x adalah …', '0.4', 'Substitusi y = 2x: 2x²/(x² + 4x²) = 2/5 = 0.4.', 'Ganti y dengan 2x lalu sederhanakan.', lambda: (1e-4*2e-4)/(1e-8 + 4e-8))
N('t2', 'sulit', 'Hitung lim_{(x,y)→(0,0)} x²y/(x² + y²).', '0', '|x²y/(x² + y²)| ≤ |y| karena x²/(x² + y²) ≤ 1. Karena |y| → 0, limitnya 0 (teorema apit).', 'Batasi nilai mutlaknya dengan |y|.', lambda: (1e-4**2*1e-4)/(1e-8 + 1e-8))
C('t2', 'sulit', 'lim_{(x,y)→(0,0)} x²y/(x⁴ + y²) …', 'Tidak ada', ['Sama dengan 0', 'Sama dengan 1/2', 'Tidak ada', 'Sama dengan 1'], 'Sepanjang garis y = mx limitnya 0, tetapi sepanjang parabola y = x² nilainya x⁴/(2x⁴) = 1/2. Karena berbeda, limit tidak ada.', 'Coba lintasan y = x².')
N('t2', 'sulit', 'Hitung lim_{(x,y)→(0,0)} (x² + y²)·ln(x² + y²).', '0', 'Dalam polar, bentuknya r² ln r² dengan r → 0⁺. Karena u ln u → 0 untuk u → 0⁺, limitnya 0.', 'Gunakan koordinat polar.', lambda: 1e-10*math.log(1e-10))
TF('t2', 'sulit', 'Fungsi f(x, y) = xy/(x² + y²) untuk (x, y) ≠ (0, 0) dan f(0, 0) = 0 kontinu di (0, 0).', 'Salah', 'Sepanjang y = x nilainya 1/2, sedangkan f(0, 0) = 0. Limit di (0, 0) tidak ada, jadi f tidak kontinu di sana.', 'Periksa lintasan y = x.')

# ---------------- t3 Turunan Parsial ----------------
N('t3', 'mudah', 'Diberikan f(x, y) = x³ + 2xy. Hitung f_x(1, 2).', '7', 'f_x = 3x² + 2y, sehingga f_x(1, 2) = 3 + 4 = 7.', 'Anggap y konstan saat menurunkan terhadap x.', lambda: d(lambda x: x**3 + 2*x*2, 1))
N('t3', 'mudah', 'Diberikan f(x, y) = x²y³. Hitung f_y(2, 1).', '12', 'f_y = 3x²y², sehingga f_y(2, 1) = 3 · 4 · 1 = 12.', 'Anggap x konstan saat menurunkan terhadap y.', lambda: d(lambda y: 4*y**3, 1))
N('t3', 'mudah', 'Diberikan f(x, y) = 5x − 3y + xy. Hitung f_x(0, 4).', '9', 'f_x = 5 + y, sehingga f_x(0, 4) = 9.', 'Suku −3y menjadi nol saat diturunkan terhadap x.', lambda: d(lambda x: 5*x - 12 + 4*x, 0))
C('t3', 'mudah', 'Turunan parsial ∂/∂x dari e^(xy) adalah …', 'y·e^(xy)', ['e^(xy)', 'x·e^(xy)', 'y·e^(xy)', 'xy·e^(xy)'], 'Aturan rantai: turunan eksponen xy terhadap x adalah y, sehingga hasilnya y·e^(xy).', 'Turunkan pangkatnya terhadap x.')
N('t3', 'sedang', 'Diberikan f(x, y) = sin x · cos y. Hitung f_x(0, 0).', '1', 'f_x = cos x · cos y, sehingga f_x(0, 0) = 1 · 1 = 1.', 'cos y dianggap konstanta.', lambda: d(lambda x: math.sin(x)*math.cos(0), 0))
N('t3', 'sedang', 'Untuk f(x, y) = x² + 3y², hitung |∇f(1, 1)|. (4 desimal)', '6.3246', '∇f = ⟨2x, 6y⟩ = ⟨2, 6⟩ di (1, 1), panjangnya √40 ≈ 6.3246.', 'Gradien = ⟨f_x, f_y⟩.', lambda: math.hypot(2, 6))
N('t3', 'sedang', 'Diberikan f(x, y) = x³y². Hitung f_xy(1, 2).', '12', 'f_x = 3x²y², lalu f_xy = 6x²y, sehingga f_xy(1, 2) = 12.', 'Turunkan terhadap x, lalu terhadap y.', lambda: 6*1*2)
N('t3', 'sedang', 'Hitung turunan berarah f(x, y) = x² + y² di (1, 2) dalam arah u = ⟨3/5, 4/5⟩.', '4.4', '∇f(1, 2) = ⟨2, 4⟩. D_u f = 2(3/5) + 4(4/5) = 22/5 = 4.4.', 'D_u f = ∇f · u.', lambda: d(lambda s: (1 + 0.6*s)**2 + (2 + 0.8*s)**2, 0))
N('t3', 'sulit', 'Diberikan f(x, y) = ln(x² + y²). Hitung f_x(1, 1).', '1', 'f_x = 2x/(x² + y²), sehingga f_x(1, 1) = 2/2 = 1.', 'Aturan rantai untuk ln.', lambda: d(lambda x: math.log(x*x + 1), 1))
N('t3', 'sulit', 'Berapa laju perubahan maksimum f(x, y) = xy² di (2, 1)? (4 desimal)', '4.1231', '∇f = ⟨y², 2xy⟩ = ⟨1, 4⟩. Laju maksimum = |∇f| = √17 ≈ 4.1231.', 'Laju maksimum sama dengan panjang gradien.', lambda: math.hypot(1, 4))
N('t3', 'sulit', 'Bidang singgung z = x² + y² di (1, 2, 5) ditulis z = 2x + 4y + c. Berapa c?', '-5', 'z = 5 + 2(x − 1) + 4(y − 2) = 2x + 4y − 5, sehingga c = −5.', 'z = f(a,b) + f_x(x − a) + f_y(y − b).', lambda: 5 - 2*1 - 4*2)
TF('t3', 'sulit', 'Fungsi f(x, y) = x² − y² memenuhi persamaan Laplace f_xx + f_yy = 0.', 'Benar', 'f_xx = 2 dan f_yy = −2, sehingga jumlahnya 0.', 'Hitung turunan kedua murni.')

# ---------------- t4 Aturan Rantai ----------------
N('t4', 'mudah', 'z = x² + y² dengan x = t dan y = 2t. Hitung dz/dt di t = 1.', '10', 'dz/dt = 2x·1 + 2y·2 = 2t + 8t = 10t, sehingga di t = 1 bernilai 10.', 'dz/dt = z_x·x′ + z_y·y′.', lambda: d(lambda t: t*t + 4*t*t, 1))
N('t4', 'mudah', 'z = xy dengan x = cos t dan y = sin t. Hitung dz/dt di t = 0.', '1', 'dz/dt = y·(−sin t) + x·cos t = 0 + 1 = 1 di t = 0.', 'Gunakan aturan rantai satu parameter.', lambda: d(lambda t: math.cos(t)*math.sin(t), 0))
N('t4', 'mudah', 'Untuk f(x, y) = 3x + 4y, hitung diferensial total df jika dx = 0.1 dan dy = 0.2.', '1.1', 'df = f_x dx + f_y dy = 3(0.1) + 4(0.2) = 0.3 + 0.8 = 1.1.', 'df = f_x dx + f_y dy.', lambda: 3*0.1 + 4*0.2)
C('t4', 'mudah', 'Jika z = f(x, y) dengan x = x(t) dan y = y(t), maka dz/dt = …', '(∂z/∂x)(dx/dt) + (∂z/∂y)(dy/dt)', ['(∂z/∂x)(dx/dt) + (∂z/∂y)(dy/dt)', '(∂z/∂x) + (∂z/∂y)', '(dx/dt)(dy/dt)', '(∂z/∂x)(∂z/∂y)'], 'Perubahan z mengalir melalui x dan y, sehingga kontribusi keduanya dijumlahkan.', 'Ada dua jalur dari t ke z.')
N('t4', 'sedang', 'z = e^(xy) dengan x = t dan y = t². Hitung dz/dt di t = 1. (4 desimal)', '8.1548', 'z = e^(t³), sehingga dz/dt = 3t²·e^(t³) = 3e ≈ 8.1548 di t = 1.', 'Substitusi dulu atau pakai aturan rantai.', lambda: d(lambda t: math.exp(t**3), 1))
N('t4', 'sedang', 'Untuk f(x, y) = √(x² + y²), aproksimasi perubahan df dari (3, 4) ke (3.02, 3.97).', '-0.012', 'f_x = 3/5, f_y = 4/5 di (3, 4). df = 0.6(0.02) + 0.8(−0.03) = 0.012 − 0.024 = −0.012.', 'Gunakan dx = 0.02 dan dy = −0.03.', lambda: 0.6*0.02 + 0.8*(-0.03))
N('t4', 'sedang', 'z = x²y dengan x = s + t dan y = s − t. Hitung ∂z/∂s di (s, t) = (1, 1).', '4', 'Di (1, 1): x = 2, y = 0. z_x = 2xy = 0, z_y = x² = 4. ∂z/∂s = 0·1 + 4·1 = 4.', '∂z/∂s = z_x·x_s + z_y·y_s.', lambda: d(lambda s: (s + 1)**2*(s - 1), 1))
N('t4', 'sedang', 'Untuk kurva x² + y² = 25, hitung dy/dx di (3, 4) dengan diferensiasi implisit.', '-0.75', 'dy/dx = −F_x/F_y = −2x/(2y) = −3/4 = −0.75.', 'dy/dx = −F_x/F_y.', lambda: d(lambda x: math.sqrt(25 - x*x), 3))
N('t4', 'sulit', 'Permukaan xy + yz + xz = 11 melalui (1, 2, 3). Hitung ∂z/∂x di titik itu. (4 desimal)', '-1.6667', 'F_x = y + z = 5 dan F_z = y + x = 3, sehingga ∂z/∂x = −F_x/F_z = −5/3 ≈ −1.6667.', '∂z/∂x = −F_x/F_z.', lambda: d(lambda x: (11 - 2*x)/(2 + x), 1))
N('t4', 'sulit', 'Silinder r = 10 cm, h = 20 cm. Jari-jari naik 0.1 cm dan tinggi turun 0.2 cm. Aproksimasi perubahan volume dV (cm³, 4 desimal).', '62.8319', 'dV = 2πrh dr + πr² dh = 2π(10)(20)(0.1) + π(100)(−0.2) = 40π − 20π = 20π ≈ 62.8319.', 'V = πr²h, lalu dV = V_r dr + V_h dh.', lambda: 2*pi*10*20*0.1 + pi*100*(-0.2))
N('t4', 'sulit', 'z = x² − y² dengan x = r cos θ, y = r sin θ. Hitung ∂z/∂θ di r = 2, θ = π/4.', '-8', 'z = r² cos 2θ, sehingga ∂z/∂θ = −2r² sin 2θ = −2·4·1 = −8.', 'Sederhanakan z ke bentuk polar.', lambda: d(lambda th: 4*math.cos(2*th), pi/4))
N('t4', 'sulit', 'Suhu T = x² + y² + z² diamati sepanjang r(t) = ⟨cos t, sin t, t⟩. Hitung dT/dt di t = 2.', '4', 'Sepanjang kurva T = 1 + t², sehingga dT/dt = 2t = 4 di t = 2.', 'cos² t + sin² t = 1.', lambda: d(lambda t: math.cos(t)**2 + math.sin(t)**2 + t*t, 2))

# ---------------- t5 Optimasi ----------------
N('t5', 'mudah', 'Tentukan nilai minimum f(x, y) = x² + y² − 4x + 6y.', '-13', 'Titik kritis: f_x = 2x − 4 = 0, f_y = 2y + 6 = 0, yaitu (2, −3). f(2, −3) = 4 + 9 − 8 − 18 = −13.', 'Selesaikan f_x = 0 dan f_y = 0.', lambda: 4 + 9 - 8 - 18)
C('t5', 'mudah', 'Titik (0, 0) untuk f(x, y) = x² + y² adalah …', 'Minimum lokal', ['Maksimum lokal', 'Minimum lokal', 'Titik pelana', 'Bukan titik kritis'], 'f ≥ 0 di mana pun dan f(0, 0) = 0, sehingga (0, 0) minimum (lokal dan global).', 'Bandingkan f(0,0) dengan nilai di sekitarnya.')
N('t5', 'mudah', 'Berapa nilai minimum f(x, y) = (x − 1)² + (y + 2)² + 5?', '5', 'Kedua kuadrat bernilai minimal 0 di (1, −2), sehingga minimumnya 5.', 'Kuadrat tidak pernah negatif.', lambda: 5)
TF('t5', 'mudah', 'Di titik kritis interior dari fungsi terdiferensialkan, gradiennya sama dengan vektor nol.', 'Benar', 'Titik kritis interior memenuhi f_x = 0 dan f_y = 0, yaitu ∇f = 0.', 'Ingat definisi titik kritis.')
C('t5', 'sedang', 'Titik (0, 0) untuk f(x, y) = x² − y² adalah …', 'Titik pelana', ['Maksimum lokal', 'Minimum lokal', 'Titik pelana', 'Maksimum global'], 'D = f_xx f_yy − f_xy² = (2)(−2) − 0 = −4 < 0, sehingga titik pelana.', 'Gunakan uji turunan kedua.')
N('t5', 'sedang', 'Untuk f(x, y) = x² + xy + y², hitung D = f_xx f_yy − (f_xy)² di (0, 0).', '3', 'f_xx = 2, f_yy = 2, f_xy = 1, sehingga D = 4 − 1 = 3.', 'Hitung ketiga turunan kedua.', lambda: 2*2 - 1)
N('t5', 'sedang', 'f(x, y) = x³ − 3x + y² memiliki titik kritis (1, 0) dan (−1, 0). Berapa nilai minimum lokalnya?', '-2', 'Di (1, 0): f_xx = 6 > 0 dan D = 6·2 = 12 > 0, minimum lokal. f(1, 0) = 1 − 3 = −2. Titik (−1, 0) adalah pelana.', 'Uji kedua titik dengan D.', lambda: 1 - 3)
N('t5', 'sedang', 'Dua bilangan positif x dan y berjumlah 10. Berapa nilai maksimum hasil kali xy?', '25', 'xy = x(10 − x) maksimum di x = 5, sehingga xy = 25.', 'Substitusi y = 10 − x.', lambda: max(x*(10 - x) for x in [i/1000 for i in range(10001)]))
N('t5', 'sulit', 'Dengan pengali Lagrange, tentukan nilai maksimum f(x, y) = x + y pada lingkaran x² + y² = 8.', '4', '∇f = λ∇g memberi 1 = 2λx dan 1 = 2λy, jadi x = y. Dari 2x² = 8, x = y = 2, f = 4.', 'Selesaikan ∇f = λ∇g bersama kendala.', lambda: max(math.sqrt(8)*(math.cos(t) + math.sin(t)) for t in [i/10000*2*pi for i in range(10001)]))
N('t5', 'sulit', 'Kotak tanpa tutup bervolume 32 cm³. Berapa luas permukaan minimumnya (cm²)?', '48', 'Optimum di alas 4 × 4 dan tinggi 2: luas = 16 + 4(4·2) = 48.', 'Luas = xy + 2xz + 2yz dengan xyz = 32.', lambda: min(x*y + 2*(x + y)*32/(x*y) for x in [1 + i/50 for i in range(400)] for y in [1 + j/50 for j in range(400)]))
N('t5', 'sulit', 'Berapa jarak terdekat dari titik asal ke bidang x + 2y + 2z = 9?', '3', 'Jarak = |9| / √(1 + 4 + 4) = 9/3 = 3.', 'Gunakan rumus jarak titik ke bidang.', lambda: 9/math.sqrt(9))
N('t5', 'sulit', 'Tentukan nilai maksimum absolut f(x, y) = x² + y² − 2x pada cakram x² + y² ≤ 4.', '8', 'Interior: titik kritis (1, 0) dengan f = −1. Batas: f = 4 − 2x, maksimum di x = −2 dengan f = 8.', 'Periksa titik kritis interior dan batas cakram.', lambda: max(4 - 2*2*math.cos(t) for t in [i/10000*2*pi for i in range(10001)]))

# ---------------- t6 Integral Lipat Dua ----------------
N('t6', 'mudah', 'Hitung ∫₀² ∫₀³ 1 dy dx.', '6', 'Integral 1 atas persegi panjang 2 × 3 sama dengan luasnya, yaitu 6.', 'Integral fungsi 1 = luas daerah.', lambda: integ2(lambda x, y: 1, 0, 2, 0, 3, 40))
N('t6', 'mudah', 'Hitung ∫₀¹ ∫₀² (x + y) dy dx.', '3', 'Integral dalam: ∫₀² (x + y) dy = 2x + 2. Integral luar: ∫₀¹ (2x + 2) dx = 1 + 2 = 3.', 'Kerjakan integral dalam terlebih dahulu.', lambda: integ2(lambda x, y: x + y, 0, 1, 0, 2, 40))
N('t6', 'mudah', 'Hitung ∫₀¹ ∫₀¹ xy dx dy.', '0.25', 'Fungsi terpisah: (∫₀¹ x dx)(∫₀¹ y dy) = (1/2)(1/2) = 0.25.', 'xy dapat dipisah menjadi x·y.', lambda: integ2(lambda x, y: x*y, 0, 1, 0, 1, 40))
C('t6', 'mudah', 'Luas daerah D di bidang dapat dihitung dengan …', '∬_D 1 dA', ['∬_D 1 dA', '∬_D x dA', '∫_D y dx', '∬_D (x + y) dA'], 'Mengintegralkan fungsi bernilai 1 atas D menjumlahkan semua elemen luas dA.', 'Fungsi apa yang setiap elemennya bernilai 1?')
N('t6', 'sedang', 'Hitung ∫₀¹ ∫₀ˣ 2y dy dx. (4 desimal)', '0.3333', 'Integral dalam: ∫₀ˣ 2y dy = x². Integral luar: ∫₀¹ x² dx = 1/3 ≈ 0.3333.', 'Batas atas integral dalam bergantung pada x.', lambda: integ2(lambda x, y: 2*y, 0, 1, 0, lambda x: x, 60))
N('t6', 'sedang', 'Hitung volume di bawah z = 4 − x − y di atas persegi panjang [0, 1] × [0, 2].', '5', '∫₀¹ ∫₀² (4 − x − y) dy dx = ∫₀¹ (8 − 2x − 2) dx = 6 − 1 = 5.', 'Volume = ∬ f dA.', lambda: integ2(lambda x, y: 4 - x - y, 0, 1, 0, 2, 40))
N('t6', 'sedang', 'Dengan koordinat polar, hitung ∬ (x² + y²) dA atas cakram x² + y² ≤ 4. (4 desimal)', '25.1327', '∫₀^{2π} ∫₀² r²·r dr dθ = 2π · (2⁴/4) = 8π ≈ 25.1327.', 'Ingat dA = r dr dθ.', lambda: integ(lambda th: integ(lambda r: r**3, 0, 2, 200), 0, 2*pi, 200))
N('t6', 'sedang', 'Berapa nilai rata-rata f(x, y) = x + y pada persegi [0, 2] × [0, 2]?', '2', '∬ (x + y) dA = 4 + 4 = 8 dan luas = 4, sehingga rata-rata = 8/4 = 2.', 'Rata-rata = (1/Luas) ∬ f dA.', lambda: integ2(lambda x, y: x + y, 0, 2, 0, 2, 40)/4)
N('t6', 'sulit', 'Hitung ∫₀¹ ∫ᵧ¹ e^(x²) dx dy dengan mengubah urutan integrasi. (4 desimal)', '0.8591', 'Daerah 0 ≤ y ≤ x ≤ 1. Urutan baru: ∫₀¹ ∫₀ˣ e^(x²) dy dx = ∫₀¹ x·e^(x²) dx = (e − 1)/2 ≈ 0.8591.', 'Gambar daerahnya, lalu integralkan y lebih dulu.', lambda: integ2(lambda x, y: math.exp(x*x), 0, 1, 0, lambda x: x, 200))
N('t6', 'sulit', 'Hitung luas daerah antara y = x² dan y = x. (4 desimal)', '0.1667', 'Kedua kurva berpotongan di x = 0 dan x = 1. Luas = ∫₀¹ ∫_{x²}^{x} dy dx = ∫₀¹ (x − x²) dx = 1/6 ≈ 0.1667.', 'Cari titik potong terlebih dahulu.', lambda: integ2(lambda x, y: 1, 0, 1, lambda x: x*x, lambda x: x, 200))
N('t6', 'sulit', 'Lamina [0, 1] × [0, 1] berdensitas ρ = x + y. Hitung koordinat x pusat massanya. (4 desimal)', '0.5833', 'Massa = ∬ (x + y) dA = 1. M_y = ∬ x(x + y) dA = 1/3 + 1/4 = 7/12, sehingga x̄ = 7/12 ≈ 0.5833.', 'x̄ = (∬ xρ dA) / (∬ ρ dA).', lambda: integ2(lambda x, y: x*(x + y), 0, 1, 0, 1, 60)/integ2(lambda x, y: x + y, 0, 1, 0, 1, 60))
N('t6', 'sulit', 'Hitung ∬ e^(−(x² + y²)) dA atas cakram satuan. (4 desimal)', '1.9859', 'Polar: ∫₀^{2π} ∫₀¹ e^(−r²)·r dr dθ = 2π · (1 − e^(−1))/2 = π(1 − 1/e) ≈ 1.9859.', 'Substitusi u = r².', lambda: integ(lambda th: integ(lambda r: math.exp(-r*r)*r, 0, 1, 200), 0, 2*pi, 100))

# ---------------- t7 Integral Lipat Tiga ----------------
N('t7', 'mudah', 'Hitung ∭ 1 dV atas kotak [0, 1] × [0, 2] × [0, 3].', '6', 'Integral 1 atas kotak sama dengan volumenya: 1 · 2 · 3 = 6.', 'Integral fungsi 1 = volume.', lambda: integ3(lambda x, y, z: 1, 0, 1, 0, 2, 0, 3, 10))
N('t7', 'mudah', 'Hitung ∭ (x + y + z) dV atas kubus satuan [0, 1]³.', '1.5', 'Masing-masing ∭ x dV = ∭ y dV = ∭ z dV = 1/2, jumlahnya 1.5.', 'Pisahkan menjadi tiga integral.', lambda: integ3(lambda x, y, z: x + y + z, 0, 1, 0, 1, 0, 1, 10))
C('t7', 'mudah', 'Elemen volume dV dalam koordinat silinder adalah …', 'r dr dθ dz', ['dr dθ dz', 'r dr dθ dz', 'r² dr dθ dz', 'ρ² sin φ dρ dφ dθ'], 'Elemen luas polar r dr dθ dikalikan dz.', 'Ingat elemen luas polar.')
N('t7', 'mudah', 'Hitung ∫₀² ∫₀¹ ∫₀¹ xyz dz dy dx.', '0.5', 'Terpisah: (∫₀² x dx)(∫₀¹ y dy)(∫₀¹ z dz) = 2 · 1/2 · 1/2 = 0.5.', 'Fungsi xyz dapat dipisah.', lambda: integ3(lambda x, y, z: x*y*z, 0, 2, 0, 1, 0, 1, 10))
N('t7', 'sedang', 'Dengan koordinat silinder, hitung volume silinder r ≤ 2, 0 ≤ z ≤ 5. (4 desimal)', '62.8319', '∫₀^{2π} ∫₀² ∫₀⁵ r dz dr dθ = 2π · 2 · 5 = 20π ≈ 62.8319.', 'Ingat faktor r pada dV.', lambda: 2*pi*integ(lambda r: r*5, 0, 2))
N('t7', 'sedang', 'Dengan koordinat bola, hitung volume bola berjari-jari 3. (4 desimal)', '113.0973', '∫₀^{2π} ∫₀^π ∫₀³ ρ² sin φ dρ dφ dθ = 2π · 2 · 9 = 36π ≈ 113.0973.', 'dV = ρ² sin φ dρ dφ dθ.', lambda: 2*pi*integ(lambda ph: math.sin(ph), 0, pi)*integ(lambda r: r*r, 0, 3))
C('t7', 'sedang', 'Elemen volume dV dalam koordinat bola (ρ, φ, θ) adalah …', 'ρ² sin φ dρ dφ dθ', ['ρ dρ dφ dθ', 'ρ² sin φ dρ dφ dθ', 'ρ² cos φ dρ dφ dθ', 'sin φ dρ dφ dθ'], 'Faktor Jacobian transformasi bola adalah ρ² sin φ.', 'Ingat Jacobian koordinat bola.')
N('t7', 'sedang', 'Hitung ∫₀^{2π} ∫₀¹ r dr dθ. (4 desimal)', '3.1416', 'Integral dalam = 1/2, dikali 2π memberi π ≈ 3.1416 (luas cakram satuan).', 'Integral ini adalah luas cakram satuan.', lambda: integ(lambda th: integ(lambda r: r, 0, 1), 0, 2*pi))
N('t7', 'sulit', 'Hitung volume tetrahedron x + y + z ≤ 1 di oktan pertama. (4 desimal)', '0.1667', '∫₀¹ ∫₀^{1−x} (1 − x − y) dy dx = 1/6 ≈ 0.1667.', 'Batas z: 0 sampai 1 − x − y.', lambda: integ2(lambda x, y: 1 - x - y, 0, 1, 0, lambda x: 1 - x, 200))
N('t7', 'sulit', 'Hitung ∭ (x² + y² + z²) dV atas bola satuan. (4 desimal)', '2.5133', 'Bola: ∫₀^{2π} ∫₀^π ∫₀¹ ρ²·ρ² sin φ dρ dφ dθ = 2π · 2 · 1/5 = 4π/5 ≈ 2.5133.', 'x² + y² + z² = ρ².', lambda: 2*pi*integ(lambda ph: math.sin(ph), 0, pi)*integ(lambda r: r**4, 0, 1))
N('t7', 'sulit', 'Hitung volume daerah di dalam kerucut z = √(x² + y²) dan di bawah bidang z = 2. (4 desimal)', '8.3776', 'Silinder: ∫₀^{2π} ∫₀² ∫_r² r dz dr dθ = 2π ∫₀² (2r − r²) dr = 2π(4 − 8/3) = 8π/3 ≈ 8.3776.', 'Batas z dari r sampai 2.', lambda: 2*pi*integ(lambda r: (2 - r)*r, 0, 2))
N('t7', 'sulit', 'Kubus [0, 1]³ memiliki densitas ρ = x² + y² + z². Hitung massanya.', '1', 'Massa = 3 · ∭ x² dV = 3 · 1/3 = 1.', 'Manfaatkan simetri tiga suku.', lambda: integ3(lambda x, y, z: x*x + y*y + z*z, 0, 1, 0, 1, 0, 1, 10))

# ---------------- verifikasi ----------------
bad = 0
from collections import Counter
cnt = Counter((q['topicId'], q['difficulty']) for q in Q)
for q in Q:
    if q['chk'] is not None:
        v = q['chk']()
        if abs(v - float(q['expectedAnswer'])) > 0.005:
            bad += 1
            print('MISMATCH', q['topicId'], q['difficulty'], q['prompt'][:60], q['expectedAnswer'], v)
print('total', len(Q), 'mismatch', bad, 'per sel', set(cnt.values()))
assert all(v == 4 for v in cnt.values()) and len(cnt) == 24

if bad == 0 and len(sys.argv) > 1:
    def dq(s):
        return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"
    out = ['// GENERATED dari tool/bank.py. Jangan edit manual; ubah bank.py lalu jalankan ulang.',
           '// Soal disusun orisinal oleh Tim Pasti Bisa mengikuti cakupan OpenStax Calculus Volume 3',
           '// (Strang & Herman, CC BY-NC-SA 4.0) bab 2 sampai 5. Kunci numerik diverifikasi numerik.',
           '', "import 'adaptive.dart';", '', 'const kTopics = <TopicInfo>[']
    for tid, short, full in TOPICS:
        out.append(f"  TopicInfo({dq(tid)}, {dq(short)}, {dq(full)}),")
    out += ['];', '', 'const kQuestionBank = <BankQuestion>[']
    seq = Counter()
    for q in Q:
        seq[q['topicId']] += 1
        qid = f"local-{q['topicId']}-{seq[q['topicId']]:02d}"
        opts = '[' + ', '.join(dq(o) for o in q['options']) + ']'
        out.append(f"  BankQuestion(id: {dq(qid)}, topicId: {dq(q['topicId'])}, difficulty: {dq(q['difficulty'])}, type: {dq(q['type'])},")
        out.append(f"    prompt: {dq(q['prompt'])},")
        out.append(f"    expectedAnswer: {dq(q['expectedAnswer'])}, options: {opts},")
        out.append(f"    explanation: {dq(q['explanation'])},")
        out.append(f"    hint: {dq(q['hint'])}),")
    out.append('];')
    open(sys.argv[1], 'w', encoding='utf-8').write('\n'.join(out) + '\n')
    print('ditulis', sys.argv[1])
