import 'package:acervo360/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: const Text(
          'Política de Privacidade',
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
              '1. Introdução',
              'A privacidade dos usuários é considerada de suma importância para a Acervo 360. A presente Política de Privacidade tem por objetivo estabelecer, em conformidade com a legislação vigente, os termos e condições pelos quais são coletadas, utilizadas, compartilhadas e protegidas as informações pessoais dos usuários do aplicativo da Acervo 360.',
            ),
            _buildSection(
              colors,
              '2. Coleta de Informações',
              '',
              children: [
                _buildSubSection(colors, '2.1 Informações Pessoais', 
                  'Poderemos proceder à coleta das seguintes informações pessoais dos usuários:'),
                _buildBulletPoint(colors, 'Nome completo'),
                _buildBulletPoint(colors, 'Data de nascimento'),
                _buildBulletPoint(colors, 'Endereço de correio eletrônico (e-mail)'),
                _buildBulletPoint(colors, 'Número de telefone'),
                _buildBulletPoint(colors, 'Foto'),
                const SizedBox(height: 16),
                _buildSubSection(colors, '2.2 Informações de Equipamentos', 
                  'Poderemos também coletar informações relativas aos equipamentos dos usuários, incluindo, mas não se limitando a:'),
                _buildBulletPoint(colors, 'Histórico de Gtes'),
                _buildBulletPoint(colors, 'Detalhes concernentes aos equipamentos e Gtes'),
                _buildBulletPoint(colors, 'Cadastro de Clubes de Tiro'),
                const SizedBox(height: 8),
                Text(
                  'E quaisquer dados adicionais que estejam no aplicativo.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 16),
                _buildSubSection(colors, '2.3 Informações Coletadas Automaticamente', 
                  'Podemos coletar informações automaticamente quando o usuário utiliza o aplicativo, incluindo:'),
                _buildBulletPoint(colors, 'Endereço IP'),
                _buildBulletPoint(colors, 'Dados de geolocalização'),
                _buildBulletPoint(colors, 'Informações sobre o dispositivo (tipo, sistema operacional, identificador do dispositivo)'),
                _buildBulletPoint(colors, 'Dados de uso do aplicativo'),
                _buildBulletPoint(colors, 'Cookies e tecnologias similares, para aprimorar a experiência do usuário e personalizar os serviços oferecidos'),
              ],
            ),
            _buildSection(
              colors,
              '3. Uso das Informações',
              'As informações coletadas dos usuários serão utilizadas para os seguintes propósitos:',
              children: [
                _buildBulletPoint(colors, 'Gerenciamento de registros de equipamentos pessoais dos usuários'),
                _buildBulletPoint(colors, 'Guias de Tráfego e Competições'),
                _buildBulletPoint(colors, 'Envio de notificações de lembrete para vencimentos de documentos'),
                _buildBulletPoint(colors, 'Aperfeiçoamento dos serviços oferecidos pelo aplicativo, incluindo a análise de dados visando à otimização das funcionalidades e da experiência dos usuários'),
                _buildBulletPoint(colors, 'Análise e pesquisa para desenvolvimento de novos serviços e funcionalidades'),
                _buildBulletPoint(colors, 'Cumprimento de obrigações legais e regulatórias'),
                _buildBulletPoint(colors, 'Marketing direto, mediante consentimento do usuário, para informar sobre novidades e serviços relevantes da Acervo 360 e parceiros comerciais'),
              ],
            ),
            _buildSection(
              colors,
              '4. Compartilhamento de\n Informações',
              '',
              children: [
                _buildSubSection(colors, '4.1 Com Terceiros', 
                  'As informações pessoais dos usuários não serão compartilhadas com terceiros, salvo nas seguintes hipóteses:'),
                _buildBulletPoint(colors, 'Quando necessário para a prestação dos serviços solicitados pelo usuário'),
                _buildBulletPoint(colors, 'Quando exigido por força de lei ou em resposta a processos judiciais ou administrativos'),
                _buildBulletPoint(colors, 'Para proteção de direitos, propriedade e segurança da Acervo 360, dos usuários e de terceiros'),
                _buildBulletPoint(colors, 'Com parceiros comerciais, para fins de personalização de ofertas e promoções, desde que o usuário tenha concedido consentimento nesta política de privacidade'),
                const SizedBox(height: 16),
                _buildSubSection(colors, '4.2 Com Prestadores de Serviços', 
                  'Poderemos compartilhar informações pessoais dos usuários com prestadores de serviços terceirizados que auxiliem na operação do aplicativo, tais como provedores de hospedagem e serviços de análise de dados, desde que tais prestadores de serviços concordem em manter a confidencialidade das informações e utilizá-las exclusivamente para os fins determinados por nós.'),
              ],
            ),
            _buildSection(
              colors,
              '5. Bases Legais para o Tratamento\n de Dados',
              'A coleta e o tratamento das informações pessoais dos usuários são realizados com base nas seguintes fundamentações legais:',
              children: [
                _buildBulletPoint(colors, 'Consentimento: Obtemos o consentimento específico dos usuários para a coleta de informações de equipamentos e outros dados sensíveis'),
                _buildBulletPoint(colors, 'Execução de contrato: Quando o tratamento das informações é necessário para a prestação dos serviços solicitados'),
                _buildBulletPoint(colors, 'Cumprimento de obrigação legal ou regulatória: Quando o tratamento for necessário para o cumprimento de obrigações legais ou regulatórias'),
                _buildBulletPoint(colors, 'Legítimo interesse: Quando o tratamento for necessário para atender a interesses legítimos da Acervo 360, desde que não prevaleçam os interesses ou direitos e liberdades fundamentais dos usuários'),
              ],
            ),
            _buildSection(
              colors,
              '6. Segurança das Informações',
              'Implementamos medidas de segurança técnicas e administrativas para proteger as informações dos usuários contra acesso não autorizado, alteração, divulgação ou destruição. Tais medidas incluem a criptografia durante a transmissão de dados, controles de acesso restrito e autenticação em duas etapas, com o objetivo de assegurar a integridade e a confidencialidade dos dados. Não obstante, reconhecemos que nenhum método de transmissão pela Internet ou armazenamento eletrônico é absolutamente seguro e infalível.',
            ),
            _buildSection(
              colors,
              '7. Retenção de Dados',
              'As informações pessoais dos usuários serão retidas pelo período necessário para a consecução dos propósitos descritos nesta Política de Privacidade, salvo se um prazo de retenção mais longo for exigido ou permitido pela legislação aplicável. O usuário poderá solicitar a exclusão de seus dados pessoais a qualquer momento, sujeito às restrições legais ou regulatórias.',
            ),
            _buildSection(
              colors,
              '8. Direitos dos Usuários',
              'Os usuários possuem os seguintes direitos em relação às suas informações pessoais:',
              children: [
                _buildBulletPoint(colors, 'Acessar suas informações pessoais, mediante requisição formal'),
                _buildBulletPoint(colors, 'Solicitar a correção de informações incorretas, inexatas ou incompletas'),
                _buildBulletPoint(colors, 'Requerer a exclusão de suas informações pessoais, observadas as exceções previstas em lei'),
                _buildBulletPoint(colors, 'Retirar o consentimento previamente concedido para o uso de suas informações pessoais, sem prejuízo da legalidade do tratamento realizado antes da retirada do consentimento'),
                _buildBulletPoint(colors, 'Solicitar informações sobre as entidades públicas e privadas com as quais realizamos o uso compartilhado de dados'),
                _buildBulletPoint(colors, 'Solicitar a eliminação de dados em desconformidade com a legislação aplicável'),
                const SizedBox(height: 12),
                Text(
                  'Para exercer quaisquer dos direitos acima descritos, os usuários deverão entrar em contato conosco por meio das informações de contato disponibilizadas na Seção 10 desta Política de Privacidade.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 15),
                ),
              ],
            ),
            _buildSection(
              colors,
              '9. Alterações na Política de\n Privacidade',
              'Reservamo-nos o direito de atualizar a presente Política de Privacidade periodicamente, conforme necessário, para refletir eventuais alterações nos nossos serviços ou no cumprimento de requisitos legais e regulatórios.',
            ),
            _buildSection(
              colors,
              '10. Contato',
              'Caso o usuário tenha quaisquer dúvidas, comentários ou preocupações relacionadas a esta Política de Privacidade, poderá entrar em contato conosco através do seguinte endereço de e-mail:',
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
              '11. Foro',
              'Fica eleito o foro da Comarca de Belo Horizonte, Minas Gerais, como competente para dirimir quaisquer litígios ou controvérsias oriundas do presente Termo de Uso e da Política de Privacidade, com renúncia expressa a qualquer outro, por mais privilegiado que seja.',
            ),
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png', // Assuming there's a logo
                    width: 60,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.security_rounded,
                      size: 40,
                      color: colors.textMuted.withValues(alpha: 0.5),
                    ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accent,
            colors.accent.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Política de Privacidade',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seus dados protegidos e tratados com transparência em conformidade com a LGPD.',
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

  Widget _buildSubSection(AppColors colors, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBulletPoint(AppColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
