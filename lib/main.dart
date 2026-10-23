
import 'package:flutter/material.dart';
import 'dart:convert';
import 'services/visualmath_api.dart';
import 'package:dio/dio.dart';


void main() {
  runApp(const VisualMathApp());
}

const Color primaryBlue = Color(0xFF2878F0);
const Color lightBlue = Color(0xFFEAF3FF);
const Color darkNavy = Color(0xFF183153);
const Color pageBackground = Color(0xFFF7F9FE);

class VisualMathApp extends StatelessWidget {
  const VisualMathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VisualMath AI',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: pageBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
        fontFamily: 'Roboto',
      ),
      home: const LoginPage(),
    );
  }
}


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final VisualMathApi api = VisualMathApi();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;
  String errorText = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      setState(() => errorText = 'Email dan kata sandi wajib diisi.');
      return;
    }

    setState(() {
      isLoading = true;
      errorText = '';
    });

    try {
      await api.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = e.response?.statusCode == 401
            ? 'Login gagal. Periksa email dan kata sandi.'
            : 'Tidak dapat login. Periksa koneksi atau server.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => errorText = 'Terjadi kesalahan saat login.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login VisualMath AI'),
        backgroundColor: Colors.white,
        foregroundColor: darkNavy,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 35),
            const Icon(
              Icons.functions_rounded,
              size: 72,
              color: primaryBlue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Selamat Datang!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkNavy,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Login untuk mulai belajar matematika bersama AI.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Kata sandi',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (errorText.isNotEmpty) ...[
              Text(
                errorText,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(
                  isLoading ? 'Sedang login...' : 'Login',
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Belum punya akun?'),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterPage(),
                      ),
                    );
                  },
                  child: const Text('Daftar sekarang'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  void showFeature(String feature) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FeaturePage(title: feature),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: [
            buildHome(),
            const SimplePage(
              icon: Icons.edit_note_rounded,
              title: 'Latihan Soal',
              subtitle: 'Asah kemampuan kalkulusmu sedikit demi sedikit.',
            ),
            const SimplePage(
              icon: Icons.history_rounded,
              title: 'Riwayat Belajar',
              subtitle: 'Aktivitas belajar akan muncul di sini.',
            ),
            const SimplePage(
              icon: Icons.person_outline_rounded,
              title: 'Profil Saya',
              subtitle: 'Informasi akun mahasiswa.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: lightBlue,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Latihan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget buildHome() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.functions_rounded,
                      color: Colors.white,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VisualMath AI',
                          style: TextStyle(
                            color: darkNavy,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Belajar Kalkulus, Lebih Mudah',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => showFeature('Notifikasi'),
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: darkNavy,
                      size: 27,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Halo, Mahasiswa! 👋',
                style: TextStyle(
                  color: darkNavy,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Yuk, pahami matematika satu langkah '
                'demi satu langkah. Kamu pasti bisa!',
                style: TextStyle(
                  color: Color(0xFF687991),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3988FF), Color(0xFF2465DD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✨ TEMAN BELAJAR AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Matematika terasa sulit?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tanyakan soalmu dan pelajari '
                      'langkah penyelesaiannya.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: () => showFeature('AI Math Explainer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryBlue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 19,
                        ),
                        label: const Text(
                          'Mulai Belajar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionTitle(
                title: 'Ringkasan Belajar',
                subtitle: 'Perjalananmu',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.menu_book_rounded,
                      iconColor: primaryBlue,
                      iconBackground: lightBlue,
                      value: 'Mulai',
                      label: 'Materi kuliah',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.track_changes_rounded,
                      iconColor: Color(0xFF159D83),
                      iconBackground: Color(0xFFE3F8F1),
                      value: 'Belajar',
                      label: 'Target harian',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const SectionTitle(
                title: 'Mau Belajar Apa?',
                subtitle: 'Pilih fitur',
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  FeatureCard(
                    icon: Icons.smart_toy_rounded,
                    title: 'AI Math Explainer',
                    description: 'Tanya soal matematika',
                    color: primaryBlue,
                    background: lightBlue,
                    onTap: () => showFeature('AI Math Explainer'),
                  ),
                  FeatureCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Latihan Soal',
                    description: 'Uji pemahamanmu',
                    color: Color(0xFF159D83),
                    background: Color(0xFFE3F8F1),
                    onTap: () => setState(() => selectedIndex = 1),
                  ),
                  FeatureCard(
                    icon: Icons.show_chart_rounded,
                    title: 'Grafik Interaktif',
                    description: 'Jelajahi grafik fungsi',
                    color: Color(0xFF7458DB),
                    background: Color(0xFFF0EBFF),
                    onTap: () => showFeature('Grafik Interaktif'),
                  ),
                  FeatureCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Scan Soal',
                    description: 'Foto soalmu',
                    color: Color(0xFFE38B24),
                    background: Color(0xFFFFF2DE),
                    onTap: () => showFeature('Scan Soal'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const SectionTitle(
                title: 'Aktivitas Terbaru',
                subtitle: 'Perjalanan belajarmu',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFFEAF0FA)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: primaryBlue,
                      size: 25,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aktivitas belajarmu akan tampil di sini '
                        'setelah fitur riwayat dihubungkan.',
                        style: TextStyle(
                          color: Color(0xFF687991),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: darkNavy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF8190A7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFEAF0FA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: darkNavy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8190A7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0xFFEAF0FA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkNavy,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF8190A7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SimplePage extends StatelessWidget {
  const SimplePage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(icon, color: primaryBlue, size: 43),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: darkNavy,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF687991),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
  

class FeaturePage extends StatefulWidget {
  final String title;

  const FeaturePage({
    super.key,
    required this.title,
  });

  @override
  State<FeaturePage> createState() => _FeaturePageState();
}

class _FeaturePageState extends State<FeaturePage> {
  final VisualMathApi api = VisualMathApi();
  final TextEditingController questionController =
      TextEditingController();

  bool isLoading = false;
  String? resultText;
  String? errorText;

  bool get isMathExplainer => widget.title == 'AI Math Explainer';

  @override
  void dispose() {
    questionController.dispose();
    super.dispose();
  }

  Future<void> analyzeQuestion() async {
    final expression = questionController.text.trim();

    if (expression.isEmpty) {
      setState(() {
        errorText = 'Masukkan ekspresi matematika terlebih dahulu.';
        resultText = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      errorText = null;
      resultText = null;
    });

    try {
      final result = await api.analyzeFormula(expression);

      if (!mounted) return;

      setState(() {
        resultText = const JsonEncoder.withIndent('  ').convert(result);
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        final statusCode = e.response?.statusCode;

        if (statusCode == 401 || statusCode == 403) {
          errorText =
              'Akses ditolak atau sesi tidak valid. Silakan login kembali.';
        } else if (e.response != null) {
          errorText =
              'Server gagal memproses ekspresi (HTTP $statusCode).';
        } else {
          errorText =
              'Tidak dapat terhubung ke server. Periksa koneksi internet.';
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorText = 'Terjadi kesalahan saat membaca respons server.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String get featureDescription {
    switch (widget.title) {
      case 'Grafik Interaktif':
        return 'Fitur grafik akan tersedia setelah mesin grafik terhubung.';
      case 'Scan Soal':
        return 'Fitur pemindaian soal akan tersedia setelah integrasi kamera dan OCR.';
      case 'Notifikasi':
        return 'Notifikasi akan ditampilkan setelah layanan notifikasi terhubung.';
      case 'Latihan Soal':
        return 'Latihan soal akan tersedia setelah materi dan layanan latihan terhubung.';
      default:
        return 'Fitur ini belum terhubung ke layanan backend.';
    }
  }

  IconData get featureIcon {
    switch (widget.title) {
      case 'Grafik Interaktif':
        return Icons.show_chart_rounded;
      case 'Scan Soal':
        return Icons.camera_alt_rounded;
      case 'Notifikasi':
        return Icons.notifications_none_rounded;
      case 'Latihan Soal':
        return Icons.edit_note_rounded;
      default:
        return Icons.construction_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: darkNavy,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (isMathExplainer) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: primaryBlue,
                      size: 34,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Math Explainer',
                            style: TextStyle(
                              color: darkNavy,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Masukkan ekspresi matematika untuk dikirim ke server.',
                            style: TextStyle(
                              color: Color(0xFF687991),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Ekspresi Matematika',
                style: TextStyle(
                  color: darkNavy,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: questionController,
                enabled: !isLoading,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!isLoading) {
                    analyzeQuestion();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Contoh: x^2 + 3*x',
                  helperText:
                      'Masukkan ekspresi yang didukung oleh backend.',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E8F5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : analyzeQuestion,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    isLoading ? 'Memproses...' : 'Proses Ekspresi',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    errorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              if (resultText != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Respons Backend',
                  style: TextStyle(
                    color: darkNavy,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE0E8F5),
                    ),
                  ),
                  child: SelectableText(
                    resultText!,
                    style: const TextStyle(
                      color: darkNavy,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: lightBlue,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          featureIcon,
                          size: 42,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: darkNavy,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        featureDescription,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF687991),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final VisualMathApi api = VisualMathApi();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final nimController = TextEditingController();
  final prodiController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String role = 'mahasiswa';
  String errorText = '';
  String successText = '';
  bool isLoading = false;
  bool isPasswordVisible = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    nimController.dispose();
    prodiController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty ||
        password.isEmpty || confirmPassword.isEmpty) {
      setState(() => errorText = 'Lengkapi semua kolom wajib.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => errorText = 'Konfirmasi kata sandi tidak cocok.');
      return;
    }

    setState(() {
      isLoading = true;
      errorText = '';
      successText = '';
    });

    try {
      await api.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        role: role,
        nim: nimController.text,
        prodi: prodiController.text,
      );

      if (!mounted) return;

      setState(() {
        successText =
            'Pendaftaran berhasil. Silakan kembali dan login.';
      });
    } on DioException catch (e) {
      if (!mounted) return;

      final data = e.response?.data;
      setState(() {
        if (data is Map && data['error'] != null) {
          errorText = data['error'].toString();
        } else if (e.response != null) {
          errorText = 'Pendaftaran gagal (HTTP ${e.response?.statusCode}).';
        } else {
          errorText = 'Tidak dapat terhubung ke server.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => errorText = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar VisualMath AI'),
        backgroundColor: Colors.white,
        foregroundColor: darkNavy,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.person_add_alt_1_rounded,
              size: 64,
              color: primaryBlue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Buat Akun Baru',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkNavy,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama lengkap *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: const InputDecoration(
                labelText: 'Peran pengguna',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'mahasiswa',
                  child: Text('Mahasiswa'),
                ),
                DropdownMenuItem(
                  value: 'dosen',
                  child: Text('Dosen'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => role = value);
                }
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nimController,
              decoration: const InputDecoration(
                labelText: 'NIM (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: prodiController,
              decoration: const InputDecoration(
                labelText: 'Program studi (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Kata sandi *',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi kata sandi *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            if (errorText.isNotEmpty) ...[
              Text(
                errorText,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
            ],
            if (successText.isNotEmpty) ...[
              Text(
                successText,
                style: const TextStyle(color: Colors.green),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(
                  isLoading ? 'Mendaftarkan...' : 'Daftar',
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Sudah punya akun? Login'),
            ),
          ],
        ),
      ),
    );
  }
}

