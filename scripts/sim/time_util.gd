class_name TimeUtil
extends RefCounted

## Calendar helpers. Dates are zero-padded ISO strings, compared in UTC day counts.


static func today() -> String:
	var d: Dictionary = Time.get_date_dict_from_system()
	return iso(int(d.year), int(d.month), int(d.day))


static func iso(year: int, month: int, day: int) -> String:
	return "%04d-%02d-%02d" % [year, month, day]


static func unix_day(date_text: String) -> int:
	var parts := date_text.split("-")
	var stamp := Time.get_unix_time_from_datetime_dict({
		"year": int(parts[0]),
		"month": int(parts[1]),
		"day": int(parts[2]),
		"hour": 0,
		"minute": 0,
		"second": 0,
	})
	return int(stamp / 86400)


static func days_between(start_date: String, end_date: String) -> int:
	return unix_day(end_date) - unix_day(start_date)


static func add_days(date_text: String, days: int) -> String:
	var stamp := int(Time.get_unix_time_from_datetime_dict({
		"year": int(date_text.substr(0, 4)),
		"month": int(date_text.substr(5, 2)),
		"day": int(date_text.substr(8, 2)),
		"hour": 0,
		"minute": 0,
		"second": 0,
	}))
	stamp += days * 86400
	var d: Dictionary = Time.get_datetime_dict_from_unix_time(stamp)
	return iso(int(d.year), int(d.month), int(d.day))


static func seconds_until_midnight() -> int:
	var t: Dictionary = Time.get_time_dict_from_system()
	var secs := int(t.hour) * 3600 + int(t.minute) * 60 + int(t.second)
	return maxi(0, 86400 - secs)


static func countdown_text() -> String:
	var left := seconds_until_midnight()
	var hours := int(left / 3600)
	var minutes := int((left % 3600) / 60)
	return "%dh %dm until the next decade" % [hours, minutes]
