extends Node

var unexpected_events: Dictionary = {"eventos": [
	{
	  "id": "quebra_carro",
	  "titulo": "Problema no carro",
	  "descricao": "Seu carro quebrou e precisa de conserto urgente.",
	  "tipo": "negativo",
	  "categoria": "emergencia",
	  "impacto": {
		"dinheiro": -120
	  },
	  "probabilidade": 0.2
	},
	{
	  "id": "promocao_trabalho",
	  "titulo": "Promoção no trabalho",
	  "descricao": "Você foi promovido e recebeu um bônus!",
	  "tipo": "positivo",
	  "categoria": "renda",
	  "impacto": {
		"dinheiro": 800
	  },
	  "probabilidade": 0.15
	},
	{
	  "id": "gasto_saude",
	  "titulo": "Despesa médica",
	  "descricao": "Você teve um problema de saúde inesperado.",
	  "tipo": "negativo",
	  "categoria": "emergencia",
	  "impacto": {
		"dinheiro": -100
	  },
	  "probabilidade": 0.2
	},
	{
	  "id": "freelance",
	  "titulo": "Trabalho extra",
	  "descricao": "Você conseguiu um trabalho freelance no fim de semana.",
	  "tipo": "positivo",
	  "categoria": "renda_extra",
	  "impacto": {
		"dinheiro": 400
	  },
	  "probabilidade": 0.25
	},
	{
	  "id": "tentacao_compra",
	  "titulo": "Promoção imperdível",
	  "descricao": "Você encontrou uma promoção tentadora no shopping.",
	  "tipo": "neutro",
	  "categoria": "decisao",
	  "escolhas": [
		{
		  "descricao": "Comprar",
		  "impacto": {
			"dinheiro": -100
		  }
		},
		{
		  "descricao": "Não comprar",
		  "impacto": {
			"dinheiro": 0
		  }
		}
	  ],
	  "probabilidade": 0.2
	}
  ]
}
