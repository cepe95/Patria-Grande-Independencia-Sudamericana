extends Resource

class_name Date

var year: int
var month: int
var day: int

const DAYS_IN_MONTH = [31,28,31,30,31,30,31,31,30,31,30,31]

func _init(_year: int, _month: int, _day: int):
	year = _year
	month = _month
	day = _day

func copy() -> Date:
	return Date.new(year, month, day)

func as_string() -> String:
	return "%02d/%02d/%04d" % [day, month, year]

func next_day():
	day += 1
	if day > DAYS_IN_MONTH[month - 1]:
		day = 1
		month += 1
		if month > 12:
			month = 1
			year += 1

func add_days(days: int):
	for i in range(days):
		next_day()

func is_greater_or_equal(other: Date) -> bool:
	if year != other.year:
		return year > other.year
	if month != other.month:
		return month > other.month
	return day >= other.day
