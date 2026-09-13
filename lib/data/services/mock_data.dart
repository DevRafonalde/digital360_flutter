import '../models/curso.dart';
import '../models/servico.dart';
import '../models/usuario.dart';
import '../models/pedido_logistico.dart';

/// Dados simulados para o app rodar sem backend (avaliacao / demo).
/// Coordenadas reais de Sao Paulo para a tela de mapas.
class MockData {
  static Usuario usuario(String nomeUser) => Usuario(
        id: 1,
        nomeAmigavel: nomeUser.isEmpty ? 'Visitante' : nomeUser,
        nomeUser: nomeUser,
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
      );

  static List<Curso> cursos() => [
        Curso(
          id: 1,
          titulo: 'Primeiros passos no celular',
          descricao: 'Aprenda a usar o smartphone com segurança e confiança.',
          nivel: 'BASICO',
          cargaHoraria: 4,
          totalModulos: 6,
          progresso: 75,
          topicosModulos: const [
            'Ligando e desligando o celular',
            'Conhecendo a tela inicial',
            'Conectando ao Wi-Fi',
            'Fazendo e recebendo chamadas',
            'Enviando mensagens de texto',
            'Cuidando da bateria e da segurança do aparelho',
          ],
        ),
        Curso(
          id: 2,
          titulo: 'Usando o gov.br',
          descricao: 'Acesse serviços públicos digitais sem complicação.',
          nivel: 'INTERMEDIARIO',
          cargaHoraria: 6,
          totalModulos: 8,
          progresso: 30,
          topicosModulos: const [
            'O que é o gov.br e para que serve',
            'Criando sua conta gov.br',
            'Fazendo login com CPF e senha',
            'Consultando seus benefícios do INSS',
            'Agendando atendimento no INSS',
            'Emitindo documentos (CPF, CNH digital)',
            'Acompanhando protocolos e solicitações',
            'Pedindo ajuda quando algo não funciona',
          ],
        ),
        Curso(
          id: 3,
          titulo: 'Segurança digital e golpes',
          descricao: 'Identifique fraudes e proteja seus dados pessoais.',
          nivel: 'INTERMEDIARIO',
          cargaHoraria: 5,
          totalModulos: 7,
          progresso: 0,
          topicosModulos: const [
            'Como reconhecer uma mensagem falsa',
            'O golpe do falso parente em emergência',
            'Cuidado com links e QR codes desconhecidos',
            'Protegendo sua senha e seus dados pessoais',
            'O golpe do falso funcionário do banco',
            'Verificando se um site é seguro',
            'O que fazer se você caiu em um golpe',
          ],
        ),
        Curso(
          id: 4,
          titulo: 'Pix e pagamentos digitais',
          descricao: 'Faça transferências e pagamentos com tranquilidade.',
          nivel: 'AVANCADO',
          cargaHoraria: 8,
          totalModulos: 10,
          progresso: 10,
          topicosModulos: const [
            'O que é o Pix e como ele funciona',
            'Cadastrando sua chave Pix',
            'Fazendo seu primeiro Pix',
            'Recebendo dinheiro por Pix',
            'Conferindo o comprovante da transação',
            'Cuidados antes de confirmar um pagamento',
            'Golpes comuns envolvendo o Pix',
            'Pagando contas e boletos pelo celular',
            'Usando cartão de débito e crédito com segurança',
            'O que fazer se você caiu em um golpe com Pix',
          ],
        ),
      ];

  /// Conteudo didatico de cada modulo, por curso e por titulo do topico -
  /// texto curto e direto, pensado pro publico com baixo letramento digital
  /// (frases curtas, linguagem simples, tom encorajador).
  static String conteudoModulo(int cursoId, String topico) {
    return _conteudosModulos[cursoId]?[topico] ??
        'Conteúdo deste módulo em preparação. Toque em "Concluir módulo" para avançar mesmo assim.';
  }

  static final Map<int, Map<String, String>> _conteudosModulos = {
    1: {
      'Ligando e desligando o celular':
          'Para ligar, segure o botão lateral por alguns segundos até a tela acender. '
          'Para desligar, segure o mesmo botão e toque em "Desligar" na tela que aparecer. '
          'Se o celular travar, segure o botão por mais tempo até ele reiniciar sozinho.',
      'Conhecendo a tela inicial':
          'Na tela inicial ficam os ícones dos aplicativos (os "quadradinhos" com desenhos). '
          'Toque uma vez com o dedo para abrir um aplicativo. '
          'O botão de "voltar" ou o gesto de deslizar da borda ajuda a sair de onde você está.',
      'Conectando ao Wi-Fi':
          'Vá em Configurações e toque em "Wi-Fi". '
          'Escolha o nome da sua rede na lista e digite a senha quando pedir. '
          'Uma vez conectado, o celular lembra a senha e conecta sozinho da próxima vez.',
      'Fazendo e recebendo chamadas':
          'Abra o aplicativo de telefone (ícone de um telefone verde) e toque no contato ou digite o número. '
          'Para atender uma ligação, deslize o círculo verde. Para recusar, deslize o vermelho. '
          'Você pode aumentar o volume da chamada com os botões na lateral do celular.',
      'Enviando mensagens de texto':
          'Abra o aplicativo de mensagens ou o WhatsApp e toque no contato desejado. '
          'Digite o texto no campo de baixo e toque na seta para enviar. '
          'Você também pode gravar um áudio segurando o ícone do microfone, se preferir falar em vez de digitar.',
      'Cuidando da bateria e da segurança do aparelho':
          'Carregue o celular sempre que possível, sem esperar chegar a 0%. '
          'Configure uma senha ou desenho de desbloqueio em Configurações para proteger seus dados. '
          'Evite emprestar o celular desbloqueado e nunca compartilhe sua senha com estranhos.',
    },
    2: {
      'O que é o gov.br e para que serve':
          'O gov.br é o portal único do governo para acessar serviços públicos pela internet. '
          'Por ele dá para consultar benefícios do INSS, tirar documentos e agendar atendimentos, sem sair de casa. '
          'Ter uma conta gov.br é como ter uma "chave" que abre vários serviços do governo de uma vez.',
      'Criando sua conta gov.br':
          'Acesse o site ou app gov.br e toque em "Criar conta". '
          'Informe seu CPF e alguns dados pessoais para confirmar quem você é. '
          'Guarde a senha escolhida em um lugar seguro — ela será usada em todos os serviços do governo.',
      'Fazendo login com CPF e senha':
          'Na tela de entrada, digite seu CPF e a senha cadastrada. '
          'Se esquecer a senha, toque em "Esqueci minha senha" para criar uma nova. '
          'Nunca digite sua senha do gov.br em links recebidos por mensagem — só no site ou app oficial.',
      'Consultando seus benefícios do INSS':
          'Dentro do gov.br, procure por "Meu INSS". '
          'Lá você vê o valor do seu benefício, a data do próximo pagamento e o extrato de pagamentos anteriores. '
          'Também dá para saber se algum documento está pendente de envio.',
      'Agendando atendimento no INSS':
          'No Meu INSS, toque em "Agendamentos" e escolha o serviço que precisa. '
          'Selecione a agência mais perto de você e o melhor dia e horário disponíveis. '
          'Você recebe a confirmação na tela e pode consultar de novo sempre que quiser.',
      'Emitindo documentos (CPF, CNH digital)':
          'O gov.br permite ver e baixar documentos digitais, como CPF e CNH. '
          'Procure pelo nome do documento na busca do aplicativo. '
          'O documento digital tem a mesma validade do documento físico e pode ser mostrado direto no celular.',
      'Acompanhando protocolos e solicitações':
          'Todo pedido feito no gov.br gera um número de protocolo. '
          'Guarde esse número — com ele dá para consultar o andamento do seu pedido a qualquer momento. '
          'Em "Meus pedidos" ficam listadas todas as solicitações que você já fez.',
      'Pedindo ajuda quando algo não funciona':
          'Se algo não funcionar, o próprio gov.br tem uma "Central de Atendimento" com perguntas frequentes. '
          'Você também pode ligar para o telefone 135 (INSS) para falar com uma pessoa de verdade. '
          'Nunca pague para "agilizar" um serviço público — esses serviços são sempre gratuitos.',
    },
    3: {
      'Como reconhecer uma mensagem falsa':
          'Desconfie de mensagens com erros de português, urgência exagerada ou promessas boas demais. '
          'Bancos e órgãos públicos nunca pedem senha ou código por mensagem. '
          'Na dúvida, não responda nem clique em nada — ligue direto para o número oficial da empresa.',
      'O golpe do falso parente em emergência':
          'É comum receber uma mensagem dizendo ser um filho ou neto "com o número novo", pedindo dinheiro com urgência. '
          'Antes de fazer qualquer pagamento, ligue para a pessoa no número antigo que você já conhece. '
          'Combine com a família uma "palavra secreta" para confirmar pedidos de emergência.',
      'Cuidado com links e QR codes desconhecidos':
          'Não clique em links recebidos de números desconhecidos, mesmo que pareçam de bancos ou lojas. '
          'QR codes também podem levar a páginas falsas — só escaneie os que você mesmo gerou ou reconhece a origem. '
          'Se tiver dúvida sobre um link, apague a mensagem sem abrir.',
      'Protegendo sua senha e seus dados pessoais':
          'Nunca compartilhe suas senhas, mesmo com quem diz ser "do banco" ou "do governo". '
          'Use senhas diferentes para aplicativos diferentes, se possível. '
          'Guarde documentos como CPF e RG apenas em locais seguros, sem tirar foto e enviar por mensagem sem necessidade.',
      'O golpe do falso funcionário do banco':
          'Golpistas ligam se passando por funcionários do banco, avisando de uma "compra suspeita". '
          'O banco de verdade nunca pede para você transferir dinheiro para uma "conta segura". '
          'Desconfie e desligue — depois ligue você mesmo para o número oficial do banco, escrito no cartão.',
      'Verificando se um site é seguro':
          'Sites seguros começam com "https://" e mostram um cadeado ao lado do endereço. '
          'Confira se o nome do site está escrito corretamente, sem letras trocadas. '
          'Evite fazer compras ou digitar dados pessoais em sites que você não conhece.',
      'O que fazer se você caiu em um golpe':
          'Não sinta vergonha — isso acontece com muita gente e quanto mais rápido agir, melhor. '
          'Ligue imediatamente para o seu banco para bloquear a conta ou o cartão. '
          'Registre um Boletim de Ocorrência (pode ser feito online) e avise seus familiares.',
    },
    4: {
      'O que é o Pix e como ele funciona':
          'O Pix é uma forma de transferir dinheiro na hora, a qualquer horário, sem taxa para pessoas físicas. '
          'Funciona pelo aplicativo do seu banco, usando uma "chave" que identifica a conta de destino. '
          'É mais rápido que TED ou DOC e funciona todos os dias, inclusive fins de semana.',
      'Cadastrando sua chave Pix':
          'No aplicativo do banco, procure por "Pix" e depois "Minhas chaves". '
          'Você pode cadastrar seu CPF, e-mail, celular ou uma chave aleatória. '
          'Escolha uma chave fácil de lembrar para quem for te enviar dinheiro, como o celular.',
      'Fazendo seu primeiro Pix':
          'No app do banco, toque em "Pix" e depois em "Transferir". '
          'Digite a chave da pessoa que vai receber, confira o nome que aparece na tela e o valor. '
          'Sempre confira o nome antes de confirmar — se o nome não bater, cancele a operação.',
      'Recebendo dinheiro por Pix':
          'Para receber, basta informar sua chave Pix (CPF, celular, e-mail) para quem vai te pagar. '
          'O dinheiro cai na sua conta em poucos segundos. '
          'Você recebe uma notificação no celular confirmando o recebimento.',
      'Conferindo o comprovante da transação':
          'Depois de qualquer Pix, o aplicativo gera um comprovante. '
          'Guarde ou tire print desse comprovante, principalmente em compras. '
          'O comprovante mostra data, valor e para quem foi feita a transferência.',
      'Cuidados antes de confirmar um pagamento':
          'Sempre confira o nome de quem vai receber antes de tocar em "Confirmar". '
          'Desconfie se alguém pedir pressa para você fazer o Pix. '
          'Uma vez confirmado, o Pix não tem como ser cancelado — por isso, confira com calma antes.',
      'Golpes comuns envolvendo o Pix':
          'Desconfie de vendedores que só aceitam Pix e pedem pagamento antecipado sem nota fiscal. '
          'Golpistas também criam QR codes falsos — confira sempre o valor antes de pagar. '
          'Nunca faça um Pix "para desbloquear um prêmio" ou "liberar uma encomenda".',
      'Pagando contas e boletos pelo celular':
          'No app do banco, toque em "Pagar" e depois em "Ler código de barras" ou digite o número do boleto. '
          'Confira o valor e a data de vencimento antes de confirmar o pagamento. '
          'Guarde o comprovante até ter certeza de que o pagamento foi reconhecido.',
      'Usando cartão de débito e crédito com segurança':
          'Cubra o teclado com a mão ao digitar a senha do cartão em maquininhas. '
          'Ative notificações de compra no aplicativo do banco para saber na hora se algo for cobrado. '
          'Nunca entregue seu cartão para "ajuda" de estranhos, mesmo em caixas eletrônicos.',
      'O que fazer se você caiu em um golpe com Pix':
          'Ligue imediatamente para o seu banco — existe um mecanismo chamado "Pix Alto" que pode bloquear o dinheiro em até 24h. '
          'Quanto mais rápido avisar, maior a chance de recuperar o valor. '
          'Depois, registre um Boletim de Ocorrência e guarde os comprovantes da conversa com o golpista.',
    },
  };

  /// Espelha heuristics.py::gerar_rascunho_curso do backend real - mesmo
  /// template por regra fixa (NAO IA generativa), pro modo mock e o modo
  /// real terem o mesmo comportamento de demo.
  static List<String> gerarRascunhoCurso(String titulo, String nivel) {
    final tituloNormalizado = titulo.trim().isEmpty ? 'este assunto' : titulo.trim();
    final modulos = <String>[
      'Introdução: por que aprender $tituloNormalizado',
      'Passo a passo com exemplos práticos',
      'Erros comuns e como evitá-los',
    ];
    if (nivel.toUpperCase() == 'INTERMEDIARIO' || nivel.toUpperCase() == 'AVANCADO') {
      modulos.add('Aprofundando: casos do dia a dia');
    }
    if (nivel.toUpperCase() == 'AVANCADO') {
      modulos.add('Cenários avançados e exceções');
    }
    modulos.add('Prática guiada e revisão final');
    return modulos;
  }

  /// Espelha GET /metricas/impacto do backend real - numeros da sessao mock
  /// atual (demo), rotulados honestamente como tal, nunca uma alegacao de
  /// escala real.
  static Map<String, dynamic> metricasImpacto({
    required int cursosConcluidos,
    required int cursosComunidade,
    required int perguntasForum,
  }) =>
      {
        'totalUsuarios': 1,
        'totalCursosConcluidos': cursosConcluidos,
        'totalCursosPublicados': cursos().length + cursosComunidade,
        'totalCursosComunidade': cursosComunidade,
        'totalPerguntasForum': perguntasForum,
        'observacao':
            'Números da sessão de demonstração atual (modo mock, sem backend), não uma métrica de escala real.',
      };

  static List<Servico> servicos() => [
        Servico(
          id: 1,
          titulo: 'Consultar benefício do INSS',
          descricao: 'Veja extrato e situação de aposentadoria/auxílio.',
          categoria: 'Previdência',
          orgao: 'INSS',
          conteudo:
              'Acesse o aplicativo Meu INSS, faça login com sua conta gov.br '
              'e selecione "Extrato de pagamento" para consultar seu benefício.',
        ),
        Servico(
          id: 2,
          titulo: 'Agendar consulta no SUS',
          descricao: 'Marque atendimento na unidade de saúde mais próxima.',
          categoria: 'Saúde',
          orgao: 'SUS',
          conteudo:
              'Use o app Conecte SUS ou procure a UBS do seu bairro com o '
              'Cartão Nacional de Saúde para agendar sua consulta.',
        ),
        Servico(
          id: 3,
          titulo: 'Emitir 2ª via do RG/CPF',
          descricao: 'Solicite documentos pelo portal gov.br.',
          categoria: 'Documentos',
          orgao: 'gov.br',
          conteudo:
              'No portal gov.br, busque por "2a via" do documento desejado e '
              'siga as instruções. Alguns serviços são gratuitos.',
        ),
        Servico(
          id: 4,
          titulo: 'Consultar Bolsa Família',
          descricao: 'Verifique calendário e valor do benefício.',
          categoria: 'Assistência Social',
          orgao: 'Caixa',
          conteudo:
              'Use o app Bolsa Família ou Caixa Tem para consultar o '
              'calendário de pagamentos e o valor do seu benefício.',
        ),
        Servico(
          id: 5,
          titulo: 'Conheça seus direitos: Estatuto do Idoso',
          descricao: 'Direitos garantidos por lei a quem tem 60 anos ou mais.',
          categoria: 'Direitos e Cidadania',
          orgao: 'Governo Federal',
          conteudo:
              'O Estatuto do Idoso (Lei nº 10.741/2003) garante, entre outros direitos:\n\n'
              '• Atendimento preferencial em bancos, comércio, órgãos públicos e filas em geral;\n'
              '• Gratuidade no transporte coletivo público urbano para quem tem 65 anos ou mais '
              '(basta apresentar um documento com foto);\n'
              '• Desconto de pelo menos 50% em eventos de cultura, esporte e lazer para quem tem '
              '60 anos ou mais;\n'
              '• Vagas reservadas de estacionamento e assentos preferenciais em transportes e locais públicos;\n'
              '• Prioridade na tramitação de processos judiciais e administrativos;\n'
              '• Proteção contra negligência, abandono, violência e discriminação — isso é crime '
              'previsto em lei.\n\n'
              'Se você ou alguém que conhece sofrer maus-tratos, ligue gratuitamente para o '
              'Disque 100 (Direitos Humanos), disponível 24 horas por dia, todos os dias.',
        ),
      ];

  static List<PedidoLogistico> pedidos() => [
        PedidoLogistico(
          id: 1,
          codigoPedido: 'LM-2026-0001',
          produto: 'Kit ferramentas basicas',
          tipoProduto: 'Ferramentas',
          regiaoEntrega: 'Sao Paulo - Centro',
          distanciaKm: 8,
          prazoPrometido: '16/06/2026',
          statusAtual: 'EM_TRANSITO',
          parceiroLogistico: 'Loggi',
          estoqueDisponivel: true,
          historicoAtrasos: 0,
          reagendamentos: 0,
          latitude: -23.5505,
          longitude: -46.6333,
        ),
        PedidoLogistico(
          id: 2,
          codigoPedido: 'LM-2026-0002',
          produto: 'Tinta acrilica 18L',
          tipoProduto: 'Pintura',
          regiaoEntrega: 'Sao Paulo - Zona Leste',
          distanciaKm: 22,
          prazoPrometido: '15/06/2026',
          statusAtual: 'ATRASADO',
          parceiroLogistico: 'Total Express',
          estoqueDisponivel: false,
          historicoAtrasos: 3,
          reagendamentos: 2,
          latitude: -23.5400,
          longitude: -46.4900,
        ),
        PedidoLogistico(
          id: 3,
          codigoPedido: 'LM-2026-0003',
          produto: 'Furadeira de impacto',
          tipoProduto: 'Ferramentas eletricas',
          regiaoEntrega: 'Sao Paulo - Zona Sul',
          distanciaKm: 14,
          prazoPrometido: '18/06/2026',
          statusAtual: 'PENDENTE',
          parceiroLogistico: 'Correios',
          estoqueDisponivel: true,
          historicoAtrasos: 1,
          reagendamentos: 0,
          latitude: -23.6500,
          longitude: -46.7000,
        ),
        PedidoLogistico(
          id: 4,
          codigoPedido: 'LM-2026-0004',
          produto: 'Piso laminado (10 caixas)',
          tipoProduto: 'Revestimento',
          regiaoEntrega: 'Sao Paulo - Zona Norte',
          distanciaKm: 19,
          prazoPrometido: '14/06/2026',
          statusAtual: 'ENTREGUE',
          parceiroLogistico: 'Loggi',
          estoqueDisponivel: true,
          historicoAtrasos: 0,
          reagendamentos: 0,
          latitude: -23.4800,
          longitude: -46.6200,
        ),
      ];

  /// Heuristica de risco identica em espirito ao motor do backend (regras).
  /// [impactoClima] (0-25) vem do clima consultado via Open-Meteo na tela de
  /// detalhe - chuva/vento realmente aumentam o score, nao sao so texto.
  static RiscoLogistico calcularRisco(PedidoLogistico p, {int impactoClima = 0}) {
    int score = 0;
    score += p.historicoAtrasos * 18;
    score += p.reagendamentos * 12;
    score += p.estoqueDisponivel ? 0 : 25;
    score += p.distanciaKm > 20 ? 15 : (p.distanciaKm > 10 ? 8 : 0);
    if (p.statusAtual == 'ATRASADO') score += 20;
    score += impactoClima.clamp(0, 25);
    if (score > 100) score = 100;

    String nivel;
    String rec;
    if (score >= 75) {
      nivel = 'CRITICO';
      rec = 'Acionar suporte logístico e oferecer reagendamento proativo.';
    } else if (score >= 50) {
      nivel = 'ALTO';
      rec = 'Monitorar de perto e comunicar o cliente sobre possível atraso.';
    } else if (score >= 25) {
      nivel = 'MEDIO';
      rec = 'Acompanhar a entrega no próximo ciclo de atualização.';
    } else {
      nivel = 'BAIXO';
      rec = 'Entrega dentro do esperado. Nenhuma ação necessária.';
    }
    return RiscoLogistico(
      pedidoId: p.id,
      riscoScore: score,
      riscoNivel: nivel,
      recomendacao: rec,
      mensagemCliente: score >= 50
          ? 'Detectamos fatores que podem afetar a janela prometida.'
          : 'Sua entrega está dentro do prazo previsto.',
    );
  }

  static Map<String, String> respostaAssistente(String pergunta) {
    final q = pergunta.toLowerCase();
    if (q.contains('atras')) {
      return {
        'resposta':
            'Identificamos risco elevado neste pedido. Recomendamos acionar o '
            'suporte logístico antes do prazo para um reagendamento proativo.',
        'acaoRecomendada': 'REAGENDAR',
      };
    }
    if (q.contains('prazo') || q.contains('quando')) {
      return {
        'resposta':
            'O prazo prometido segue válido. Você receberá uma notificação '
            'caso haja qualquer alteração na janela de entrega.',
        'acaoRecomendada': 'AGUARDAR',
      };
    }
    return {
      'resposta':
          'Estou acompanhando seu pedido em tempo real. Posso ajudar com '
          'prazo, status, risco de atraso ou reagendamento.',
      'acaoRecomendada': 'INFORMAR',
    };
  }

  /// Categorias em alta (deteccao de picos/sazonalidade) - espelha o formato
  /// do endpoint real GET /tendencias do backend. Nomes de categoria
  /// identicos aos usados em Servico.categoria (mesma acentuacao).
  static List<Map<String, dynamic>> tendencias() => [
        {
          'categoria': 'Previdência',
          'volumeUltimos7Dias': 34,
          'mediaHistoricaDiaria': 2.1,
          'emAlta': true,
        },
        {
          'categoria': 'Documentos',
          'volumeUltimos7Dias': 9,
          'mediaHistoricaDiaria': 1.8,
          'emAlta': false,
        },
        {
          'categoria': 'Saúde',
          'volumeUltimos7Dias': 6,
          'mediaHistoricaDiaria': 1.2,
          'emAlta': false,
        },
      ];

  /// Top recomendacoes heuristicas - espelha o formato (cold-start) do
  /// endpoint real GET /recomendacoes/{userId} do backend: prioriza o
  /// curso de nivel BASICO e o primeiro servico quando o usuario nao tem
  /// historico de eventos ainda.
  static List<Map<String, dynamic>> recomendacoes() => [
        {
          'tipo': 'curso',
          'id': 1,
          'titulo': 'Primeiros passos no celular',
          'nivel': 'BASICO',
          'score': 100,
          'motivo': 'cold-start',
        },
        {
          'tipo': 'servico',
          'id': 1,
          'titulo': 'Consultar benefício do INSS',
          'categoria': 'Previdência',
          'score': 90,
          'motivo': 'cold-start',
        },
        {
          'tipo': 'curso',
          'id': 2,
          'titulo': 'Usando o gov.br',
          'nivel': 'INTERMEDIARIO',
          'score': 80,
          'motivo': 'cold-start',
        },
      ];
}
