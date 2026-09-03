extends Panel

@onready var fund_list = $ScrollContainer/VBoxContainer

func _ready():
	FIIManager.funds_updated.connect(_on_funds_updated)
	load_funds()

func _on_funds_updated():
	load_funds()

func load_funds():
	# limpa lista
	for child in fund_list.get_children():
		child.queue_free()
	
	for fund_id in FIIManager.funds.keys():
		var fund = FIIManager.funds[fund_id]
		
		
		var container = VBoxContainer.new()
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		container.add_theme_constant_override("separation", 16)

# =============================
# 🏷️ LABEL
# =============================
		var label = Label.new()
		label.text = "%s - R$%.2f" % [fund["name"], fund["price"]]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

# IMPORTANTE: não deixar expandir demais
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER


# =============================
# 🔢INPUT
# =============================
		var input = SpinBox.new()
		input.min_value = 1
		input.max_value = 100
		input.step = 1

		input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		input.size_flags_vertical = Control.SIZE_SHRINK_CENTER


# =============================
# 🔘 BOTÕES
# =============================
		var btn_container = HBoxContainer.new()
		btn_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var buy_btn = Button.new()
		buy_btn.text = "Comprar"
		buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var sell_btn = Button.new()
		sell_btn.text = "Vender"
		sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

# conectar
		buy_btn.pressed.connect(_on_buy.bind(fund_id, input))
		sell_btn.pressed.connect(_on_sell.bind(fund_id, input))

		btn_container.add_child(buy_btn)
		btn_container.add_child(sell_btn)


# =============================
# 📦 HIERARQUIA CORRETA
# =============================
		container.add_child(label)
		container.add_child(input)
		container.add_child(btn_container)

		fund_list.add_child(container)


# =============================
# 💸 AÇÕES
# =============================
func _on_buy(fund_id, input):
	var amount = int(input.value)
	FIIManager.buy_fund(fund_id, amount)
	load_funds() # atualiza UI


func _on_sell(fund_id, input):
	var amount = int(input.value)
	FIIManager.sell_fund(fund_id, amount)
	load_funds()
