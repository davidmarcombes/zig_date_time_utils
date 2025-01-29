const std = @import("std");
const testing = std.testing;

const ctime = @cImport(@cInclude("time.h"));

/// Error definitions
const DateTimeError = error{
    /// Invalid date
    InvalidDate,
    /// Invalid time
    InvalidTime,
    /// Invalid date and time
    InvalidDateTime,
};    

/// Days in each month (non-leap year)
const daysInMonth = [12]u8{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

/// Day names
const dayNames = [_][]const u8{ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" };

/// Short day names
const shortDayNames = [_][]const u8{"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};

/// Month names
const monthNames = [_][]const u8{"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};

/// Short month names
const shortMonthNames = [_][]const u8{"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};

/// Represents different units of time measurement
pub const TimeUnit = enum {
    /// Represents seconds
    Second,
    /// Represents minutes
    Minute,
    /// Represents hours
    Hour,
    /// Represents days
    Day,
    /// Represents a week
    Week,
    /// Represents months
    Month,
    /// Represents a quarter
    Quarter,
    //// Represents a half year
    Semester,
    /// Represents years
    Year,
    /// Represents decades
    Decade,
    /// Represents centuries
    Century,

    /// Convert the time unit to its string representation
    pub fn toString(self: TimeUnit) []const u8 {
        return switch (self) {
            .Second => "second",
            .Minute => "minute",
            .Hour => "hour",
            .Day => "day",
            .Week => "week",
            .Month => "month",
            .Quarter => "quarter",
            .Semester => "semester",
            .Year => "year",
            .Decade => "decade",
            .Century => "century",
        };
    }    
};

pub const DateRoll = enum {
    /// No roll
    None,
    /// Roll to the next valid date
    Following,
    /// Roll to the previous valid date
    Preceding,
    /// Roll to the next date in the same month or previous date in smae month
    ModifiedFollowing,
    /// Roll to the previous date in the same month or next date in the same month
    ModifiedPreceding,

    /// Convert the date roll to its string representation
    /// Returns an empty string if the date roll is invalid
    pub fn toString(self: DateRoll) []const u8 {
        return switch (self) {
            .None => "N",
            .Following => "F",
            .Preceding => "P",
            .ModifiedFollowing => "MF",
            .ModifiedPreceding => "MP",
            else => "",
        };
    }

    /// Convert a string to a date roll
    /// Returns None if the string is invalid
    pub fn fromString(value: []const u8) DateRoll {
        return switch (value) {
            "N" => .None,
            "F" => .Following,
            "P" => .Preceding,
            "MF" => .ModifiedFollowing,
            "MP" => .ModifiedPreceding,
            else => .None,
        };
    }
};

/// Represents a C Date Time
pub const CDateTime = extern struct {
    /// Seconds
    seconds: c_int,
    /// Minutes
    minutes: c_int,
    /// Hours
    hours: c_int,
    /// Day of the month
    day: c_int,
    /// Month from 0 to 11
    month: c_int, 
    /// Year from 1900    
    year: c_int,
    /// Day of the week
    day_of_week: c_int,
    /// Day of the year
    day_of_year: c_int,
    /// Is daylight saving time
    is_day_light_saving: c_int,
};

/// Represents a date and time.
pub const DateTime = extern struct {
    /// Seconds
    seconds: u8,
    /// Minutes
    minutes: u8,
    /// Hours
    hours: u8,
    /// Day of the month
    day: u8,
    /// Month from 1 to 12
    month: u8,
    /// Year from AD
    year: u16,
  };

/// Represents a date.
pub const Date = extern struct {  
    /// Day of the month
    day: u8,
    /// Month from 1 to 12
    month: u8,
    /// Year from AD
    year: u16,

    pub fn init(year: u16, month: u8, day: u8) Date {
        return Date{
            .day = day,
            .month = month,
            .year = year,
        };
    }

    pub fn toDateTime(self: Date) DateTime {
        return DateTime{
            .seconds = 0,
            .minutes = 0,
            .hours = 0,
            .day = self.day,
            .month = self.month,
            .year = self.year,
        };
    }

    pub fn isEqual(self: Date, other: Date) bool {
        return self.day == other.day and self.month == other.month and self.year == other.year;
    }
    
    pub fn isLessThan(self: Date, other: Date) bool {
        if (self.year < other.year) {
            return true;
        } else if (self.year == other.year) {
            if (self.month < other.month) {
                return true;
            } else if (self.month == other.month) {
                return self.day < other.day;
            }
        }
        return false;
    }

    pub fn isLessThanOrEqual(self: Date, other: Date) bool {
        return self.isLessThan(other) or self.isEqual(other);
    }

    pub fn isGreaterThan(self: Date, other: Date) bool {
        return !self.isLessThanOrEqual(other);
    }

    pub fn isGreaterThanOrEqual(self: Date, other: Date) bool {
        return !self.isLessThan(other);
    }

    pub fn toJulian(self: Date) u32 {
        return ymdToJulianDay(self.year, self.month, self.day);
    }

    pub fn toGregorian(self: Date) u32 {
        return ymdToGregorianDay(self.year, self.month, self.day);
    }

    pub fn toOADate(self: Date) f64 {
        return ymdhmsToExcelSerialDate(self.year, self.month, self.day, 0, 0, 0);
    }

};

/// Represents a time span.
pub const TimeSpan = extern struct {
    /// Number of seconds
    seconds: i32,
    /// Number of minutes
    minutes: i32,
    /// Number of hours
    hours: i32,
    /// Number of days
    days: i32,
    /// Number of months
    months: i32,
    /// Number of years
    years: i32,
};

/// Represents a time offset.
pub const TimeOffset = extern struct {
    /// Amount of time units
    amount: i32,
    /// Time unit
    unit: TimeUnit,
};

/// Represents a single holiday
pub const Holiday = struct {
    /// Month (1-12)
    month: u8,
    /// Day (1-31)
    day: u8,
};

// Some Regular holidays
pub const Holidays = struct {
    /// New Year's Day
    NewYearsDay: Holiday = Holiday{ .month = 1, .day = 1 },
    /// Valentine's Day
    ValentinesDay: Holiday = Holiday{ .month = 2, .day = 14 },
    /// Juneteenth
    Juneteenth: Holiday = Holiday{ .month = 6, .day = 19 },
    /// US Independence Day
    UsIndependenceDay: Holiday = Holiday{ .month = 7, .day = 4 },
    /// French National Day - Bastille Day
    BastilleDay: Holiday = Holiday{ .month = 7, .day = 14 },
    /// St. Patrick's Day
    StPatricksDay: Holiday = Holiday{ .month = 3, .day = 17 },
    /// April Fool's Day
    AprilFoolsDay: Holiday = Holiday{ .month = 4, .day = 1 },
    /// Halloween
    Halloween: Holiday = Holiday{ .month = 10, .day = 31 },
    /// Christmas Day
    ChristmasDay: Holiday = Holiday{ .month = 12, .day = 25 },
    /// Boxing Day
    BoxingDay: Holiday = Holiday{ .month = 12, .day = 26 },
};

/// Convert year month day to Gregorian day
/// Based on Zeller's Congruence
pub fn ymdToGregorianDay(year: u16, month: u8, day: u8) u32 {
    var m = month;
    var y = year;
    
    // Adjust month and year for January and February
    if (m <= 2) {
        m += 12;
        y -= 1;
    }
    
    const k = y % 100;
    const j = y / 100;
    
    // Zeller's congruence formula
    var h = (day + ((13 * (m + 1)) / 5) + k + (k / 4) + (j / 4) - (2 * j)) % 7;
    
    // Convert Zeller's result (0 = Saturday) to ISO weekday (0 = Sunday)
    if (h <= 0) h += 7;
    return @intCast((h + 6) % 7);
}

/// Convert year month day to Julian day
pub fn ymdToJulianDay(year: u16, month: u8, day: u8) u32 {
    var a = @intCast((14 - month) / 12);
    var y = year + 4800 - a;
    var m = month + 12 * a - 3;
    return @intCast(day + ((153 * m + 2) / 5) + 365 * y + (y / 4) - (y / 100) + (y / 400) - 32045);
}

/// Convert year mont day to a date key
/// The date key is a 32-bit integer with the format YYYYMMDD
pub fn ymdToDateKey(year: u16, month: u8, day: u8) u32 {
    return @as(u32, year) * 10000 + @as(u32, month) * 100 + @as(u32, day);
}

/// Convert year month day hour minute second to Excel serial date
pub fn ymdhmsToExcelSerialDate(year: u16, month: u8, day: u8, hours: u8, minutes: u8, seconds: u8) f64 {
    const julianDay = ymdToJulianDay(year, month, day);
    return @intToFloat(julianDay) + @intToFloat(hours) / 24.0 + @intToFloat(minutes) / 1440.0 + @intToFloat(seconds) / 86400.0;
}

pub const HolidayCalendar = struct 
{
    /// Allocator for dynamic memory
    allocator: std.mem.Allocator,
    /// Weekend first day
    weekendFirstDay: u8,
    /// Weekend second day
    weekendSecondDay: u8,
    /// Regular holidays (fixed dates)
    regular_holidays: std.ArrayList(Holiday),
    /// Special holidays (variable dates)
    special_holidays: std.AutoHashMap(u32, []const u8),

    /// Initialize a new holiday calendar
    pub fn init(allocator: std.mem.Allocator) !HolidayCalendar {
        return HolidayCalendar{
            .allocator = allocator,
            .weekend = WeekendConfig{},
            .regular_holidays = std.ArrayList(Holiday).init(allocator),
            .special_holidays = std.AutoHashMap(u32, []const u8).init(allocator),
        };
    }

    /// Free allocated memory
    pub fn deinit(self: *HolidayCalendar) void {
        self.regular_holidays.deinit();
        self.special_holidays.deinit();
    }


    /// Add a regular holiday
    pub fn addRegularHoliday(self: *HolidayCalendar, name: []const u8, month: u8, day: u8) !void {
        try self.regular_holidays.append(Holiday{
            .name = name,
            .month = month,
            .day = day,
        });
    }

    /// Add a special holiday
    pub fn addSpecialHoliday(self: *HolidayCalendar, year: u16, month: u8, day: u8, name: []const u8) !void {
        const date_key = ymdToDateKey(year, month, day);
        try self.special_holidays.put(date_key, name);
    }

    /// Check if a date is a holiday
    pub fn isHoliday(self: *HolidayCalendar, year: u16, month: u8, day: u8) bool {
        const date_key = ymdToDateKey(year, month, day);
        return self.isWeekend(day) or self.special_holidays.contains(date_key) or self.isRegularHoliday(month, day);    
    }

    /// Check if a date is a regular holiday
    pub fn isRegularHoliday(self: *HolidayCalendar, month: u8, day: u8) bool {
        for (self.regular_holidays.items()) |holiday| {
            if (holiday.month == month and holiday.day == day) {
                return true;
            }
        }
        return false;
    }

    /// Check if a date is a weekend
    pub fn isWeekend(self: *HolidayCalendar, day: u8) bool {
        return day == self.weekendFirstDay or day == self.weekendSecondDay;
    }

};

/// Check if a year is a leap year
export fn isLeapYear(year: u16) bool {
    return (year % 4 == 0 and year % 100 != 0) or year % 400 == 0;
}

/// Get the day number from its name
/// Sunday = 0, Monday = 1, ..., Saturday = 6
/// Returns -1 if the day name is invalid
pub fn getDayNumber(dayName: []const u8) i8 {

    var i: u8 = 0;
    while (i < 7) : (i += 1) {
        if (dayName.len == dayNames[i].len and
            std.mem.eql(u8, dayName, dayNames[i]) or
            dayName.len == shortDayNames[i].len and
            std.mem.eql(u8, dayName, shortDayNames[i])) {
            return @intCast(i);
        }
    }

    return -1;
}

/// Get the month number from its name
/// January = 1, February = 2, ..., December = 12
/// Returns -1 if the month name is invalid
pub fn getMonthNumber(monthName: []const u8) i8 {
    var i: u8 = 0;
    while (i < 12) : (i += 1) {
        if (monthName.len == monthNames[i].len and
            std.mem.eql(u8, monthName, monthNames[i]) or
            monthName.len == shortMonthNames[i].len and
            std.mem.eql(u8, monthName, shortMonthNames[i])) {
            return @intCast(i + 1);
        }
    }

    return -1;
}

/// Calculate the day of the year
export fn calcDayOfYear(year: u16, month: u8, day: u8) u16 {
    var dayOfYear: u16 = 0;
    var i: u8 = 0;
    while (i < month - 1) : (i += 1) {
        dayOfYear += daysInMonth[i];
    }

    if (isLeapYear(year) and month > 2) {
        dayOfYear += 1;
    }

    dayOfYear += day;
    return dayOfYear;
}

/// Calculate the day of the week
pub fn calcDayOfWeek(year: u16, month: u8, day: u8) u8 {
    var m = month;
    var y = year;
    
    // Adjust month and year for January and February
    if (m <= 2) {
        m += 12;
        y -= 1;
    }
    
    const k = y % 100;
    const j = y / 100;
    
    // Zeller's congruence formula
    var h = (day + ((13 * (m + 1)) / 5) + k + (k / 4) + (j / 4) - (2 * j)) % 7;
    
    // Convert Zeller's result (0 = Saturday) to ISO weekday (0 = Sunday)
    if (h <= 0) h += 7;
    return @intCast((h + 6) % 7);
}

/// Calculate week number
/// Based on ISO 8601
pub fn calcWeekNumber(year: u16, month: u8, day: u8) u8 {
    // Get the day of the year
    const dayOfYear = calcDayOfYear(year, month, day);
    
    // Get the day of week for January 1st
    const jan1WeekDay = calcDayOfWeek(year, 1, 1);
    
    // Calculate the week number
    // Add 6 to handle the case when Jan 1 is not Monday
    const weekNum = @divFloor(dayOfYear + 6 + jan1WeekDay, 7);
    
    // Handle special cases for week 53 and start of year
    if (weekNum > 52) {
        // Check if this date belongs to week 1 of next year
        if (month == 12 and day >= 29) {
            return 1;
        }
    }
    
    return @intCast(weekNum);
}

/// Create a DateTime struct from a CDateTime struct
pub fn createDateTimeFromCDateTime(cdt: CDateTime) DateTime {
    return DateTime{
        .seconds = @intCast(cdt.seconds),
        .minutes = @intCast(cdt.minutes),
        .hours = @intCast(cdt.hours),
        .day = @intCast(cdt.day),
        .month = @intCast(cdt.month + 1),
        .year = @intCast(cdt.year + 1900),
    };
}

/// Create a Date struct from a CDateTime struct
pub fn createDateFromCDateTime(cdt: CDateTime) Date {
    return Date{
        .day = @intCast(cdt.day),
        .month = @intCast(cdt.month + 1),
        .year = @intCast(cdt.year + 1900),
    };
}

/// Create a DateTime struct from a Date struct
pub fn createDateTimeFromDate(date: Date) DateTime {
    return DateTime{
        .seconds = 0,
        .minutes = 0,
        .hours = 0,
        .day = date.day,
        .month = date.month,
        .year = date.year,
    };
}

/// Create a Date struct from a DateTime struct
pub fn createDateFromDateTime(dt: DateTime) Date {
    return Date{
        .day = dt.day,
        .month = dt.month,
        .year = dt.year,
    };
}

/// Get the current local date and time as a CDateTime struct   
pub fn getLocalCDateTime() CDateTime {
    const now = ctime.time(null);
    const local = ctime.localtime(&now);
    return CDateTime{
        .seconds = local.*.tm_sec,
        .minutes = local.*.tm_min,
        .hours = local.*.tm_hour,
        .day = local.*.tm_mday,
        .month = local.*.tm_mon,
        .year = local.*.tm_year,
        .day_of_week = local.*.tm_wday,
        .day_of_year = local.*.tm_yday,
        .is_day_light_saving = local.*.tm_isdst,
    };
}

/// Get the current UTC date and time as a CDateTime struct
pub fn getUtcCDateTime() CDateTime {
    const now = ctime.time(null);
    const utc = ctime.gmtime(&now);
    return DateTime{
        .seconds = utc.*.tm_sec,
        .minutes = utc.*.tm_min,
        .hours = utc.*.tm_hour,
        .day = utc.*.tm_mday,
        .month = utc.*.tm_mon + 1,
        .year = utc.*.tm_year + 1900,
        .day_of_week = utc.*.tm_wday,
        .day_of_year = utc.*.tm_yday,
        .is_day_light_saving = false,
    };
}

/// Get the current local date and time as a DateTime struct
pub fn getLocalDateTime() DateTime {
    const cdt = getLocalCDateTime();
    return createDateTimeFromCDateTime(cdt);
}

/// Get the current UTC date and time as a DateTime struct
pub fn getUtcDateTime() DateTime {
    const cdt = getUtcCDateTime();
    return createDateTimeFromCDateTime(cdt);
}

/// Get the current local date as a Date struct
pub fn getLocalDate() Date {
    const cdt = getLocalCDateTime();
    return createDateFromCDateTime(cdt);
}

/// Get the current UTC date as a Date struct
pub fn getUtcDate() Date {
    const cdt = getUtcCDateTime();
    return createDateFromCDateTime(cdt);
}

/// Validates year, month and day combination
pub fn validateYmd(year: u16, month: u8, day: u8) bool {
    // Quick range checks first
    if (year < 1 or year > 9999 or 
        month < 1 or month > 12 or 
        day < 1 or day > 31) {
        return false;
    }

    // Get days in this month
    var maxDays = daysInMonth[month - 1];
    
    // Adjust February for leap years
    if (month == 2 and isLeapYear(year)) {
        maxDays += 1;
    }

    return day <= maxDays;
}
/// Create a Date struct from a year, month, and day
pub fn createDateFromYmd(year: u16, month: u8, day: u8) Date {
    return Date{
        .day = day,
        .month = month,
        .year = year,
    };
}

/// Create a DateTime struct from a year, month, day, hours, minutes, and seconds
pub fn createDateTimeFromYmd(year: u16, month: u8, day: u8) DateTimeError!DateTime {
    
    if (!validateYmd(year, month, day)) {
        return DateTimeError.InvalidDate;
    }
    
    return DateTime{
        .seconds = 0,
        .minutes = 0,
        .hours = 0,
        .day = day,
        .month = month,
        .year = year,
    };
}

/// Create a DateTime struct from a year, month, day, hours, minutes, and seconds
pub fn createDateTimeFromYmdHms(year: u16, month: u8, day: u8, hours: u8, minutes: u8, seconds: u8) DateTimeError!DateTime {
    
    if (!validateYmd(year, month, day)) {
        return DateTimeError.InvalidDate;
    }
    
    return DateTime{
        .seconds = seconds,
        .minutes = minutes,
        .hours = hours,
        .day = day,
        .month = month,
        .year = year,
    };
}

export fn createTimeSpanFromYmd(years: i32, months: i32, days: i32) TimeSpan {
    return TimeSpan{
        .seconds = 0,
        .minutes = 0,
        .hours = 0,
        .days = days,
        .months = months,
        .years = years,
    };
}

export fn createTimeSpanFromYmdHms(years: i32, months: i32, days: i32, hours: i32, minutes: i32, seconds: i32) TimeSpan {
    return TimeSpan{
        .seconds = seconds,
        .minutes = minutes,
        .hours = hours,
        .days = days,
        .months = months,
        .years = years,
    };
}   

pub fn createTimeOffset(amount: i32, unit: TimeUnit) TimeOffset {
    return TimeOffset{
        .amount = amount,
        .unit = unit,
    };
}

pub fn createTimeOffsetFromString(definition: []const u8) TimeOffset {
    var amount: i32 = 0;
    var unit: TimeUnit = TimeUnit.Second;

    var i: usize = 0;
    while (i < definition.len) : (i += 1) {
        if (definition[i] >= '0' and definition[i] <= '9') {
            const digit : i32 = @intCast(definition[i] - '0');
            amount = amount * 10 + digit;
        } else {
            unit =
            switch (definition[i]) {
                's'=>  TimeUnit.Second,
                'm'=>  TimeUnit.Minute,
                'h'=>  TimeUnit.Hour,
                'd'=>  TimeUnit.Day,
                'w'=>  TimeUnit.Week,
                'M'=>  TimeUnit.Month,
                'Q'=>  TimeUnit.Quarter,
                'S'=>  TimeUnit.Semester,
                'Y'=>  TimeUnit.Year,
                'D'=>  TimeUnit.Decade,
                'C'=>  TimeUnit.Century,
            };
        }
    }

    return TimeOffset{
        .amount = amount,
        .unit = unit,
    };
}   

/// Converts a digit to a character.
fn digitToChar(digit: u8) u8 {
    return digit + '0';
}

/// Extracts a digit from a number at a given position.
fn extractDigit(number: c_int, position: u8) u8 {
    var res: u8 = 0;
    const unsigned_number : u32 = @intCast(number) ; // Cast to unsigned integer

    switch (position) {
        0 => res = @truncate( @rem(unsigned_number, 10)),
        1 => res = @truncate( @rem(unsigned_number / 10, 10)),
        2 => res = @truncate( @rem(unsigned_number / 100, 10)),
        3 => res = @truncate( @rem(unsigned_number / 1000, 10)),
        else => res =0,
    }
    return res;
}

/// Check if a date is end of month
pub fn isEndOfMonth(year: u16, month: u8, day: u8) bool {
    if (day == daysInMonth[month - 1]) {
        if (month == 2 and isLeapYear(year)) {
            return day == 29;
        }
        return true;
    }
    return false;
}



/// Formats the DateTime struct into a string based on the provided format.
pub fn formatDateTime(dt: DateTime, format: []const u8, allocator: std.mem.Allocator) ![]u8 {

    const months = "JanFebMarAprMayJunJulAugSepOctNovDec";
    const days3 = "SunMonTueWedThuFriSat";
    
    const buffer = try allocator.alloc(u8, format.len);

    var i: usize = 0;
    var j: usize = 0;
    while (i < format.len) : (i += 1) {
        if (format[i] == 'y' and i + 3 < format.len and format[i + 1] == 'y' and format[i + 2] == 'y' and format[i + 3] == 'y') {
            buffer[j] = digitToChar(extractDigit(dt.year, 3));
            buffer[j + 1] = digitToChar(extractDigit(dt.year, 2));
            buffer[j + 2] = digitToChar(extractDigit(dt.year, 1));
            buffer[j + 3] = digitToChar(extractDigit(dt.year, 0));
            j += 4;
            i += 3;
        } else if (format[i] == 'y' and i + 1 < format.len and format[i + 1] == 'y') {
            buffer[j] = digitToChar(extractDigit(dt.year, 1));
            buffer[j + 1] = digitToChar(extractDigit(dt.year, 0));
            j += 2;
            i += 1;
        } else if (format[i] == 'M' and i + 2 < format.len and format[i + 1] == 'M' and format[i + 2] == 'M') {            
            const offset : u8 = @intCast((dt.month - 1) * 3) ; // Cast to unsigned integer
            buffer[j] = months[offset];
            buffer[j + 1] = months[offset + 1];
            buffer[j + 2] = months[offset + 2];
            j += 3;
            i += 2;
        } else if (format[i] == 'M' and i + 1 < format.len and format[i + 1] == 'M') {
            buffer[j] = digitToChar(extractDigit(dt.month, 1));
            buffer[j + 1] = digitToChar(extractDigit(dt.month, 0));
            j += 2;
            i += 1;
        } 
        else if (format[i] == 'd' and i + 2 < format.len and format[i + 1] == 'd' and format[i + 2] == 'd') {
            const day_of_week: u8 = calcDayOfWeek(dt.year, dt.month, dt.day);
            const offset : u8 = @intCast(day_of_week * 3) ; // Cast to unsigned integer

            buffer[j] = days3[offset];
            buffer[j + 1] = days3[offset + 1];
            buffer[j + 2] = days3[offset + 2];
            j += 3;
            i += 2;
        }
        else if (format[i] == 'd' and i + 1 < format.len and format[i + 1] == 'd') {
            buffer[j] = digitToChar(extractDigit(dt.day, 1));
            buffer[j + 1] = digitToChar(extractDigit(dt.day, 0));
            j += 2;
            i += 1;
        } 
        else if (format[i] == 'h' and i + 1 < format.len and format[i + 1] == 'h') {
            buffer[j] = digitToChar(extractDigit(dt.hours, 1));
            buffer[j + 1] = digitToChar(extractDigit(dt.hours, 0));
            j += 2;
            i += 1;
        } else if (format[i] == 'm' and i + 1 < format.len and format[i + 1] == 'm') {
            buffer[j] = digitToChar(extractDigit(dt.minutes, 1));
            buffer[j + 1] = digitToChar(extractDigit(dt.minutes, 0));
            j += 2;
            i += 1;
        } else if (format[i] == 's' and i + 1 < format.len and format[i + 1] == 's') {
            buffer[j] = digitToChar(extractDigit(dt.seconds, 1));
            buffer[j + 1] = digitToChar(extractDigit(dt.seconds, 0));
            j += 2;
            i += 1;
        } else {
            buffer[j] = format[i];
            j += 1;
        }
    }

    return buffer; 
}

/// Check if a number exists in an array
fn contains(comptime T: type, haystack: []const T, needle: T) bool {
    for (haystack) |item| {
        if (item == needle) return true;
    }
    return false;
}

test "isLeapYear" {
    // Leap year from 1900 to 2100
    const leapYears = [49]u16{
        1904, 1908, 1912, 1916, 1920, 1924, 1928, 1932, 1936, 1940, 1944, 1948, 1952, 1956, 1960, 1964, 1968, 1972, 1976, 1980, 1984, 1988, 1992, 1996, 2000, 2004, 2008, 2012, 2016, 2020, 2024, 2028, 2032, 2036, 2040, 2044, 2048, 2052, 2056, 2060, 2064, 2068, 2072, 2076, 2080, 2084, 2088, 2092, 2096,
    };

    // Check couple of years
    try testing.expect(contains(u16, &leapYears, 2000));
    try testing.expect(!contains(u16, &leapYears, 2001));

    // Loop over all dates from 1900 to 2100
    var year: u16 = 1900;
    while (year < 2100) : (year += 1) {
        if (contains(u16, &leapYears, year)) {
            try testing.expect(isLeapYear(year));
        } else {
            try testing.expect(!isLeapYear(year));
        }
    }
}

test "getDayName" {
    try testing.expect(getDayNumber("Sunday") == 0);
    try testing.expect(getDayNumber("Monday") == 1);
    try testing.expect(getDayNumber("Tuesday") == 2);
    try testing.expect(getDayNumber("Wednesday") == 3);
    try testing.expect(getDayNumber("Thursday") == 4);
    try testing.expect(getDayNumber("Friday") == 5);
    try testing.expect(getDayNumber("Saturday") == 6);

    try testing.expect(getDayNumber("Sun") == 0);
    try testing.expect(getDayNumber("Mon") == 1);
    try testing.expect(getDayNumber("Tue") == 2);
    try testing.expect(getDayNumber("Wed") == 3);
    try testing.expect(getDayNumber("Thu") == 4);
    try testing.expect(getDayNumber("Fri") == 5);
    try testing.expect(getDayNumber("Sat") == 6);

    try testing.expect(getDayNumber("Invalid") == -1);
}

test "getMonthName" {
    try testing.expect(getMonthNumber("January") == 1);
    try testing.expect(getMonthNumber("February") == 2);
    try testing.expect(getMonthNumber("March") == 3);
    try testing.expect(getMonthNumber("April") == 4);
    try testing.expect(getMonthNumber("May") == 5);
    try testing.expect(getMonthNumber("June") == 6);
    try testing.expect(getMonthNumber("July") == 7);
    try testing.expect(getMonthNumber("August") == 8);
    try testing.expect(getMonthNumber("September") == 9);
    try testing.expect(getMonthNumber("October") == 10);
    try testing.expect(getMonthNumber("November") == 11);
    try testing.expect(getMonthNumber("December") == 12);

    try testing.expect(getMonthNumber("Jan") == 1);
    try testing.expect(getMonthNumber("Feb") == 2);
    try testing.expect(getMonthNumber("Mar") == 3);
    try testing.expect(getMonthNumber("Apr") == 4);
    try testing.expect(getMonthNumber("May") == 5);
    try testing.expect(getMonthNumber("Jun") == 6);
    try testing.expect(getMonthNumber("Jul") == 7);
    try testing.expect(getMonthNumber("Aug") == 8);
    try testing.expect(getMonthNumber("Sep") == 9);
    try testing.expect(getMonthNumber("Oct") == 10);
    try testing.expect(getMonthNumber("Nov") == 11);
    try testing.expect(getMonthNumber("Dec") == 12);

    try testing.expect(getMonthNumber("Invalid") == -1);
}

test "calcDayOfYear" {
    try testing.expect(calcDayOfYear(2024, 1, 1) == 1);
    try testing.expect(calcDayOfYear(2024, 1, 31) == 31);
    try testing.expect(calcDayOfYear(2024, 2, 1) == 32);
    try testing.expect(calcDayOfYear(2024, 2, 29) == 60);
    try testing.expect(calcDayOfYear(2024, 3, 1) == 61);
    try testing.expect(calcDayOfYear(2024, 12, 31) == 366);
}

test "calcDayOfWeek" {
    try testing.expect(calcDayOfWeek(2024, 1, 1) == 1); // Monday
    try testing.expect(calcDayOfWeek(2024, 1, 31) == 3); // Wednesday
    try testing.expect(calcDayOfWeek(2024, 2, 1) == 4); // Thursday
    try testing.expect(calcDayOfWeek(2024, 2, 29) == 4); // Thursday
    try testing.expect(calcDayOfWeek(2024, 3, 1) == 5); // Friday
    try testing.expect(calcDayOfWeek(2024, 12, 31) == 2); // Tuesday
}

test "calcWeekNumber" {
    try testing.expect(calcWeekNumber(2024, 1, 1) == 1);
    try testing.expect(calcWeekNumber(2024, 1, 31) == 5);
    try testing.expect(calcWeekNumber(2024, 2, 1) == 5);
    try testing.expect(calcWeekNumber(2024, 2, 29) == 9);
    try testing.expect(calcWeekNumber(2024, 3, 1) == 9);
    try testing.expect(calcWeekNumber(2024, 12, 31) == 1);
}

test "getLocalTime" {
    const dt = getLocalCDateTime();

    // Basic assertions to ensure the values are within expected ranges
    try std.testing.expect(dt.seconds >= 0 and dt.seconds < 60);
    try std.testing.expect(dt.minutes >= 0 and dt.minutes < 60);
    try std.testing.expect(dt.hours >= 0 and dt.hours < 24);
    try std.testing.expect(dt.day >= 1 and dt.day <= 31);
    try std.testing.expect(dt.month >= 0 and dt.month < 12);
    try std.testing.expect(dt.year >= 70); // Since tm_year is years since 1900
    try std.testing.expect(dt.day_of_week >= 0 and dt.day_of_week < 7);
    try std.testing.expect(dt.day_of_year >= 0 and dt.day_of_year < 366);
}

test "formatDateTime" {
     var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
     defer arena.deinit();
  
    const cdt = getLocalCDateTime();
    const dt = createDateTimeFromCDateTime(cdt);
    const formatted = try formatDateTime(dt, "yyyy MMM ddd hh:mm:ss", arena.allocator());             

    std.debug.print("{s}", .{formatted});
}


test "validateYmd" {
    // Test valid dates
    try std.testing.expect(validateYmd(2024, 2, 29)); // Leap year
    try std.testing.expect(validateYmd(2024, 1, 31));
    try std.testing.expect(validateYmd(2024, 4, 30));
    
    // Test invalid dates
    try std.testing.expect(!validateYmd(2024, 2, 30)); // Invalid leap year day
    try std.testing.expect(!validateYmd(2023, 2, 29)); // Not a leap year
    try std.testing.expect(!validateYmd(2024, 4, 31)); // April has 30 days
    try std.testing.expect(!validateYmd(0, 1, 1));     // Year 0
    try std.testing.expect(!validateYmd(2024, 0, 1));  // Month 0
    try std.testing.expect(!validateYmd(2024, 13, 1)); // Month 13
    try std.testing.expect(!validateYmd(2024, 1, 0));  // Day 0
    try std.testing.expect(!validateYmd(2024, 1, 32)); // Day 32
}

