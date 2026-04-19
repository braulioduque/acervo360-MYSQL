import 'package:acervo360/pages/register_screen.dart';
import 'package:acervo360/pages/welcome_screen.dart';
import 'package:acervo360/theme/app_theme.dart';
import 'package:flutter/material.dart';

class TermsOfUsePage extends StatelessWidget {
  final bool showButtons;

  const TermsOfUsePage({
    super.key,
    this.showButtons = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: const Text(
          'Termos de Uso',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        backgroundColor: colors.scaffold,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
            const SizedBox(height: 32),
            _buildSection(
              colors,
              '1. Aceitação dos Termos',
              'Ao acessar ou utilizar o aplicativo ACERVO360, o usuário concorda em estar vinculado aos termos e condições estabelecidos neste Termo de Uso, bem como à Política de Privacidade aqui incorporada por referência. Caso o usuário não concorde com quaisquer dos termos aqui estipulados, deve abster-se de utilizar o aplicativo.',
            ),
            _buildSection(
              colors,
              '2. Licença de Uso',
              'A Acervo 360 concede ao usuário uma licença limitada, não exclusiva e intransferível para utilizar o aplicativo, exclusivamente para fins pessoais e não comerciais. O usuário concorda em não reproduzir, modificar, distribuir, vender, alugar ou explorar de qualquer outra forma o aplicativo ou seus conteúdos sem a autorização expressa e por escrito do Acervo 360.',
            ),
            _buildSection(
              colors,
              '3. Responsabilidades do Usuário',
              'O usuário compromete-se a utilizar o aplicativo de forma ética e legal, abstendo-se de utilizar o aplicativo para quaisquer atividades ilícitas, fraudulentas, abusivas ou que violem direitos de terceiros. O usuário também é responsável pela veracidade e precisão das informações fornecidas a Acervo 360 durante o uso do aplicativo. O usuário deverá manter a confidencialidade de suas credenciais de acesso e comunicar imediatamente à Acervo 360 qualquer uso não autorizado de sua conta.',
            ),
            _buildSection(
              colors,
              '4. Modificações no Aplicativo',
              'A Acervo 360 se reserva o direito de, a qualquer momento e sem aviso prévio, modificar ou descontinuar, temporária ou permanentemente, o aplicativo ou qualquer parte dele. A Acervo 360 não será responsável por quaisquer danos decorrentes de tais modificações ou descontinuações.',
            ),
            _buildSection(
              colors,
              '5. Limitação de Responsabilidade',
              'A Acervo 360 não se responsabiliza por quaisquer danos diretos, indiretos, incidentais, especiais ou consequenciais que resultem do uso ou da impossibilidade de uso do aplicativo, incluindo, mas não se limitando, à perda de dados, falhas de comunicação ou problemas técnicos. O uso do aplicativo é feito por conta e risco exclusivo do usuário.',
            ),
            _buildSection(
              colors,
              '6. Propriedade Intelectual',
              'Todos os direitos relativos ao aplicativo, incluindo, mas não se limitando a, direitos autorais, marcas, patentes e segredos comerciais, são de propriedade exclusiva da Acervo 360 ou de seus licenciadores. Nenhuma disposição deste Termo de Uso concede ao usuário qualquer direito sobre o conteúdo do aplicativo, exceto conforme estritamente permitido por este documento.',
            ),
            _buildSection(
              colors,
              '7. Proteção de Dados e Privacidade',
              'O usuário concorda que a utilização do aplicativo está sujeita também à Política de Privacidade, que descreve as práticas de coleta, uso, compartilhamento e proteção de dados pessoais, conforme descrito no documento "Política de Privacidade da Acervo 360".',
            ),
            _buildSection(
              colors,
              '8. Alterações no Termo de Uso',
              'A Acervo 360 poderá modificar este Termo de Uso periodicamente, conforme necessário. O uso contínuo do aplicativo após quaisquer modificações implica na aceitação automática dos novos termos.',
            ),
            _buildSection(
              colors,
              '9. Contato',
              'Em caso de dúvidas ou preocupações sobre este Termo de Uso, o usuário poderá entrar em contato conosco através do seguinte endereço de e-mail:',
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined, color: colors.accent, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'suporte@inforfile.com.br',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _buildSection(
              colors,
              '10. Foro',
              'Fica eleito o foro da Comarca de Belo Horizonte, Minas Gerais, como competente para dirimir quaisquer litígios ou controvérsias oriundas do presente Termo de Uso e da Política de Privacidade, com renúncia expressa a qualquer outro, por mais privilegiado que seja.',
            ),
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.gavel_rounded,
                    size: 40,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ACERVO 360',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Última atualização: 07 de Abril de 2026',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            if (showButtons) _buildActionButtons(context, colors),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppColors colors) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'ACEITAR',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomePage()),
                (route) => false,
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              side: BorderSide(color: colors.cardBorder, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'VOLTAR AO LOGIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF334155),
            const Color(0xFF1E293B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.description_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Termos de Uso',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ao utilizar o aplicativo, você concorda com as diretrizes e responsabilidades descritas neste documento.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(AppColors colors, String title, String content, {List<Widget>? children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (content.isNotEmpty)
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: colors.textSecondary,
              ),
            ),
          if (children != null) ...[
            if (content.isNotEmpty) const SizedBox(height: 12),
            ...children,
          ],
        ],
      ),
    );
  }
}
