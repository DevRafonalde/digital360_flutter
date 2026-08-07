import 'package:flutter/foundation.dart';
import '../data/models/vinculo_cuidador.dart';
import '../data/services/api_service.dart';

/// Estado do modo cuidador - somente leitura: o cuidador acompanha o
/// progresso de idosos vinculados, mas nunca age em nome deles.
class CuidadorProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  bool carregando = false;
  bool vinculando = false;
  String? erro;
  List<VinculoCuidador> vinculos = [];
  final Map<String, ResumoIdoso> resumos = {};

  Future<bool> vincular(String bearer, String cuidadorId, String codigoIdoso) async {
    vinculando = true;
    erro = null;
    notifyListeners();
    try {
      await _api.vincularCuidador(bearer, cuidadorId, codigoIdoso);
      return true;
    } catch (e) {
      erro = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      vinculando = false;
      notifyListeners();
    }
  }

  Future<void> carregarVinculos(String bearer, String cuidadorId) async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      vinculos = await _api.getVinculosCuidador(bearer, cuidadorId);
      for (final v in vinculos) {
        resumos[v.idosoId] = await _api.getResumoIdoso(bearer, v.idosoId);
      }
    } catch (_) {
      erro = 'Não foi possível carregar seus vínculos agora.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }
}
