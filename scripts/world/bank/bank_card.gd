extends RefCounted

# Card padrão das abas do banco (histórico, eventos, contas da casa, loja de
# FIIs e carteira). O grid de cada aba (colunas, espaçamento) é da cena; aqui
# fica só o card, para as cinco abas terem o mesmo visual e uma regra só.
#
# Estrutura: PanelContainer > MarginContainer > VBoxContainer. Quem monta o
# conteúdo adiciona filhos em `box`.
#
# PanelContainer, e não Panel: um Panel não é container, não lê o tamanho mínimo
# dos filhos e o conteúdo vazaria para fora do card quando um texto quebra em
# mais linhas. O PanelContainer cresce junto; `min_height` é só o piso, para os
# cards de uma mesma linha do grid não ficarem com alturas muito diferentes.
# O visual vem do PanelContainer/styles/panel do font_theme.tres da aba.

# label.tres, e não o tema do painel: o Label do font_theme.tres tem fundo
# (label_round.png) e corpo 24, que dentro de um card viram caixa dentro de caixa.
const LABEL_THEME = preload("res://themes/label.tres")

const CARD_MARGIN := 10

# Devolve {"card": PanelContainer, "box": VBoxContainer}.
static func new_card(min_height: int) -> Dictionary:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, min_height)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, CARD_MARGIN)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	return {"card": card, "box": box}

# autowrap_mode: um Label sem autowrap pede como largura mínima o texto inteiro
# em uma linha e empurra o card para fora do grid (ver PROJECT_KNOWLEDGE 3.5).
static func make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.theme = LABEL_THEME
	label.add_theme_font_size_override("font_size", font_size)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label

static func make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button

# Card de aviso para lista vazia ("Nenhuma conta pendente"), no lugar de um
# Label solto que ficaria preso à primeira célula do grid.
static func new_empty_card(message: String) -> PanelContainer:
	var parts := new_card(80)
	parts["box"].add_child(make_label(message, 16))
	return parts["card"]
