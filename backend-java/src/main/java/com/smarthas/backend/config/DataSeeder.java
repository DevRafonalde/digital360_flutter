package com.smarthas.backend.config;

import com.smarthas.backend.model.*;
import com.smarthas.backend.repository.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Popula dados de demonstracao no primeiro start (banco H2 em arquivo vazio),
 * espelhando o MockData.dart do app Flutter para o app e o backend mostrarem
 * exatamente o mesmo cenario na demo/video.
 */
@Component
public class DataSeeder implements CommandLineRunner {

    private final UsuarioRepository usuarioRepository;
    private final CursoRepository cursoRepository;
    private final ServicoRepository servicoRepository;
    private final PedidoLogisticoRepository pedidoRepository;
    private final PasswordEncoder passwordEncoder;

    public DataSeeder(UsuarioRepository usuarioRepository, CursoRepository cursoRepository,
                       ServicoRepository servicoRepository, PedidoLogisticoRepository pedidoRepository,
                       PasswordEncoder passwordEncoder) {
        this.usuarioRepository = usuarioRepository;
        this.cursoRepository = cursoRepository;
        this.servicoRepository = servicoRepository;
        this.pedidoRepository = pedidoRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        seedUsuarios();
        seedCursos();
        seedServicos();
        seedPedidos();
    }

    private void seedUsuarios() {
        if (usuarioRepository.count() > 0) return;

        usuarioRepository.save(Usuario.builder()
                .nomeAmigavel("Administrador")
                .nomeUser("admin")
                .senhaHash(passwordEncoder.encode("admin123"))
                .perfil(Perfil.ADMIN)
                .build());

        usuarioRepository.save(Usuario.builder()
                .nomeAmigavel("Joao Visitante")
                .nomeUser("joao")
                .senhaHash(passwordEncoder.encode("123456"))
                .perfil(Perfil.USUARIO)
                // isTutor=true na seed para o cenario de demo poder exercitar de
                // verdade o fluxo comunitario (gerar-rascunho, criar curso, avaliar).
                .isTutor(true)
                .build());
    }

    private void seedCursos() {
        if (cursoRepository.count() > 0) return;

        cursoRepository.save(Curso.builder().titulo("Primeiros passos no celular")
                .descricao("Aprenda a usar o smartphone com seguranca e confianca.")
                .nivel("BASICO").cargaHoraria(4).totalModulos(6).progresso(75).build());

        cursoRepository.save(Curso.builder().titulo("Usando o gov.br")
                .descricao("Acesse servicos publicos digitais sem complicacao.")
                .nivel("INTERMEDIARIO").cargaHoraria(6).totalModulos(8).progresso(30).build());

        cursoRepository.save(Curso.builder().titulo("Seguranca digital e golpes")
                .descricao("Identifique fraudes e proteja seus dados pessoais.")
                .nivel("INTERMEDIARIO").cargaHoraria(5).totalModulos(7).progresso(0).build());

        cursoRepository.save(Curso.builder().titulo("Pix e pagamentos digitais")
                .descricao("Faca transferencias e pagamentos com tranquilidade.")
                .nivel("AVANCADO").cargaHoraria(8).totalModulos(10).progresso(10).build());
    }

    private void seedServicos() {
        if (servicoRepository.count() > 0) return;

        servicoRepository.save(Servico.builder().titulo("Consultar beneficio do INSS")
                .descricao("Veja extrato e situacao de aposentadoria/auxilio.")
                .categoria("Previdencia").orgao("INSS")
                .conteudo("Acesse o aplicativo Meu INSS, faca login com sua conta gov.br e selecione "
                        + "\"Extrato de pagamento\" para consultar seu beneficio.").build());

        servicoRepository.save(Servico.builder().titulo("Agendar consulta no SUS")
                .descricao("Marque atendimento na unidade de saude mais proxima.")
                .categoria("Saude").orgao("SUS")
                .conteudo("Use o app Conecte SUS ou procure a UBS do seu bairro com o Cartao Nacional de "
                        + "Saude para agendar sua consulta.").build());

        servicoRepository.save(Servico.builder().titulo("Emitir 2a via do RG/CPF")
                .descricao("Solicite documentos pelo portal gov.br.")
                .categoria("Documentos").orgao("gov.br")
                .conteudo("No portal gov.br, busque por \"2a via\" do documento desejado e siga as "
                        + "instrucoes. Alguns servicos sao gratuitos.").build());

        servicoRepository.save(Servico.builder().titulo("Consultar Bolsa Familia")
                .descricao("Verifique calendario e valor do beneficio.")
                .categoria("Assistencia Social").orgao("Caixa")
                .conteudo("Use o app Bolsa Familia ou Caixa Tem para consultar o calendario de pagamentos "
                        + "e o valor do seu beneficio.").build());
    }

    private void seedPedidos() {
        if (pedidoRepository.count() > 0) return;

        pedidoRepository.save(PedidoLogistico.builder()
                .codigoPedido("LM-2026-0001").produto("Kit ferramentas basicas").tipoProduto("Ferramentas")
                .regiaoEntrega("Sao Paulo - Centro").distanciaKm(8).prazoPrometido("16/06/2026")
                .statusAtual("EM_TRANSITO").parceiroLogistico("Loggi").estoqueDisponivel(true)
                .historicoAtrasos(0).reagendamentos(0).latitude(-23.5505).longitude(-46.6333).build());

        pedidoRepository.save(PedidoLogistico.builder()
                .codigoPedido("LM-2026-0002").produto("Tinta acrilica 18L").tipoProduto("Pintura")
                .regiaoEntrega("Sao Paulo - Zona Leste").distanciaKm(22).prazoPrometido("15/06/2026")
                .statusAtual("ATRASADO").parceiroLogistico("Total Express").estoqueDisponivel(false)
                .historicoAtrasos(3).reagendamentos(2).latitude(-23.5400).longitude(-46.4900).build());

        pedidoRepository.save(PedidoLogistico.builder()
                .codigoPedido("LM-2026-0003").produto("Furadeira de impacto").tipoProduto("Ferramentas eletricas")
                .regiaoEntrega("Sao Paulo - Zona Sul").distanciaKm(14).prazoPrometido("18/06/2026")
                .statusAtual("PENDENTE").parceiroLogistico("Correios").estoqueDisponivel(true)
                .historicoAtrasos(1).reagendamentos(0).latitude(-23.6500).longitude(-46.7000).build());

        pedidoRepository.save(PedidoLogistico.builder()
                .codigoPedido("LM-2026-0004").produto("Piso laminado (10 caixas)").tipoProduto("Revestimento")
                .regiaoEntrega("Sao Paulo - Zona Norte").distanciaKm(19).prazoPrometido("14/06/2026")
                .statusAtual("ENTREGUE").parceiroLogistico("Loggi").estoqueDisponivel(true)
                .historicoAtrasos(0).reagendamentos(0).latitude(-23.4800).longitude(-46.6200).build());
    }
}
