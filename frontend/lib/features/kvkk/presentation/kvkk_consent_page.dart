import 'package:flutter/material.dart';

class KvkkConsentPage extends StatelessWidget {
  final VoidCallback onAccepted;

  const KvkkConsentPage({
    super.key,
    required this.onAccepted,
  });

  static const Color backgroundColor = Color(0xFF0D120D);
  static const Color neonGreen = Color(0xFFB6FF5B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: neonGreen,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'KVKK Aydınlatma Metni',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lütfen uygulamayı kullanmadan önce aşağıdaki metni okuyunuz.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: const SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Text(
                      '''
Bu uygulama kapsamında kullanıcıya ait ad, e-posta adresi, sera bilgileri, cihaz bilgileri ve uygulama kullanım verileri hizmetin sunulabilmesi, sistem güvenliğinin sağlanması ve kullanıcı deneyiminin iyileştirilmesi amacıyla işlenebilir.

Toplanan kişisel veriler yalnızca uygulamanın temel işlevlerini yerine getirmek, kullanıcı doğrulama süreçlerini yürütmek, sera izleme verilerini göstermek, bildirim hizmetlerini sunmak ve gerekli durumlarda teknik destek sağlamak amacıyla kullanılacaktır.

Kullanıcı verileri, ilgili mevzuata uygun şekilde korunur ve gerekli teknik/idari tedbirler alınır. Veriler, açık rıza veya hukuki yükümlülük bulunmadıkça üçüncü kişilerle paylaşılmaz.

Kullanıcı, dilediği zaman kişisel verilerine ilişkin bilgi talep etme, düzeltilmesini isteme, silinmesini talep etme ve işlenmesine itiraz etme hakkına sahiptir.

Bu metni onaylayarak, kişisel verilerinizin yukarıda açıklanan kapsamda işlenmesi konusunda bilgilendirildiğinizi kabul etmiş olursunuz.
''',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.7,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: neonGreen.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: neonGreen, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Devam edebilmek için metni okuduğunuzu ve anladığınızı onaylamanız gerekmektedir.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAccepted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Okudum ve Anladım',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}