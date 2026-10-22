
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
      home: const HomePage(),
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
  const FeaturePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<FeaturePage> createState() => _FeaturePageState();
}

class _FeaturePageState extends State<FeaturePage> {
  // Satu instance dipakai untuk login dan mengirim soal,
  // supaya cookie sesi yang sama tetap digunakan.
  final VisualMathApi api = VisualMathApi();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final questionController = TextEditingController();

  bool isLoggedIn = false;
  bool isLoading = false;
  String resultText = '';
  String errorText = '';
  bool isPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    questionController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        errorText = 'Email dan kata sandi wajib diisi.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorText = '';
      resultText = '';
    });

    try {
      await api.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        isLoggedIn = true;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        errorText = e.response?.statusCode == 401
            ? 'Login gagal. Periksa email dan kata sandi.'
            : 'Tidak dapat login. Periksa koneksi atau server.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorText = 'Terjadi kesalahan saat login.';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> analyzeQuestion() async {
    final question = questionController.text.trim();

    if (question.isEmpty) {
      setState(() {
        errorText = 'Masukkan soal terlebih dahulu.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorText = '';
      resultText = '';
    });

    try {
      final result = await api.analyzeFormula(question);

      if (!mounted) return;

      setState(() {
        resultText = const JsonEncoder.withIndent('  ').convert(result);
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        if (e.response?.statusCode == 401) {
          errorText = 'Sesi login tidak valid. Silakan login kembali.';
          isLoggedIn = false;
        } else {
          errorText =
              'Soal belum berhasil diproses. Periksa koneksi dan format soal.';
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorText = 'Terjadi kesalahan saat memproses soal.';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
            Text(
              isLoggedIn ? widget.title : 'Login VisualMath AI',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkNavy,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isLoggedIn
                  ? 'Masukkan ekspresi matematika untuk dianalisis.'
                  : 'Login menggunakan akun website VisualMath AI.',
              style: const TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 20),

            if (!isLoggedIn) ...[
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
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Kata sandi',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                      ),
                    onPressed: () {
                      setState(() {isPasswordVisible = !isPasswordVisible;});
                      },
                      ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Text(isLoading ? 'Sedang login...' : 'Login'),
                ),
              ),
            ] else ...[
              TextField(
                controller: questionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Soal matematika',
                  hintText: 'Contoh: x^2 + 3*x',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : analyzeQuestion,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    isLoading ? 'Sedang memproses...' : 'Pelajari Soal',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],

            if (errorText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                errorText,
                style: const TextStyle(color: Colors.red),
              ),
            ],

            if (resultText.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Respons dari server',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkNavy,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEAF0FA)),
                ),
                child: SelectableText(
                  resultText,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
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
