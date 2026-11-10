class_name ConexaoFase2 extends Marker2D
## Ponto nomeado de entrada, saída, spawn de debug ou slot de uma área.
## Só carrega dados; quem decide o que fazer com ele é a fase ou a área.

@export_enum("entrada", "saida", "debug", "slot") var tipo: String = "entrada"
