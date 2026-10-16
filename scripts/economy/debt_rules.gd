extends RefCounted

# Regras compartilhadas das contas do banco (contas da casa e eventos que
# cobram dinheiro). Funções puras: quem chama passa os dias absolutos, então
# nada aqui depende de autoload.
#
# Linha do tempo de uma conta:
#   due_week   -> vence no fim dessa semana (último dia dela). Pagar até aqui
#                 custa o valor original.
#   limit_week -> data limite: no fim dessa semana o jogo cobra a conta sozinho.
# Entre as duas, o valor cresce INTEREST_PER_DAY ao dia, composto.
#
# O valor com juros é sempre DERIVADO do dia atual, nunca gravado na conta.
# Assim repetir uma semana (dias voltam a 1) devolve os mesmos valores, em vez
# de somar juros sobre juros já cobrados na tentativa anterior.

const INTEREST_PER_DAY := 0.10

# Dias de atraso em `as_of_abs_day` (dia absoluto, ver Global.get_absolute_day()).
# O dia de vencimento ainda não tem juros: o primeiro dia de atraso é o seguinte.
static func overdue_days(as_of_abs_day: int, due_week: int, days_per_week: int) -> int:
	return maxi(0, as_of_abs_day - due_week * days_per_week)

static func amount_with_interest(base_amount: float, overdue: int) -> float:
	return snappedf(base_amount * pow(1.0 + INTEREST_PER_DAY, float(overdue)), 0.01)
