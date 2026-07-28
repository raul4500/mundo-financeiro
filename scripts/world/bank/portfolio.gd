extends Panel

@onready var portfolio_list = $ScrollContainer/VBoxContainer


func _ready():
	FIIManager.portfolio_updated.connect(_on_portfolio_updated)
	load_portfolio()
	
func _on_portfolio_updated():
	load_portfolio()

func load_portfolio():
	# limpa
	for child in portfolio_list.get_children():
		child.queue_free()
	
	for fund_id in FIIManager.portfolio.keys():
		var quantity = FIIManager.portfolio[fund_id]
		
		if quantity <= 0:
			continue
		
		var fund = FIIManager.funds[fund_id]
		
		# =============================
		# 🎴 PANEL
		# =============================
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(0, 60)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var label = Label.new()
		
		var total_value = fund["price"] * quantity
		
		label.text = "%s | Cotas: %d | Valor: R$%.2f" % [
			fund["name"], quantity, total_value
		]
		
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		panel.add_child(label)
		portfolio_list.add_child(panel)
