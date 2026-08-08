import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Política de privacidade (conteúdo estático) - descreve, em linguagem
/// simples, quais dados o Digital 360 coleta e por quê.
class PrivacidadeScreen extends StatelessWidget {
  const PrivacidadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de Privacidade')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Secao(
            titulo: 'O que coletamos',
            texto:
                'Nome de usuário, nome completo, nome de exibição e CPF (para validar sua '
                'identidade), além do progresso nos cursos e o histórico de serviços e cursos '
                'que você acessa no app.',
          ),
          _Secao(
            titulo: 'Por que coletamos',
            texto:
                'Seu progresso alimenta as recomendações personalizadas e a gamificação. O CPF '
                'serve só para validar seu cadastro - não é compartilhado com terceiros nem '
                'usado para nenhuma outra finalidade.',
          ),
          _Secao(
            titulo: 'Com quem compartilhamos',
            texto:
                'Se você criar um curso como tutor ou perguntar no fórum, seu nome de exibição '
                'fica visível para outros usuários da comunidade. Nenhum outro dado pessoal '
                '(CPF, nome completo, senha) é exibido a outros usuários em nenhuma tela.',
          ),
          _Secao(
            titulo: 'Modo cuidador',
            texto:
                'Se alguém se vincular a você como cuidador usando seu nome de usuário como '
                'código, essa pessoa passa a ver um resumo do seu progresso (cursos concluídos '
                'e sequência de uso) - nada além disso, e ela nunca pode agir em seu nome.',
          ),
          _Secao(
            titulo: 'Seus direitos',
            texto:
                'Você pode editar seu nome de exibição a qualquer momento em Perfil, e excluir '
                'sua conta e seus dados quando quiser, também em Perfil. Cursos que você '
                'publicou como tutor continuam disponíveis para quem já os estuda, mas deixam '
                'de estar associados ao seu nome.',
          ),
          _Secao(
            titulo: 'Armazenamento',
            texto:
                'Sua senha nunca é armazenada em texto puro (usamos hash). O token de acesso '
                'da sua sessão fica no armazenamento seguro do seu dispositivo (Keystore/'
                'Keychain), não em um arquivo comum.',
          ),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  final String texto;
  const _Secao({required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(texto, style: const TextStyle(color: AppColors.onSurface, height: 1.4)),
        ],
      ),
    );
  }
}
