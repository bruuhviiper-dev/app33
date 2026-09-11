/// Fundos-foto GRÁTIS do editor de imagem (seção "Fotos" da tela Criar).
///
/// As imagens vêm do Lorem Picsum (fotos do Unsplash — licença livre para uso
/// comercial: https://unsplash.com/license). Os ids foram CURADOS manualmente
/// (conferidos um a um): só paisagens/natureza, nada de pessoas/animais que
/// altere a classificação do app.
///
/// São carregadas da internet e cacheadas no disco pelo `cached_network_image`.
/// Depois de abertas 1x, seguem disponíveis mesmo SEM internet.
class PhotoBackground {
  const PhotoBackground(this.id);

  /// Id estável da foto no Picsum.
  final String id;

  /// Imagem em alta para o fundo do cartão (story 9:16, com folga para os
  /// formatos quadrado/retrato via BoxFit.cover).
  String get full => 'https://picsum.photos/id/$id/1080/1920';

  /// Miniatura leve para o seletor.
  String get thumb => 'https://picsum.photos/id/$id/160/240';
}

/// Catálogo CURADO para o nicho de REFLEXÃO: só paisagens serenas/contemplativas
/// (água espelhada, névoa, amanhecer, montanha calma, floresta) — as mais
/// reflexivas primeiro. Removidas as cenas urbanas (cidade/arquitetura/ruas),
/// que fugiam do tema. Licença Unsplash (uso comercial livre).
const photoBackgrounds = <PhotoBackground>[
  // --- Água espelhada / lago calmo (o mais "reflexão") ---
  PhotoBackground('1077'), // lago espelhado
  PhotoBackground('1055'), // lago calmo ao amanhecer
  PhotoBackground('1051'), // cais de madeira no lago
  PhotoBackground('1060'), // cais e lago
  PhotoBackground('1069'), // lago e montanhas
  PhotoBackground('1024'), // montanhas e lago
  PhotoBackground('1041'), // mar sereno / gelo
  PhotoBackground('1061'), // praia serena
  // --- Névoa / bruma (contemplativo) ---
  PhotoBackground('1064'), // neblina sobre as colinas
  PhotoBackground('1044'), // floresta com névoa
  PhotoBackground('1071'), // céu e nuvens
  // --- Amanhecer / entardecer suave ---
  PhotoBackground('1037'), // nascer do sol entre árvores
  PhotoBackground('1083'), // montanha ao amanhecer
  PhotoBackground('1016'), // cânion no fim de tarde
  PhotoBackground('1057'), // costa ao pôr do sol
  PhotoBackground('1053'), // pôr do sol no mar
  PhotoBackground('1072'), // deserto ao entardecer
  // --- Montanha / vale / floresta serena ---
  PhotoBackground('1015'), // fiorde / penhasco
  PhotoBackground('1039'), // cachoeira e vale verde
  PhotoBackground('1043'), // vale de Yosemite
  PhotoBackground('1045'), // montanha verde
  PhotoBackground('1042'), // vale verde
  PhotoBackground('1018'), // montanhas verdes e estrada
  PhotoBackground('1036'), // montanhas nevadas
  PhotoBackground('1035'), // montanha nevada
  PhotoBackground('1063'), // neve e árvores
  PhotoBackground('1029'), // trilho na floresta
  PhotoBackground('1059'), // trilha na mata
  PhotoBackground('1070'), // floresta densa
  PhotoBackground('1020'), // rio na floresta
  PhotoBackground('1066'), // colinas verdes
  PhotoBackground('1056'), // vale ensolarado
  PhotoBackground('1058'), // estrada e montanha
  // --- Mar / costa calma ---
  PhotoBackground('1019'), // mar sob céu nublado
  PhotoBackground('1013'), // costa rochosa
  PhotoBackground('1014'), // mar e horizonte
  PhotoBackground('1052'), // praia de rocha negra
  PhotoBackground('1038'), // costa gelada
  PhotoBackground('1054'), // ilha e mar
  PhotoBackground('1065'), // vista aérea da costa
  PhotoBackground('1084'), // costa e farol
  PhotoBackground('1075'), // praia e falésias
  PhotoBackground('1049'), // praia tropical
  // --- Campo / natureza aberta ---
  PhotoBackground('1023'), // campos vistos do alto
  PhotoBackground('1031'), // campo dourado
  PhotoBackground('1074'), // campo aberto
  PhotoBackground('1033'), // estrada no campo
  PhotoBackground('1082'), // campo florido
  PhotoBackground('1080'), // vinhedos
  PhotoBackground('1073'), // dunas
  PhotoBackground('1062'), // outono dourado
  PhotoBackground('1003'), // folhas de outono
];
